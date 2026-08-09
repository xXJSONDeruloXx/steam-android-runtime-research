#include <alsa/asoundlib.h>

#include <errno.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

static int report_error(const char *operation, int status)
{
    fprintf(stdout, "alsa_%s=fail status=%d error=%s\n",
            operation, status, snd_strerror(status));
    return 1;
}

int main(int argc, char **argv)
{
    const char *device = argc > 1 ? argv[1] : "default";
    unsigned int buffer_us = argc > 2 ? (unsigned int)strtoul(argv[2], NULL, 10) : 10000;
    const unsigned int channels = 2;
    const unsigned int rate = 48000;
    snd_pcm_t *pcm = NULL;

    printf("alsa_device=%s\n", device);
    printf("alsa_requested_format=S16_LE\n");
    printf("alsa_requested_rate=%u\n", rate);
    printf("alsa_requested_channels=%u\n", channels);
    printf("alsa_requested_buffer_us=%u\n", buffer_us);
    printf("alsa_write_payload=silence\n");

    int status = snd_pcm_open(&pcm, device, SND_PCM_STREAM_PLAYBACK,
                              SND_PCM_NONBLOCK);
    if (status < 0) {
        return report_error("pcm_open", status);
    }
    printf("alsa_pcm_open=pass\n");

    /* Chromium's Linux ALSA backend uses snd_pcm_set_params() with the same
     * S16 interleaved format and non-blocking open before its first write. */
    status = snd_pcm_set_params(pcm, SND_PCM_FORMAT_S16_LE,
                                SND_PCM_ACCESS_RW_INTERLEAVED, channels, rate,
                                1, buffer_us);
    if (status < 0) {
        snd_pcm_close(pcm);
        return report_error("pcm_set_params", status);
    }
    printf("alsa_pcm_set_params=pass\n");

    snd_pcm_uframes_t buffer_frames = 0;
    snd_pcm_uframes_t period_frames = 0;
    status = snd_pcm_get_params(pcm, &buffer_frames, &period_frames);
    if (status < 0) {
        snd_pcm_close(pcm);
        return report_error("get_params", status);
    }
    printf("alsa_buffer_frames=%lu\n", (unsigned long)buffer_frames);
    printf("alsa_period_frames=%lu\n", (unsigned long)period_frames);

    status = snd_pcm_drop(pcm);
    if (status < 0 && status != -EAGAIN) {
        snd_pcm_close(pcm);
        return report_error("pcm_drop", status);
    }
    status = snd_pcm_prepare(pcm);
    if (status < 0 && status != -EAGAIN) {
        snd_pcm_close(pcm);
        return report_error("pcm_prepare", status);
    }
    printf("alsa_pcm_prepare=pass\n");

    snd_pcm_sframes_t available_frames = snd_pcm_avail_update(pcm);
    if (available_frames < 0) {
        snd_pcm_close(pcm);
        return report_error("avail_update", (int)available_frames);
    }
    printf("alsa_available_frames=%ld\n", (long)available_frames);
    if (available_frames == 0) {
        snd_pcm_drop(pcm);
        snd_pcm_close(pcm);
        printf("alsa_pcm_write=not_attempted reason=no_available_frames\n");
        return 0;
    }

    /* Write one complete currently available buffer of zeroed frames. This
     * tests the kernel/plugin write contract without producing an audible tone. */
    const size_t frame_bytes = channels * sizeof(int16_t);
    const size_t payload_bytes = (size_t)available_frames * frame_bytes;
    int16_t *payload = calloc((size_t)available_frames * channels,
                              sizeof(*payload));
    if (!payload) {
        snd_pcm_drop(pcm);
        snd_pcm_close(pcm);
        fprintf(stdout, "alsa_pcm_write=fail error=allocation_failed bytes=%lu\n",
                (unsigned long)payload_bytes);
        return 1;
    }

    snd_pcm_sframes_t written = snd_pcm_writei(pcm, payload, available_frames);
    printf("alsa_pcm_write_requested_frames=%ld\n", (long)available_frames);
    if (written < 0) {
        printf("alsa_pcm_write=fail status=%ld error=%s\n", (long)written,
               snd_strerror((int)written));
        int recovered = snd_pcm_recover(pcm, (int)written, 1);
        printf("alsa_pcm_recover_status=%d error=%s\n", recovered,
               recovered < 0 ? snd_strerror(recovered) : "pass");
    } else {
        printf("alsa_pcm_write=pass frames=%ld\n", (long)written);
    }

    free(payload);
    status = snd_pcm_drop(pcm);
    printf("alsa_pcm_drop_after_write=%s\n",
           status < 0 ? snd_strerror(status) : "pass");
    status = snd_pcm_close(pcm);
    if (status < 0) {
        return report_error("pcm_close", status);
    }
    printf("alsa_pcm_close=pass\n");
    return written < 0 ? 1 : 0;
}
