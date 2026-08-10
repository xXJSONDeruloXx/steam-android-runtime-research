package com.xjsonderulo.steamandroid.novalab;

import android.media.AudioAttributes;
import android.media.AudioFormat;
import android.media.AudioTrack;
import android.util.Log;

import java.io.EOFException;
import java.io.IOException;
import java.io.InputStream;
import java.net.InetAddress;
import java.net.InetSocketAddress;
import java.net.ServerSocket;
import java.net.Socket;
import java.net.SocketException;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.Arrays;

/** Receives one run-scoped PCM stream and presents it through Android audio. */
final class AudioPcmBridge {
    static final int DEFAULT_PORT = 29100;
    private static final String TAG = "NovaAudioBridge";
    private static final byte[] MAGIC = {
            'N', 'O', 'V', 'A', 'P', 'C', 'M', '1'
    };
    private static final int HEADER_BYTES = 16;
    private static final int FRAME_BYTES = 4;
    private static final int SAMPLE_RATE = 48000;
    private static final int CHANNELS = 2;
    private static final int FORMAT_S16_LE = 1;

    private final Object lock = new Object();
    private final int port;
    private volatile boolean stopping;
    private volatile String status = "audio_bridge=stopped";
    private volatile long framesReceived;
    private volatile long bytesReceived;
    private volatile long shortWrites;
    private volatile long zeroWrites;
    private ServerSocket serverSocket;
    private Thread worker;
    private AudioTrack track;

    AudioPcmBridge(int requestedPort) {
        port = requestedPort;
    }

    boolean start() {
        synchronized (lock) {
            if (worker != null) {
                return true;
            }
            try {
                ServerSocket listener = new ServerSocket();
                listener.setReuseAddress(true);
                listener.bind(new InetSocketAddress(
                        InetAddress.getByName("127.0.0.1"), port));
                serverSocket = listener;
            } catch (IOException error) {
                updateStatus("audio_bridge=fail reason=listen error=" + error);
                return false;
            }
            stopping = false;
            worker = new Thread(new Runnable() {
                @Override
                public void run() {
                    acceptLoop();
                }
            }, "nova-audio-bridge");
            worker.start();
            updateStatus("audio_bridge_listener=ready host=127.0.0.1 port=" + port);
            return true;
        }
    }

    void stop() {
        Thread thread;
        ServerSocket listener;
        AudioTrack currentTrack;
        synchronized (lock) {
            stopping = true;
            thread = worker;
            worker = null;
            listener = serverSocket;
            serverSocket = null;
            currentTrack = track;
            track = null;
        }
        closeQuietly(listener);
        releaseTrack(currentTrack);
        if (thread != null) {
            thread.interrupt();
            try {
                thread.join(1500L);
            } catch (InterruptedException error) {
                Thread.currentThread().interrupt();
            }
        }
        updateStatus("audio_bridge=stopped frames=" + framesReceived
                + " bytes=" + bytesReceived);
    }

    String getStatus() {
        return status;
    }

    private void acceptLoop() {
        ServerSocket listener;
        synchronized (lock) {
            listener = serverSocket;
        }
        if (listener == null) {
            return;
        }
        try {
            while (!stopping) {
                Socket client = listener.accept();
                client.setTcpNoDelay(true);
                updateStatus("audio_bridge_client=connected");
                try {
                    streamClient(client);
                } catch (IOException error) {
                    if (!stopping) {
                        updateStatus("audio_bridge_client=fail error=" + error);
                    }
                } finally {
                    closeQuietly(client);
                    releaseActiveTrack();
                }
            }
        } catch (SocketException error) {
            if (!stopping) {
                updateStatus("audio_bridge=fail reason=accept error=" + error);
            }
        } catch (IOException error) {
            if (!stopping) {
                updateStatus("audio_bridge=fail reason=accept error=" + error);
            }
        } finally {
            closeQuietly(listener);
        }
    }

