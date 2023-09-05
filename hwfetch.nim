import std/[strutils, strformat, osproc]

type
  MyComputerInfo = object
    os: string
    host: string
    kernel: string
    cpu: string
    gpu: string


proc cacheUnameInfo*(): tuple[os: string, host: string, kernel: string] =
  ## Only defined for posix systems
  when defined(posix):
    let (output, errorCode) = execCmdEx("uname -omnr")
    if errorCode != 0:
      echo fmt"`uname -omnr` command failed, with Error code: {errorCode}"
      quit(2)
    let outSeq: seq[string] = output.split(' ')
    var arch: string = outSeq[3]
    stripLineEnd(arch)
    let
      os = arch & ' ' & outSeq[2]
      host = outSeq[0]
      kernel = outSeq[1]
    return (os, host, kernel)

proc getGpuInfo*(): string =
  when defined(posix):
    var (gpu_driver_name, exitCode) = execCmdEx("""lspci -nnk | awk -F ': ' \ '/Display|3D|VGA/{nr[NR+2]}; NR in nr {printf $2 ", "; exit}'""")
    if exitCode == 0:
      gpu_driver_name = gpu_driver_name.split(",")[0]
      if gpu_driver_name == "nvidia":
        var (gpu_name, exitCodeSmi) = execCmdEx("nvidia-smi --query-gpu=name --format=csv,noheader")
        if exitCodeSmi != 0:
          echo "nvidia-smi command failed with exit code: {exitCodeSmi}"
          quit(2)
        return gpu_name
      return gpu_driver_name.toUpperAscii()
    else:
      echo fmt"GpuInfo error code: {exitCode}"
      quit(2)

proc getCpuInfo*(): string =
  when defined(posix):
    var (cpu_name, _) = execCmdEx("""cat /proc/cpuinfo | awk -F '\\s*: | @' '/model name|Hardware|Processor|^cpu model|chip type|^cpu type/ { cpu=$2; if ($1 == "Hardware") exit } END { print cpu }' "$cpu_file" """)
    return cpu_name

proc `$`(mci: MyComputerInfo): string =
  ## Nice Output of a `MyComputerInfo` object
  for name, val in fieldPairs(mci):
    if $val != "":
      result.add name.capitalizeAscii()
      result.add ": "
      result.add ($val).strip(leading=false, chars = {'\n'})
      result.add "\n"
  result.strip(leading=false, chars = {'\n'})

when isMainModule:
  var mci: MyComputerInfo
  (mci.os, mci.host, mci.kernel) = cacheUnameInfo()
  mci.gpu = getGpuInfo()
  mci.cpu = getcpuInfo()
  echo mci
