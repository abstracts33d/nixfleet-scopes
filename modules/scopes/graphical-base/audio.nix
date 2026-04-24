# Audio — PipeWire with ALSA, PulseAudio, and JACK compatibility.
{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.nixfleet.graphical.enable {
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };
  };
}
