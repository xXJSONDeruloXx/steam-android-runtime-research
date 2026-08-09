#include <alsa/asoundlib.h>

#include <stdio.h>

static int report_error(const char *operation, int status)
{
    fprintf(stdout, "alsa_%s=fail status=%d error=%s\n",
            operation, status, snd_strerror(status));
    return 1;
}

int main(int argc, char **argv)
{
    const char *device = argc > 1 ? argv[1] : "default";
    snd_pcm_t *pcm = NULL;
    int status = snd_pcm_open(&pcm, device, SND_PCM_STREAM_PLAYBACK,
                              SND_PCM_NONBLOCK);
    printf("alsa_device=%s\n", device);
    if (status < 0) {
        return report_error("pcm_open", status);
    }
    printf("alsa_pcm_open=pass\n");

    snd_pcm_hw_params_t *params = NULL;
    snd_pcm_hw_params_alloca(&params);
    status = snd_pcm_hw_params_any(pcm, params);
    if (status < 0) {
        snd_pcm_close(pcm);
        return report_error("hw_params_any", status);
    }

    status = snd_pcm_hw_params_set_access(pcm, params,
                                          SND_PCM_ACCESS_RW_INTERLEAVED);
    if (status < 0) {
        snd_pcm_close(pcm);
        return report_error("set_access", status);
    }
    status = snd_pcm_hw_params_set_format(pcm, params, SND_PCM_FORMAT_S16_LE);
    if (status < 0) {
        snd_pcm_close(pcm);
        return report_error("set_format", status);
    }

    unsigned int rate = 48000;
    int direction = 0;
    status = snd_pcm_hw_params_set_rate_near(pcm, params, &rate, &direction);
    if (status < 0) {
        snd_pcm_close(pcm);
        return report_error("set_rate", status);
    }

    unsigned int channels = 2;
    status = snd_pcm_hw_params_set_channels_near(pcm, params, &channels);
    if (status < 0) {
        snd_pcm_close(pcm);
        return report_error("set_channels", status);
    }
    printf("alsa_hw_params_requested=rate:%u channels:%u\n", rate, channels);

    status = snd_pcm_hw_params(pcm, params);
    if (status < 0) {
        snd_pcm_close(pcm);
        return report_error("hw_params", status);
    }
    printf("alsa_hw_params=pass rate:%u channels:%u\n", rate, channels);

    status = snd_pcm_close(pcm);
    if (status < 0) {
        return report_error("pcm_close", status);
    }
    printf("alsa_pcm_close=pass\n");
    return 0;
}
