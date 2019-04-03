# Audio-Spectrum
Audio-Spectrum, Visualization

### 模块
  * 音频播放
    Win32::Sound - 支持非阻塞播放，在 play 的时候指定 __SND_ASYNC__ FLAG（字面常量）
    Win32::MediaPlayer - 支持非阻塞播放，可以设置指定起点，在播放时可以获取进度。

### 知识整理
  * 双缓冲播放
    Double Buffering for Audio
    
  * FFT
    Math::FFT 提供的函数传参是数组引用，数组长度必须是2的N次方

  * 信号截取的长度和偏移量
    为了声音和频谱图时间同步，偏移量一般是 每秒采样数/帧率，比如 44100Hz 的音频，每秒20帧，
    取 44100/20 = 2205 点的数据用于显示，但FFT的取样数据通常需要 2^n 为长度，所以一般不一致。

    当音频采样为 8000Hz，帧率为20fps 时，绘图数据采样率为 400Hz，
    若 FFT 采样的数据量是 1024，则偏移到末位，再取1024的长度会导致溢出。需要补0处理

  * WAV
    * fmt_Chunk
      即使是PCM波形数据，fmt_Chunk 也有可能包含 wExtend 字段（该项为0）。所以读取的时候还是应该获取 ChunkSize 按实际长度处理。

      