    private void streamClient(Socket client) throws IOException {
        InputStream input = client.getInputStream();
        byte[] header = new byte[HEADER_BYTES];
        readFully(input, header, 0, header.length);
        ByteBuffer fields = ByteBuffer.wrap(header).order(ByteOrder.LITTLE_ENDIAN);
        byte[] magic = new byte[MAGIC.length];
        fields.get(magic);
        int rate = fields.getInt();
        int channels = fields.getShort() & 0xffff;
        int format = fields.getShort() & 0xffff;
        if (!Arrays.equals(magic, MAGIC)) {
            throw new IOException("invalid_header_magic");
        }
        if (rate != SAMPLE_RATE || channels != CHANNELS || format != FORMAT_S16_LE) {
            throw new IOException("unsupported_format rate=" + rate
                    + " channels=" + channels + " format=" + format);
        }
        AudioTrack currentTrack = createTrack();
        synchronized (lock) {
            if (stopping) {
                releaseTrack(currentTrack);
                return;
            }
            track = currentTrack;
        }
        currentTrack.play();
        updateStatus("audio_bridge_stream=ready rate=" + rate
                + " channels=" + channels + " format=S16_LE");

        byte[] buffer = new byte[16384 + FRAME_BYTES];
        int carry = 0;
        for (;;) {
            if (stopping) {
                return;
            }
            int read = input.read(buffer, carry, buffer.length - carry);
            if (read < 0) {
                break;
            }
            if (read == 0) {
                continue;
            }
            int total = carry + read;
            int aligned = total - (total % FRAME_BYTES);
            if (aligned > 0) {
                writeAll(currentTrack, buffer, aligned);
            }
            carry = total - aligned;
            if (carry > 0) {
                System.arraycopy(buffer, aligned, buffer, 0, carry);
            }
        }
        if (carry != 0) {
            throw new EOFException("partial_pcm_frame bytes=" + carry);
        }
        updateStatus("audio_bridge_stream=closed frames=" + framesReceived
                + " bytes=" + bytesReceived + " short_writes=" + shortWrites
                + " zero_writes=" + zeroWrites);
    }

    private void writeAll(AudioTrack currentTrack, byte[] buffer, int length)
            throws IOException {
        int offset = 0;
        int consecutiveZeroWrites = 0;
        while (offset < length) {
            int written = currentTrack.write(
                    buffer, offset, length - offset, AudioTrack.WRITE_BLOCKING);
            if (written < 0) {
                throw new IOException("audiotrack_write=" + written);
            }
            if (written == 0) {
                zeroWrites++;
                consecutiveZeroWrites++;
                if (consecutiveZeroWrites >= 1000) {
                    throw new IOException("audiotrack_zero_write_loop");
                }
                try {
                    Thread.sleep(1L);
                } catch (InterruptedException error) {
                    Thread.currentThread().interrupt();
                    throw new IOException("audiotrack_write_interrupted", error);
                }
                continue;
            }
            if (written > length - offset) {
                throw new IOException("audiotrack_write_overrun=" + written);
            }
            if (written < length - offset) {
                shortWrites++;
            }
            offset += written;
            bytesReceived += written;
            framesReceived += written / FRAME_BYTES;
            consecutiveZeroWrites = 0;
        }
    }

    private AudioTrack createTrack() throws IOException {
        int channelMask = AudioFormat.CHANNEL_OUT_STEREO;
        int minBuffer = AudioTrack.getMinBufferSize(
                SAMPLE_RATE, channelMask, AudioFormat.ENCODING_PCM_16BIT);
        if (minBuffer <= 0) {
            throw new IOException("invalid_min_buffer=" + minBuffer);
        }
        int bufferBytes = minBuffer;
        AudioTrack current = new AudioTrack.Builder()
                .setAudioAttributes(new AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_GAME)
                        .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                        .build())
                .setAudioFormat(new AudioFormat.Builder()
                        .setSampleRate(SAMPLE_RATE)
                        .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                        .setChannelMask(channelMask)
                        .build())
                .setBufferSizeInBytes(bufferBytes)
                .setTransferMode(AudioTrack.MODE_STREAM)
                .build();
        int state = current.getState();
        if (state != AudioTrack.STATE_INITIALIZED) {
            current.release();
            throw new IOException("audiotrack_state=" + state);
        }
        return current;
    }

    private void releaseActiveTrack() {
        AudioTrack current;
        synchronized (lock) {
            current = track;
            track = null;
        }
        releaseTrack(current);
    }

    private static void releaseTrack(AudioTrack current) {
        if (current == null) {
            return;
        }
        try {
            if (current.getPlayState() == AudioTrack.PLAYSTATE_PLAYING) {
                current.stop();
            }
        } catch (IllegalStateException ignored) {
            // The track may already have been invalidated during service stop.
        }
        current.release();
    }

    private static void closeQuietly(ServerSocket listener) {
        if (listener == null) {
            return;
        }
        try {
            listener.close();
        } catch (IOException ignored) {
        }
    }

    private static void closeQuietly(Socket client) {
        if (client == null) {
            return;
        }
        try {
            client.close();
        } catch (IOException ignored) {
        }
    }

    private static void readFully(InputStream input, byte[] target, int offset, int length)
            throws IOException {
        int end = offset + length;
        while (offset < end) {
            int read = input.read(target, offset, end - offset);
            if (read < 0) {
                throw new EOFException("short_audio_header");
            }
            if (read == 0) {
                continue;
            }
            offset += read;
        }
    }

    private void updateStatus(String value) {
        status = value;
        Log.i(TAG, value);
    }
}
