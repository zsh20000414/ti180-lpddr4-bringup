# Memory map

Frozen only when the bring-up loop stops moving it. Until then, treat every
address below as provisional and keep the driver reading this document rather
than hard-coding offsets.

| offset | name | rw | notes |
|---|---|---|---|
| 0x0000 | ID | r | constant, identifies bitstream build |
| 0x0004 | STATUS | r | bit0 training done, bit1 calibration error |
| 0x0008 | ERR_CNT | rw | sticky, write 1 to clear |
| 0x0010 | BASE_LO | rw | test region base, low 32 bits |
| 0x0014 | BASE_HI | rw | test region base, high 32 bits |
| 0x0018 | LEN | rw | test region length in bytes |
| 0x001C | CTRL | rw | bit0 start pattern run, bit1 start readback compare |
