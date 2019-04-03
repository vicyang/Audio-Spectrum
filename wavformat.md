5249 4646 24bd 0100 5741 5645 666d 7420
R I  F F  ....      W A  V E  f m  t _

1000 0000 0100 0200 44ac 0000 10b1 0200
0400 1000 6461 7461 00bd 0100 0000 0000
          d a  t a
0000 0000 0000 0000 0000 ffff 0000 ffff

文件大小为 113964 
其中 24bd 0100 -> 0x0001bd24 = 113956 表示 从WAVE开始的字段到文件末的大小

WAV 格式符合 RIFF 规范，
常见的chunk 主要有 fmt chunk 和 data chunk

```c
fmt chunk
typedef struct {
  ID    chunk ID;                   // Format Chunk 标识符 'fmt'
  long  chunkSize;                  // Format Chunk 大小
  short wFormatTag;                 // 编码格式
  unsigned short wChannels;         // 声道数
  unsigned long  dwSamplesPerSec;   // 采样频率
  unsigned long  dwAvgBytesPerSec;  // 每秒的数据量
  unsigned short wBlockAlign;       // 块对齐
  unsigned short wBitsPerSample;    // 采样位数
  //unsigned short wExtend;           // 扩展值 Optional
} FormatChunk;
```

4+4+2+2+4+4+2+2+2(optional) = 26
但 wExtend 参数只有在采用非 PCM 波形数据时使用。在采用PCM格式时省略，于是长度为24byte

```c
data chunk
typedef struct {
  ID    chunk ID;                   // Format Chunk 标识符 'fmt'
  long  chunkSize;                  // Format Chunk 大小
  unsigned char waveformData[];     // 所有通道的波形数据
} FormatChunk;
```

