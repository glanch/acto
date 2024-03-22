{ config, lib, pkgs, ... }:

{
  boot.kernelModules = [ "amdgpu" ];
  # Enable PP_OVERDRIVE_MASK and all other flags that were set when writing this configuration
  # Checked with `cat /sys/module/amdgpu/parameters/ppfeaturemask`
  boot.kernelParams = [ "amdgpu.ppfeaturemask=0xfff7ffff" ];

  # Enable OpenGL
/*   hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  }; */
}
