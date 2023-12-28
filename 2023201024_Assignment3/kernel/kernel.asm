
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	b1813103          	ld	sp,-1256(sp) # 80008b18 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	076000ef          	jal	ra,8000008c <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007859b          	sext.w	a1,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873703          	ld	a4,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	9732                	add	a4,a4,a2
    80000046:	e398                	sd	a4,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00259693          	slli	a3,a1,0x2
    8000004c:	96ae                	add	a3,a3,a1
    8000004e:	068e                	slli	a3,a3,0x3
    80000050:	00009717          	auipc	a4,0x9
    80000054:	b2070713          	addi	a4,a4,-1248 # 80008b70 <timer_scratch>
    80000058:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005a:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005c:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    8000005e:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000062:	00006797          	auipc	a5,0x6
    80000066:	1ae78793          	addi	a5,a5,430 # 80006210 <timervec>
    8000006a:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000006e:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000072:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000076:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007a:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    8000007e:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000082:	30479073          	csrw	mie,a5
}
    80000086:	6422                	ld	s0,8(sp)
    80000088:	0141                	addi	sp,sp,16
    8000008a:	8082                	ret

000000008000008c <start>:
{
    8000008c:	1141                	addi	sp,sp,-16
    8000008e:	e406                	sd	ra,8(sp)
    80000090:	e022                	sd	s0,0(sp)
    80000092:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000094:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000098:	7779                	lui	a4,0xffffe
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdb81f>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	dcc78793          	addi	a5,a5,-564 # 80000e78 <main>
    800000b4:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b8:	4781                	li	a5,0
    800000ba:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000be:	67c1                	lui	a5,0x10
    800000c0:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000c2:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c6:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000ca:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000ce:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d2:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d6:	57fd                	li	a5,-1
    800000d8:	83a9                	srli	a5,a5,0xa
    800000da:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000de:	47bd                	li	a5,15
    800000e0:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e4:	00000097          	auipc	ra,0x0
    800000e8:	f38080e7          	jalr	-200(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ec:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f4:	30200073          	mret
}
    800000f8:	60a2                	ld	ra,8(sp)
    800000fa:	6402                	ld	s0,0(sp)
    800000fc:	0141                	addi	sp,sp,16
    800000fe:	8082                	ret

0000000080000100 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000100:	715d                	addi	sp,sp,-80
    80000102:	e486                	sd	ra,72(sp)
    80000104:	e0a2                	sd	s0,64(sp)
    80000106:	fc26                	sd	s1,56(sp)
    80000108:	f84a                	sd	s2,48(sp)
    8000010a:	f44e                	sd	s3,40(sp)
    8000010c:	f052                	sd	s4,32(sp)
    8000010e:	ec56                	sd	s5,24(sp)
    80000110:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000112:	04c05763          	blez	a2,80000160 <consolewrite+0x60>
    80000116:	8a2a                	mv	s4,a0
    80000118:	84ae                	mv	s1,a1
    8000011a:	89b2                	mv	s3,a2
    8000011c:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011e:	5afd                	li	s5,-1
    80000120:	4685                	li	a3,1
    80000122:	8626                	mv	a2,s1
    80000124:	85d2                	mv	a1,s4
    80000126:	fbf40513          	addi	a0,s0,-65
    8000012a:	00002097          	auipc	ra,0x2
    8000012e:	6c6080e7          	jalr	1734(ra) # 800027f0 <either_copyin>
    80000132:	01550d63          	beq	a0,s5,8000014c <consolewrite+0x4c>
      break;
    uartputc(c);
    80000136:	fbf44503          	lbu	a0,-65(s0)
    8000013a:	00000097          	auipc	ra,0x0
    8000013e:	784080e7          	jalr	1924(ra) # 800008be <uartputc>
  for(i = 0; i < n; i++){
    80000142:	2905                	addiw	s2,s2,1
    80000144:	0485                	addi	s1,s1,1
    80000146:	fd299de3          	bne	s3,s2,80000120 <consolewrite+0x20>
    8000014a:	894e                	mv	s2,s3
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4c>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000186:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	b2650513          	addi	a0,a0,-1242 # 80010cb0 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a44080e7          	jalr	-1468(ra) # 80000bd6 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	b1648493          	addi	s1,s1,-1258 # 80010cb0 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	ba690913          	addi	s2,s2,-1114 # 80010d48 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001aa:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ae:	4ca9                	li	s9,10
  while(n > 0){
    800001b0:	07305b63          	blez	s3,80000226 <consoleread+0xc2>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71763          	bne	a4,a5,800001ea <consoleread+0x86>
      if(killed(myproc())){
    800001c0:	00001097          	auipc	ra,0x1
    800001c4:	7ec080e7          	jalr	2028(ra) # 800019ac <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	472080e7          	jalr	1138(ra) # 8000263a <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	064080e7          	jalr	100(ra) # 8000223a <sleep>
    while(cons.r == cons.w){
    800001de:	0984a783          	lw	a5,152(s1)
    800001e2:	09c4a703          	lw	a4,156(s1)
    800001e6:	fcf70de3          	beq	a4,a5,800001c0 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ea:	0017871b          	addiw	a4,a5,1
    800001ee:	08e4ac23          	sw	a4,152(s1)
    800001f2:	07f7f713          	andi	a4,a5,127
    800001f6:	9726                	add	a4,a4,s1
    800001f8:	01874703          	lbu	a4,24(a4)
    800001fc:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000200:	077d0563          	beq	s10,s7,8000026a <consoleread+0x106>
    cbuf = c;
    80000204:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000208:	4685                	li	a3,1
    8000020a:	f9f40613          	addi	a2,s0,-97
    8000020e:	85d2                	mv	a1,s4
    80000210:	8556                	mv	a0,s5
    80000212:	00002097          	auipc	ra,0x2
    80000216:	588080e7          	jalr	1416(ra) # 8000279a <either_copyout>
    8000021a:	01850663          	beq	a0,s8,80000226 <consoleread+0xc2>
    dst++;
    8000021e:	0a05                	addi	s4,s4,1
    --n;
    80000220:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000222:	f99d17e3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000226:	00011517          	auipc	a0,0x11
    8000022a:	a8a50513          	addi	a0,a0,-1398 # 80010cb0 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	a5c080e7          	jalr	-1444(ra) # 80000c8a <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	a7450513          	addi	a0,a0,-1420 # 80010cb0 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	a46080e7          	jalr	-1466(ra) # 80000c8a <release>
        return -1;
    8000024c:	557d                	li	a0,-1
}
    8000024e:	70a6                	ld	ra,104(sp)
    80000250:	7406                	ld	s0,96(sp)
    80000252:	64e6                	ld	s1,88(sp)
    80000254:	6946                	ld	s2,80(sp)
    80000256:	69a6                	ld	s3,72(sp)
    80000258:	6a06                	ld	s4,64(sp)
    8000025a:	7ae2                	ld	s5,56(sp)
    8000025c:	7b42                	ld	s6,48(sp)
    8000025e:	7ba2                	ld	s7,40(sp)
    80000260:	7c02                	ld	s8,32(sp)
    80000262:	6ce2                	ld	s9,24(sp)
    80000264:	6d42                	ld	s10,16(sp)
    80000266:	6165                	addi	sp,sp,112
    80000268:	8082                	ret
      if(n < target){
    8000026a:	0009871b          	sext.w	a4,s3
    8000026e:	fb677ce3          	bgeu	a4,s6,80000226 <consoleread+0xc2>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	acf72b23          	sw	a5,-1322(a4) # 80010d48 <cons+0x98>
    8000027a:	b775                	j	80000226 <consoleread+0xc2>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	560080e7          	jalr	1376(ra) # 800007ec <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	54e080e7          	jalr	1358(ra) # 800007ec <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	542080e7          	jalr	1346(ra) # 800007ec <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	538080e7          	jalr	1336(ra) # 800007ec <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00011517          	auipc	a0,0x11
    800002d0:	9e450513          	addi	a0,a0,-1564 # 80010cb0 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	902080e7          	jalr	-1790(ra) # 80000bd6 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	554080e7          	jalr	1364(ra) # 80002846 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	9b650513          	addi	a0,a0,-1610 # 80010cb0 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	988080e7          	jalr	-1656(ra) # 80000c8a <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031e:	00011717          	auipc	a4,0x11
    80000322:	99270713          	addi	a4,a4,-1646 # 80010cb0 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000348:	00011797          	auipc	a5,0x11
    8000034c:	96878793          	addi	a5,a5,-1688 # 80010cb0 <cons>
    80000350:	0a07a683          	lw	a3,160(a5)
    80000354:	0016871b          	addiw	a4,a3,1
    80000358:	0007061b          	sext.w	a2,a4
    8000035c:	0ae7a023          	sw	a4,160(a5)
    80000360:	07f6f693          	andi	a3,a3,127
    80000364:	97b6                	add	a5,a5,a3
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00011797          	auipc	a5,0x11
    8000037a:	9d27a783          	lw	a5,-1582(a5) # 80010d48 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	92670713          	addi	a4,a4,-1754 # 80010cb0 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	91648493          	addi	s1,s1,-1770 # 80010cb0 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00011717          	auipc	a4,0x11
    800003da:	8da70713          	addi	a4,a4,-1830 # 80010cb0 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	96f72223          	sw	a5,-1692(a4) # 80010d50 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000412:	00011797          	auipc	a5,0x11
    80000416:	89e78793          	addi	a5,a5,-1890 # 80010cb0 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00011797          	auipc	a5,0x11
    8000043a:	90c7ab23          	sw	a2,-1770(a5) # 80010d4c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	90a50513          	addi	a0,a0,-1782 # 80010d48 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	fa4080e7          	jalr	-92(ra) # 800023ea <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00011517          	auipc	a0,0x11
    80000464:	85050513          	addi	a0,a0,-1968 # 80010cb0 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6de080e7          	jalr	1758(ra) # 80000b46 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32c080e7          	jalr	812(ra) # 8000079c <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00022797          	auipc	a5,0x22
    8000047c:	9d078793          	addi	a5,a5,-1584 # 80021e48 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7670713          	addi	a4,a4,-906 # 80000100 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054763          	bltz	a0,80000538 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088c63          	beqz	a7,800004fe <printint+0x62>
    buf[i++] = '-';
    800004ea:	fe070793          	addi	a5,a4,-32
    800004ee:	00878733          	add	a4,a5,s0
    800004f2:	02d00793          	li	a5,45
    800004f6:	fef70823          	sb	a5,-16(a4)
    800004fa:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fe:	02e05763          	blez	a4,8000052c <printint+0x90>
    80000502:	fd040793          	addi	a5,s0,-48
    80000506:	00e784b3          	add	s1,a5,a4
    8000050a:	fff78913          	addi	s2,a5,-1
    8000050e:	993a                	add	s2,s2,a4
    80000510:	377d                	addiw	a4,a4,-1
    80000512:	1702                	slli	a4,a4,0x20
    80000514:	9301                	srli	a4,a4,0x20
    80000516:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051a:	fff4c503          	lbu	a0,-1(s1)
    8000051e:	00000097          	auipc	ra,0x0
    80000522:	d5e080e7          	jalr	-674(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000526:	14fd                	addi	s1,s1,-1
    80000528:	ff2499e3          	bne	s1,s2,8000051a <printint+0x7e>
}
    8000052c:	70a2                	ld	ra,40(sp)
    8000052e:	7402                	ld	s0,32(sp)
    80000530:	64e2                	ld	s1,24(sp)
    80000532:	6942                	ld	s2,16(sp)
    80000534:	6145                	addi	sp,sp,48
    80000536:	8082                	ret
    x = -xx;
    80000538:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053c:	4885                	li	a7,1
    x = -xx;
    8000053e:	bf95                	j	800004b2 <printint+0x16>

0000000080000540 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000540:	1101                	addi	sp,sp,-32
    80000542:	ec06                	sd	ra,24(sp)
    80000544:	e822                	sd	s0,16(sp)
    80000546:	e426                	sd	s1,8(sp)
    80000548:	1000                	addi	s0,sp,32
    8000054a:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054c:	00011797          	auipc	a5,0x11
    80000550:	8207a223          	sw	zero,-2012(a5) # 80010d70 <pr+0x18>
  printf("panic: ");
    80000554:	00008517          	auipc	a0,0x8
    80000558:	ac450513          	addi	a0,a0,-1340 # 80008018 <etext+0x18>
    8000055c:	00000097          	auipc	ra,0x0
    80000560:	02e080e7          	jalr	46(ra) # 8000058a <printf>
  printf(s);
    80000564:	8526                	mv	a0,s1
    80000566:	00000097          	auipc	ra,0x0
    8000056a:	024080e7          	jalr	36(ra) # 8000058a <printf>
  printf("\n");
    8000056e:	00008517          	auipc	a0,0x8
    80000572:	b5a50513          	addi	a0,a0,-1190 # 800080c8 <digits+0x88>
    80000576:	00000097          	auipc	ra,0x0
    8000057a:	014080e7          	jalr	20(ra) # 8000058a <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057e:	4785                	li	a5,1
    80000580:	00008717          	auipc	a4,0x8
    80000584:	5af72823          	sw	a5,1456(a4) # 80008b30 <panicked>
  for(;;)
    80000588:	a001                	j	80000588 <panic+0x48>

000000008000058a <printf>:
{
    8000058a:	7131                	addi	sp,sp,-192
    8000058c:	fc86                	sd	ra,120(sp)
    8000058e:	f8a2                	sd	s0,112(sp)
    80000590:	f4a6                	sd	s1,104(sp)
    80000592:	f0ca                	sd	s2,96(sp)
    80000594:	ecce                	sd	s3,88(sp)
    80000596:	e8d2                	sd	s4,80(sp)
    80000598:	e4d6                	sd	s5,72(sp)
    8000059a:	e0da                	sd	s6,64(sp)
    8000059c:	fc5e                	sd	s7,56(sp)
    8000059e:	f862                	sd	s8,48(sp)
    800005a0:	f466                	sd	s9,40(sp)
    800005a2:	f06a                	sd	s10,32(sp)
    800005a4:	ec6e                	sd	s11,24(sp)
    800005a6:	0100                	addi	s0,sp,128
    800005a8:	8a2a                	mv	s4,a0
    800005aa:	e40c                	sd	a1,8(s0)
    800005ac:	e810                	sd	a2,16(s0)
    800005ae:	ec14                	sd	a3,24(s0)
    800005b0:	f018                	sd	a4,32(s0)
    800005b2:	f41c                	sd	a5,40(s0)
    800005b4:	03043823          	sd	a6,48(s0)
    800005b8:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005bc:	00010d97          	auipc	s11,0x10
    800005c0:	7b4dad83          	lw	s11,1972(s11) # 80010d70 <pr+0x18>
  if(locking)
    800005c4:	020d9b63          	bnez	s11,800005fa <printf+0x70>
  if (fmt == 0)
    800005c8:	040a0263          	beqz	s4,8000060c <printf+0x82>
  va_start(ap, fmt);
    800005cc:	00840793          	addi	a5,s0,8
    800005d0:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d4:	000a4503          	lbu	a0,0(s4)
    800005d8:	14050f63          	beqz	a0,80000736 <printf+0x1ac>
    800005dc:	4981                	li	s3,0
    if(c != '%'){
    800005de:	02500a93          	li	s5,37
    switch(c){
    800005e2:	07000b93          	li	s7,112
  consputc('x');
    800005e6:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e8:	00008b17          	auipc	s6,0x8
    800005ec:	a58b0b13          	addi	s6,s6,-1448 # 80008040 <digits>
    switch(c){
    800005f0:	07300c93          	li	s9,115
    800005f4:	06400c13          	li	s8,100
    800005f8:	a82d                	j	80000632 <printf+0xa8>
    acquire(&pr.lock);
    800005fa:	00010517          	auipc	a0,0x10
    800005fe:	75e50513          	addi	a0,a0,1886 # 80010d58 <pr>
    80000602:	00000097          	auipc	ra,0x0
    80000606:	5d4080e7          	jalr	1492(ra) # 80000bd6 <acquire>
    8000060a:	bf7d                	j	800005c8 <printf+0x3e>
    panic("null fmt");
    8000060c:	00008517          	auipc	a0,0x8
    80000610:	a1c50513          	addi	a0,a0,-1508 # 80008028 <etext+0x28>
    80000614:	00000097          	auipc	ra,0x0
    80000618:	f2c080e7          	jalr	-212(ra) # 80000540 <panic>
      consputc(c);
    8000061c:	00000097          	auipc	ra,0x0
    80000620:	c60080e7          	jalr	-928(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000624:	2985                	addiw	s3,s3,1
    80000626:	013a07b3          	add	a5,s4,s3
    8000062a:	0007c503          	lbu	a0,0(a5)
    8000062e:	10050463          	beqz	a0,80000736 <printf+0x1ac>
    if(c != '%'){
    80000632:	ff5515e3          	bne	a0,s5,8000061c <printf+0x92>
    c = fmt[++i] & 0xff;
    80000636:	2985                	addiw	s3,s3,1
    80000638:	013a07b3          	add	a5,s4,s3
    8000063c:	0007c783          	lbu	a5,0(a5)
    80000640:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000644:	cbed                	beqz	a5,80000736 <printf+0x1ac>
    switch(c){
    80000646:	05778a63          	beq	a5,s7,8000069a <printf+0x110>
    8000064a:	02fbf663          	bgeu	s7,a5,80000676 <printf+0xec>
    8000064e:	09978863          	beq	a5,s9,800006de <printf+0x154>
    80000652:	07800713          	li	a4,120
    80000656:	0ce79563          	bne	a5,a4,80000720 <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    8000065a:	f8843783          	ld	a5,-120(s0)
    8000065e:	00878713          	addi	a4,a5,8
    80000662:	f8e43423          	sd	a4,-120(s0)
    80000666:	4605                	li	a2,1
    80000668:	85ea                	mv	a1,s10
    8000066a:	4388                	lw	a0,0(a5)
    8000066c:	00000097          	auipc	ra,0x0
    80000670:	e30080e7          	jalr	-464(ra) # 8000049c <printint>
      break;
    80000674:	bf45                	j	80000624 <printf+0x9a>
    switch(c){
    80000676:	09578f63          	beq	a5,s5,80000714 <printf+0x18a>
    8000067a:	0b879363          	bne	a5,s8,80000720 <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067e:	f8843783          	ld	a5,-120(s0)
    80000682:	00878713          	addi	a4,a5,8
    80000686:	f8e43423          	sd	a4,-120(s0)
    8000068a:	4605                	li	a2,1
    8000068c:	45a9                	li	a1,10
    8000068e:	4388                	lw	a0,0(a5)
    80000690:	00000097          	auipc	ra,0x0
    80000694:	e0c080e7          	jalr	-500(ra) # 8000049c <printint>
      break;
    80000698:	b771                	j	80000624 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000069a:	f8843783          	ld	a5,-120(s0)
    8000069e:	00878713          	addi	a4,a5,8
    800006a2:	f8e43423          	sd	a4,-120(s0)
    800006a6:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006aa:	03000513          	li	a0,48
    800006ae:	00000097          	auipc	ra,0x0
    800006b2:	bce080e7          	jalr	-1074(ra) # 8000027c <consputc>
  consputc('x');
    800006b6:	07800513          	li	a0,120
    800006ba:	00000097          	auipc	ra,0x0
    800006be:	bc2080e7          	jalr	-1086(ra) # 8000027c <consputc>
    800006c2:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c4:	03c95793          	srli	a5,s2,0x3c
    800006c8:	97da                	add	a5,a5,s6
    800006ca:	0007c503          	lbu	a0,0(a5)
    800006ce:	00000097          	auipc	ra,0x0
    800006d2:	bae080e7          	jalr	-1106(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d6:	0912                	slli	s2,s2,0x4
    800006d8:	34fd                	addiw	s1,s1,-1
    800006da:	f4ed                	bnez	s1,800006c4 <printf+0x13a>
    800006dc:	b7a1                	j	80000624 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	6384                	ld	s1,0(a5)
    800006ec:	cc89                	beqz	s1,80000706 <printf+0x17c>
      for(; *s; s++)
    800006ee:	0004c503          	lbu	a0,0(s1)
    800006f2:	d90d                	beqz	a0,80000624 <printf+0x9a>
        consputc(*s);
    800006f4:	00000097          	auipc	ra,0x0
    800006f8:	b88080e7          	jalr	-1144(ra) # 8000027c <consputc>
      for(; *s; s++)
    800006fc:	0485                	addi	s1,s1,1
    800006fe:	0004c503          	lbu	a0,0(s1)
    80000702:	f96d                	bnez	a0,800006f4 <printf+0x16a>
    80000704:	b705                	j	80000624 <printf+0x9a>
        s = "(null)";
    80000706:	00008497          	auipc	s1,0x8
    8000070a:	91a48493          	addi	s1,s1,-1766 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070e:	02800513          	li	a0,40
    80000712:	b7cd                	j	800006f4 <printf+0x16a>
      consputc('%');
    80000714:	8556                	mv	a0,s5
    80000716:	00000097          	auipc	ra,0x0
    8000071a:	b66080e7          	jalr	-1178(ra) # 8000027c <consputc>
      break;
    8000071e:	b719                	j	80000624 <printf+0x9a>
      consputc('%');
    80000720:	8556                	mv	a0,s5
    80000722:	00000097          	auipc	ra,0x0
    80000726:	b5a080e7          	jalr	-1190(ra) # 8000027c <consputc>
      consputc(c);
    8000072a:	8526                	mv	a0,s1
    8000072c:	00000097          	auipc	ra,0x0
    80000730:	b50080e7          	jalr	-1200(ra) # 8000027c <consputc>
      break;
    80000734:	bdc5                	j	80000624 <printf+0x9a>
  if(locking)
    80000736:	020d9163          	bnez	s11,80000758 <printf+0x1ce>
}
    8000073a:	70e6                	ld	ra,120(sp)
    8000073c:	7446                	ld	s0,112(sp)
    8000073e:	74a6                	ld	s1,104(sp)
    80000740:	7906                	ld	s2,96(sp)
    80000742:	69e6                	ld	s3,88(sp)
    80000744:	6a46                	ld	s4,80(sp)
    80000746:	6aa6                	ld	s5,72(sp)
    80000748:	6b06                	ld	s6,64(sp)
    8000074a:	7be2                	ld	s7,56(sp)
    8000074c:	7c42                	ld	s8,48(sp)
    8000074e:	7ca2                	ld	s9,40(sp)
    80000750:	7d02                	ld	s10,32(sp)
    80000752:	6de2                	ld	s11,24(sp)
    80000754:	6129                	addi	sp,sp,192
    80000756:	8082                	ret
    release(&pr.lock);
    80000758:	00010517          	auipc	a0,0x10
    8000075c:	60050513          	addi	a0,a0,1536 # 80010d58 <pr>
    80000760:	00000097          	auipc	ra,0x0
    80000764:	52a080e7          	jalr	1322(ra) # 80000c8a <release>
}
    80000768:	bfc9                	j	8000073a <printf+0x1b0>

000000008000076a <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076a:	1101                	addi	sp,sp,-32
    8000076c:	ec06                	sd	ra,24(sp)
    8000076e:	e822                	sd	s0,16(sp)
    80000770:	e426                	sd	s1,8(sp)
    80000772:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000774:	00010497          	auipc	s1,0x10
    80000778:	5e448493          	addi	s1,s1,1508 # 80010d58 <pr>
    8000077c:	00008597          	auipc	a1,0x8
    80000780:	8bc58593          	addi	a1,a1,-1860 # 80008038 <etext+0x38>
    80000784:	8526                	mv	a0,s1
    80000786:	00000097          	auipc	ra,0x0
    8000078a:	3c0080e7          	jalr	960(ra) # 80000b46 <initlock>
  pr.locking = 1;
    8000078e:	4785                	li	a5,1
    80000790:	cc9c                	sw	a5,24(s1)
}
    80000792:	60e2                	ld	ra,24(sp)
    80000794:	6442                	ld	s0,16(sp)
    80000796:	64a2                	ld	s1,8(sp)
    80000798:	6105                	addi	sp,sp,32
    8000079a:	8082                	ret

000000008000079c <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079c:	1141                	addi	sp,sp,-16
    8000079e:	e406                	sd	ra,8(sp)
    800007a0:	e022                	sd	s0,0(sp)
    800007a2:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a4:	100007b7          	lui	a5,0x10000
    800007a8:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007ac:	f8000713          	li	a4,-128
    800007b0:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b4:	470d                	li	a4,3
    800007b6:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007ba:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007be:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c2:	469d                	li	a3,7
    800007c4:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c8:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007cc:	00008597          	auipc	a1,0x8
    800007d0:	88c58593          	addi	a1,a1,-1908 # 80008058 <digits+0x18>
    800007d4:	00010517          	auipc	a0,0x10
    800007d8:	5a450513          	addi	a0,a0,1444 # 80010d78 <uart_tx_lock>
    800007dc:	00000097          	auipc	ra,0x0
    800007e0:	36a080e7          	jalr	874(ra) # 80000b46 <initlock>
}
    800007e4:	60a2                	ld	ra,8(sp)
    800007e6:	6402                	ld	s0,0(sp)
    800007e8:	0141                	addi	sp,sp,16
    800007ea:	8082                	ret

00000000800007ec <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ec:	1101                	addi	sp,sp,-32
    800007ee:	ec06                	sd	ra,24(sp)
    800007f0:	e822                	sd	s0,16(sp)
    800007f2:	e426                	sd	s1,8(sp)
    800007f4:	1000                	addi	s0,sp,32
    800007f6:	84aa                	mv	s1,a0
  push_off();
    800007f8:	00000097          	auipc	ra,0x0
    800007fc:	392080e7          	jalr	914(ra) # 80000b8a <push_off>

  if(panicked){
    80000800:	00008797          	auipc	a5,0x8
    80000804:	3307a783          	lw	a5,816(a5) # 80008b30 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000808:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080c:	c391                	beqz	a5,80000810 <uartputc_sync+0x24>
    for(;;)
    8000080e:	a001                	j	8000080e <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000810:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000814:	0207f793          	andi	a5,a5,32
    80000818:	dfe5                	beqz	a5,80000810 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000081a:	0ff4f513          	zext.b	a0,s1
    8000081e:	100007b7          	lui	a5,0x10000
    80000822:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000826:	00000097          	auipc	ra,0x0
    8000082a:	404080e7          	jalr	1028(ra) # 80000c2a <pop_off>
}
    8000082e:	60e2                	ld	ra,24(sp)
    80000830:	6442                	ld	s0,16(sp)
    80000832:	64a2                	ld	s1,8(sp)
    80000834:	6105                	addi	sp,sp,32
    80000836:	8082                	ret

0000000080000838 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000838:	00008797          	auipc	a5,0x8
    8000083c:	3007b783          	ld	a5,768(a5) # 80008b38 <uart_tx_r>
    80000840:	00008717          	auipc	a4,0x8
    80000844:	30073703          	ld	a4,768(a4) # 80008b40 <uart_tx_w>
    80000848:	06f70a63          	beq	a4,a5,800008bc <uartstart+0x84>
{
    8000084c:	7139                	addi	sp,sp,-64
    8000084e:	fc06                	sd	ra,56(sp)
    80000850:	f822                	sd	s0,48(sp)
    80000852:	f426                	sd	s1,40(sp)
    80000854:	f04a                	sd	s2,32(sp)
    80000856:	ec4e                	sd	s3,24(sp)
    80000858:	e852                	sd	s4,16(sp)
    8000085a:	e456                	sd	s5,8(sp)
    8000085c:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085e:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000862:	00010a17          	auipc	s4,0x10
    80000866:	516a0a13          	addi	s4,s4,1302 # 80010d78 <uart_tx_lock>
    uart_tx_r += 1;
    8000086a:	00008497          	auipc	s1,0x8
    8000086e:	2ce48493          	addi	s1,s1,718 # 80008b38 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000872:	00008997          	auipc	s3,0x8
    80000876:	2ce98993          	addi	s3,s3,718 # 80008b40 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000087a:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087e:	02077713          	andi	a4,a4,32
    80000882:	c705                	beqz	a4,800008aa <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000884:	01f7f713          	andi	a4,a5,31
    80000888:	9752                	add	a4,a4,s4
    8000088a:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000088e:	0785                	addi	a5,a5,1
    80000890:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000892:	8526                	mv	a0,s1
    80000894:	00002097          	auipc	ra,0x2
    80000898:	b56080e7          	jalr	-1194(ra) # 800023ea <wakeup>
    
    WriteReg(THR, c);
    8000089c:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008a0:	609c                	ld	a5,0(s1)
    800008a2:	0009b703          	ld	a4,0(s3)
    800008a6:	fcf71ae3          	bne	a4,a5,8000087a <uartstart+0x42>
  }
}
    800008aa:	70e2                	ld	ra,56(sp)
    800008ac:	7442                	ld	s0,48(sp)
    800008ae:	74a2                	ld	s1,40(sp)
    800008b0:	7902                	ld	s2,32(sp)
    800008b2:	69e2                	ld	s3,24(sp)
    800008b4:	6a42                	ld	s4,16(sp)
    800008b6:	6aa2                	ld	s5,8(sp)
    800008b8:	6121                	addi	sp,sp,64
    800008ba:	8082                	ret
    800008bc:	8082                	ret

00000000800008be <uartputc>:
{
    800008be:	7179                	addi	sp,sp,-48
    800008c0:	f406                	sd	ra,40(sp)
    800008c2:	f022                	sd	s0,32(sp)
    800008c4:	ec26                	sd	s1,24(sp)
    800008c6:	e84a                	sd	s2,16(sp)
    800008c8:	e44e                	sd	s3,8(sp)
    800008ca:	e052                	sd	s4,0(sp)
    800008cc:	1800                	addi	s0,sp,48
    800008ce:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008d0:	00010517          	auipc	a0,0x10
    800008d4:	4a850513          	addi	a0,a0,1192 # 80010d78 <uart_tx_lock>
    800008d8:	00000097          	auipc	ra,0x0
    800008dc:	2fe080e7          	jalr	766(ra) # 80000bd6 <acquire>
  if(panicked){
    800008e0:	00008797          	auipc	a5,0x8
    800008e4:	2507a783          	lw	a5,592(a5) # 80008b30 <panicked>
    800008e8:	e7c9                	bnez	a5,80000972 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008ea:	00008717          	auipc	a4,0x8
    800008ee:	25673703          	ld	a4,598(a4) # 80008b40 <uart_tx_w>
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	2467b783          	ld	a5,582(a5) # 80008b38 <uart_tx_r>
    800008fa:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fe:	00010997          	auipc	s3,0x10
    80000902:	47a98993          	addi	s3,s3,1146 # 80010d78 <uart_tx_lock>
    80000906:	00008497          	auipc	s1,0x8
    8000090a:	23248493          	addi	s1,s1,562 # 80008b38 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090e:	00008917          	auipc	s2,0x8
    80000912:	23290913          	addi	s2,s2,562 # 80008b40 <uart_tx_w>
    80000916:	00e79f63          	bne	a5,a4,80000934 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000091a:	85ce                	mv	a1,s3
    8000091c:	8526                	mv	a0,s1
    8000091e:	00002097          	auipc	ra,0x2
    80000922:	91c080e7          	jalr	-1764(ra) # 8000223a <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000926:	00093703          	ld	a4,0(s2)
    8000092a:	609c                	ld	a5,0(s1)
    8000092c:	02078793          	addi	a5,a5,32
    80000930:	fee785e3          	beq	a5,a4,8000091a <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000934:	00010497          	auipc	s1,0x10
    80000938:	44448493          	addi	s1,s1,1092 # 80010d78 <uart_tx_lock>
    8000093c:	01f77793          	andi	a5,a4,31
    80000940:	97a6                	add	a5,a5,s1
    80000942:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000946:	0705                	addi	a4,a4,1
    80000948:	00008797          	auipc	a5,0x8
    8000094c:	1ee7bc23          	sd	a4,504(a5) # 80008b40 <uart_tx_w>
  uartstart();
    80000950:	00000097          	auipc	ra,0x0
    80000954:	ee8080e7          	jalr	-280(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    80000958:	8526                	mv	a0,s1
    8000095a:	00000097          	auipc	ra,0x0
    8000095e:	330080e7          	jalr	816(ra) # 80000c8a <release>
}
    80000962:	70a2                	ld	ra,40(sp)
    80000964:	7402                	ld	s0,32(sp)
    80000966:	64e2                	ld	s1,24(sp)
    80000968:	6942                	ld	s2,16(sp)
    8000096a:	69a2                	ld	s3,8(sp)
    8000096c:	6a02                	ld	s4,0(sp)
    8000096e:	6145                	addi	sp,sp,48
    80000970:	8082                	ret
    for(;;)
    80000972:	a001                	j	80000972 <uartputc+0xb4>

0000000080000974 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000974:	1141                	addi	sp,sp,-16
    80000976:	e422                	sd	s0,8(sp)
    80000978:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    8000097a:	100007b7          	lui	a5,0x10000
    8000097e:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000982:	8b85                	andi	a5,a5,1
    80000984:	cb81                	beqz	a5,80000994 <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    8000098e:	6422                	ld	s0,8(sp)
    80000990:	0141                	addi	sp,sp,16
    80000992:	8082                	ret
    return -1;
    80000994:	557d                	li	a0,-1
    80000996:	bfe5                	j	8000098e <uartgetc+0x1a>

0000000080000998 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    80000998:	1101                	addi	sp,sp,-32
    8000099a:	ec06                	sd	ra,24(sp)
    8000099c:	e822                	sd	s0,16(sp)
    8000099e:	e426                	sd	s1,8(sp)
    800009a0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009a2:	54fd                	li	s1,-1
    800009a4:	a029                	j	800009ae <uartintr+0x16>
      break;
    consoleintr(c);
    800009a6:	00000097          	auipc	ra,0x0
    800009aa:	918080e7          	jalr	-1768(ra) # 800002be <consoleintr>
    int c = uartgetc();
    800009ae:	00000097          	auipc	ra,0x0
    800009b2:	fc6080e7          	jalr	-58(ra) # 80000974 <uartgetc>
    if(c == -1)
    800009b6:	fe9518e3          	bne	a0,s1,800009a6 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ba:	00010497          	auipc	s1,0x10
    800009be:	3be48493          	addi	s1,s1,958 # 80010d78 <uart_tx_lock>
    800009c2:	8526                	mv	a0,s1
    800009c4:	00000097          	auipc	ra,0x0
    800009c8:	212080e7          	jalr	530(ra) # 80000bd6 <acquire>
  uartstart();
    800009cc:	00000097          	auipc	ra,0x0
    800009d0:	e6c080e7          	jalr	-404(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    800009d4:	8526                	mv	a0,s1
    800009d6:	00000097          	auipc	ra,0x0
    800009da:	2b4080e7          	jalr	692(ra) # 80000c8a <release>
}
    800009de:	60e2                	ld	ra,24(sp)
    800009e0:	6442                	ld	s0,16(sp)
    800009e2:	64a2                	ld	s1,8(sp)
    800009e4:	6105                	addi	sp,sp,32
    800009e6:	8082                	ret

00000000800009e8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009e8:	1101                	addi	sp,sp,-32
    800009ea:	ec06                	sd	ra,24(sp)
    800009ec:	e822                	sd	s0,16(sp)
    800009ee:	e426                	sd	s1,8(sp)
    800009f0:	e04a                	sd	s2,0(sp)
    800009f2:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f4:	03451793          	slli	a5,a0,0x34
    800009f8:	ebb9                	bnez	a5,80000a4e <kfree+0x66>
    800009fa:	84aa                	mv	s1,a0
    800009fc:	00022797          	auipc	a5,0x22
    80000a00:	5e478793          	addi	a5,a5,1508 # 80022fe0 <end>
    80000a04:	04f56563          	bltu	a0,a5,80000a4e <kfree+0x66>
    80000a08:	47c5                	li	a5,17
    80000a0a:	07ee                	slli	a5,a5,0x1b
    80000a0c:	04f57163          	bgeu	a0,a5,80000a4e <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a10:	6605                	lui	a2,0x1
    80000a12:	4585                	li	a1,1
    80000a14:	00000097          	auipc	ra,0x0
    80000a18:	2be080e7          	jalr	702(ra) # 80000cd2 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a1c:	00010917          	auipc	s2,0x10
    80000a20:	39490913          	addi	s2,s2,916 # 80010db0 <kmem>
    80000a24:	854a                	mv	a0,s2
    80000a26:	00000097          	auipc	ra,0x0
    80000a2a:	1b0080e7          	jalr	432(ra) # 80000bd6 <acquire>
  r->next = kmem.freelist;
    80000a2e:	01893783          	ld	a5,24(s2)
    80000a32:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a34:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a38:	854a                	mv	a0,s2
    80000a3a:	00000097          	auipc	ra,0x0
    80000a3e:	250080e7          	jalr	592(ra) # 80000c8a <release>
}
    80000a42:	60e2                	ld	ra,24(sp)
    80000a44:	6442                	ld	s0,16(sp)
    80000a46:	64a2                	ld	s1,8(sp)
    80000a48:	6902                	ld	s2,0(sp)
    80000a4a:	6105                	addi	sp,sp,32
    80000a4c:	8082                	ret
    panic("kfree");
    80000a4e:	00007517          	auipc	a0,0x7
    80000a52:	61250513          	addi	a0,a0,1554 # 80008060 <digits+0x20>
    80000a56:	00000097          	auipc	ra,0x0
    80000a5a:	aea080e7          	jalr	-1302(ra) # 80000540 <panic>

0000000080000a5e <freerange>:
{
    80000a5e:	7179                	addi	sp,sp,-48
    80000a60:	f406                	sd	ra,40(sp)
    80000a62:	f022                	sd	s0,32(sp)
    80000a64:	ec26                	sd	s1,24(sp)
    80000a66:	e84a                	sd	s2,16(sp)
    80000a68:	e44e                	sd	s3,8(sp)
    80000a6a:	e052                	sd	s4,0(sp)
    80000a6c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a6e:	6785                	lui	a5,0x1
    80000a70:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000a74:	00e504b3          	add	s1,a0,a4
    80000a78:	777d                	lui	a4,0xfffff
    80000a7a:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a7c:	94be                	add	s1,s1,a5
    80000a7e:	0095ee63          	bltu	a1,s1,80000a9a <freerange+0x3c>
    80000a82:	892e                	mv	s2,a1
    kfree(p);
    80000a84:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a86:	6985                	lui	s3,0x1
    kfree(p);
    80000a88:	01448533          	add	a0,s1,s4
    80000a8c:	00000097          	auipc	ra,0x0
    80000a90:	f5c080e7          	jalr	-164(ra) # 800009e8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	94ce                	add	s1,s1,s3
    80000a96:	fe9979e3          	bgeu	s2,s1,80000a88 <freerange+0x2a>
}
    80000a9a:	70a2                	ld	ra,40(sp)
    80000a9c:	7402                	ld	s0,32(sp)
    80000a9e:	64e2                	ld	s1,24(sp)
    80000aa0:	6942                	ld	s2,16(sp)
    80000aa2:	69a2                	ld	s3,8(sp)
    80000aa4:	6a02                	ld	s4,0(sp)
    80000aa6:	6145                	addi	sp,sp,48
    80000aa8:	8082                	ret

0000000080000aaa <kinit>:
{
    80000aaa:	1141                	addi	sp,sp,-16
    80000aac:	e406                	sd	ra,8(sp)
    80000aae:	e022                	sd	s0,0(sp)
    80000ab0:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ab2:	00007597          	auipc	a1,0x7
    80000ab6:	5b658593          	addi	a1,a1,1462 # 80008068 <digits+0x28>
    80000aba:	00010517          	auipc	a0,0x10
    80000abe:	2f650513          	addi	a0,a0,758 # 80010db0 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	084080e7          	jalr	132(ra) # 80000b46 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	00022517          	auipc	a0,0x22
    80000ad2:	51250513          	addi	a0,a0,1298 # 80022fe0 <end>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	f88080e7          	jalr	-120(ra) # 80000a5e <freerange>
}
    80000ade:	60a2                	ld	ra,8(sp)
    80000ae0:	6402                	ld	s0,0(sp)
    80000ae2:	0141                	addi	sp,sp,16
    80000ae4:	8082                	ret

0000000080000ae6 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae6:	1101                	addi	sp,sp,-32
    80000ae8:	ec06                	sd	ra,24(sp)
    80000aea:	e822                	sd	s0,16(sp)
    80000aec:	e426                	sd	s1,8(sp)
    80000aee:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000af0:	00010497          	auipc	s1,0x10
    80000af4:	2c048493          	addi	s1,s1,704 # 80010db0 <kmem>
    80000af8:	8526                	mv	a0,s1
    80000afa:	00000097          	auipc	ra,0x0
    80000afe:	0dc080e7          	jalr	220(ra) # 80000bd6 <acquire>
  r = kmem.freelist;
    80000b02:	6c84                	ld	s1,24(s1)
  if(r)
    80000b04:	c885                	beqz	s1,80000b34 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b06:	609c                	ld	a5,0(s1)
    80000b08:	00010517          	auipc	a0,0x10
    80000b0c:	2a850513          	addi	a0,a0,680 # 80010db0 <kmem>
    80000b10:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b12:	00000097          	auipc	ra,0x0
    80000b16:	178080e7          	jalr	376(ra) # 80000c8a <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b1a:	6605                	lui	a2,0x1
    80000b1c:	4595                	li	a1,5
    80000b1e:	8526                	mv	a0,s1
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	1b2080e7          	jalr	434(ra) # 80000cd2 <memset>
  return (void*)r;
}
    80000b28:	8526                	mv	a0,s1
    80000b2a:	60e2                	ld	ra,24(sp)
    80000b2c:	6442                	ld	s0,16(sp)
    80000b2e:	64a2                	ld	s1,8(sp)
    80000b30:	6105                	addi	sp,sp,32
    80000b32:	8082                	ret
  release(&kmem.lock);
    80000b34:	00010517          	auipc	a0,0x10
    80000b38:	27c50513          	addi	a0,a0,636 # 80010db0 <kmem>
    80000b3c:	00000097          	auipc	ra,0x0
    80000b40:	14e080e7          	jalr	334(ra) # 80000c8a <release>
  if(r)
    80000b44:	b7d5                	j	80000b28 <kalloc+0x42>

0000000080000b46 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b46:	1141                	addi	sp,sp,-16
    80000b48:	e422                	sd	s0,8(sp)
    80000b4a:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b4c:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b4e:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b52:	00053823          	sd	zero,16(a0)
}
    80000b56:	6422                	ld	s0,8(sp)
    80000b58:	0141                	addi	sp,sp,16
    80000b5a:	8082                	ret

0000000080000b5c <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b5c:	411c                	lw	a5,0(a0)
    80000b5e:	e399                	bnez	a5,80000b64 <holding+0x8>
    80000b60:	4501                	li	a0,0
  return r;
}
    80000b62:	8082                	ret
{
    80000b64:	1101                	addi	sp,sp,-32
    80000b66:	ec06                	sd	ra,24(sp)
    80000b68:	e822                	sd	s0,16(sp)
    80000b6a:	e426                	sd	s1,8(sp)
    80000b6c:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b6e:	6904                	ld	s1,16(a0)
    80000b70:	00001097          	auipc	ra,0x1
    80000b74:	e20080e7          	jalr	-480(ra) # 80001990 <mycpu>
    80000b78:	40a48533          	sub	a0,s1,a0
    80000b7c:	00153513          	seqz	a0,a0
}
    80000b80:	60e2                	ld	ra,24(sp)
    80000b82:	6442                	ld	s0,16(sp)
    80000b84:	64a2                	ld	s1,8(sp)
    80000b86:	6105                	addi	sp,sp,32
    80000b88:	8082                	ret

0000000080000b8a <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b8a:	1101                	addi	sp,sp,-32
    80000b8c:	ec06                	sd	ra,24(sp)
    80000b8e:	e822                	sd	s0,16(sp)
    80000b90:	e426                	sd	s1,8(sp)
    80000b92:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b94:	100024f3          	csrr	s1,sstatus
    80000b98:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b9c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b9e:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000ba2:	00001097          	auipc	ra,0x1
    80000ba6:	dee080e7          	jalr	-530(ra) # 80001990 <mycpu>
    80000baa:	5d3c                	lw	a5,120(a0)
    80000bac:	cf89                	beqz	a5,80000bc6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bae:	00001097          	auipc	ra,0x1
    80000bb2:	de2080e7          	jalr	-542(ra) # 80001990 <mycpu>
    80000bb6:	5d3c                	lw	a5,120(a0)
    80000bb8:	2785                	addiw	a5,a5,1
    80000bba:	dd3c                	sw	a5,120(a0)
}
    80000bbc:	60e2                	ld	ra,24(sp)
    80000bbe:	6442                	ld	s0,16(sp)
    80000bc0:	64a2                	ld	s1,8(sp)
    80000bc2:	6105                	addi	sp,sp,32
    80000bc4:	8082                	ret
    mycpu()->intena = old;
    80000bc6:	00001097          	auipc	ra,0x1
    80000bca:	dca080e7          	jalr	-566(ra) # 80001990 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bce:	8085                	srli	s1,s1,0x1
    80000bd0:	8885                	andi	s1,s1,1
    80000bd2:	dd64                	sw	s1,124(a0)
    80000bd4:	bfe9                	j	80000bae <push_off+0x24>

0000000080000bd6 <acquire>:
{
    80000bd6:	1101                	addi	sp,sp,-32
    80000bd8:	ec06                	sd	ra,24(sp)
    80000bda:	e822                	sd	s0,16(sp)
    80000bdc:	e426                	sd	s1,8(sp)
    80000bde:	1000                	addi	s0,sp,32
    80000be0:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000be2:	00000097          	auipc	ra,0x0
    80000be6:	fa8080e7          	jalr	-88(ra) # 80000b8a <push_off>
  if(holding(lk))
    80000bea:	8526                	mv	a0,s1
    80000bec:	00000097          	auipc	ra,0x0
    80000bf0:	f70080e7          	jalr	-144(ra) # 80000b5c <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf4:	4705                	li	a4,1
  if(holding(lk))
    80000bf6:	e115                	bnez	a0,80000c1a <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf8:	87ba                	mv	a5,a4
    80000bfa:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bfe:	2781                	sext.w	a5,a5
    80000c00:	ffe5                	bnez	a5,80000bf8 <acquire+0x22>
  __sync_synchronize();
    80000c02:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c06:	00001097          	auipc	ra,0x1
    80000c0a:	d8a080e7          	jalr	-630(ra) # 80001990 <mycpu>
    80000c0e:	e888                	sd	a0,16(s1)
}
    80000c10:	60e2                	ld	ra,24(sp)
    80000c12:	6442                	ld	s0,16(sp)
    80000c14:	64a2                	ld	s1,8(sp)
    80000c16:	6105                	addi	sp,sp,32
    80000c18:	8082                	ret
    panic("acquire");
    80000c1a:	00007517          	auipc	a0,0x7
    80000c1e:	45650513          	addi	a0,a0,1110 # 80008070 <digits+0x30>
    80000c22:	00000097          	auipc	ra,0x0
    80000c26:	91e080e7          	jalr	-1762(ra) # 80000540 <panic>

0000000080000c2a <pop_off>:

void
pop_off(void)
{
    80000c2a:	1141                	addi	sp,sp,-16
    80000c2c:	e406                	sd	ra,8(sp)
    80000c2e:	e022                	sd	s0,0(sp)
    80000c30:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c32:	00001097          	auipc	ra,0x1
    80000c36:	d5e080e7          	jalr	-674(ra) # 80001990 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c3a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c3e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c40:	e78d                	bnez	a5,80000c6a <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c42:	5d3c                	lw	a5,120(a0)
    80000c44:	02f05b63          	blez	a5,80000c7a <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c48:	37fd                	addiw	a5,a5,-1
    80000c4a:	0007871b          	sext.w	a4,a5
    80000c4e:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c50:	eb09                	bnez	a4,80000c62 <pop_off+0x38>
    80000c52:	5d7c                	lw	a5,124(a0)
    80000c54:	c799                	beqz	a5,80000c62 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c56:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c5a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c5e:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c62:	60a2                	ld	ra,8(sp)
    80000c64:	6402                	ld	s0,0(sp)
    80000c66:	0141                	addi	sp,sp,16
    80000c68:	8082                	ret
    panic("pop_off - interruptible");
    80000c6a:	00007517          	auipc	a0,0x7
    80000c6e:	40e50513          	addi	a0,a0,1038 # 80008078 <digits+0x38>
    80000c72:	00000097          	auipc	ra,0x0
    80000c76:	8ce080e7          	jalr	-1842(ra) # 80000540 <panic>
    panic("pop_off");
    80000c7a:	00007517          	auipc	a0,0x7
    80000c7e:	41650513          	addi	a0,a0,1046 # 80008090 <digits+0x50>
    80000c82:	00000097          	auipc	ra,0x0
    80000c86:	8be080e7          	jalr	-1858(ra) # 80000540 <panic>

0000000080000c8a <release>:
{
    80000c8a:	1101                	addi	sp,sp,-32
    80000c8c:	ec06                	sd	ra,24(sp)
    80000c8e:	e822                	sd	s0,16(sp)
    80000c90:	e426                	sd	s1,8(sp)
    80000c92:	1000                	addi	s0,sp,32
    80000c94:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c96:	00000097          	auipc	ra,0x0
    80000c9a:	ec6080e7          	jalr	-314(ra) # 80000b5c <holding>
    80000c9e:	c115                	beqz	a0,80000cc2 <release+0x38>
  lk->cpu = 0;
    80000ca0:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ca4:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca8:	0f50000f          	fence	iorw,ow
    80000cac:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cb0:	00000097          	auipc	ra,0x0
    80000cb4:	f7a080e7          	jalr	-134(ra) # 80000c2a <pop_off>
}
    80000cb8:	60e2                	ld	ra,24(sp)
    80000cba:	6442                	ld	s0,16(sp)
    80000cbc:	64a2                	ld	s1,8(sp)
    80000cbe:	6105                	addi	sp,sp,32
    80000cc0:	8082                	ret
    panic("release");
    80000cc2:	00007517          	auipc	a0,0x7
    80000cc6:	3d650513          	addi	a0,a0,982 # 80008098 <digits+0x58>
    80000cca:	00000097          	auipc	ra,0x0
    80000cce:	876080e7          	jalr	-1930(ra) # 80000540 <panic>

0000000080000cd2 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cd2:	1141                	addi	sp,sp,-16
    80000cd4:	e422                	sd	s0,8(sp)
    80000cd6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd8:	ca19                	beqz	a2,80000cee <memset+0x1c>
    80000cda:	87aa                	mv	a5,a0
    80000cdc:	1602                	slli	a2,a2,0x20
    80000cde:	9201                	srli	a2,a2,0x20
    80000ce0:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000ce4:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ce8:	0785                	addi	a5,a5,1
    80000cea:	fee79de3          	bne	a5,a4,80000ce4 <memset+0x12>
  }
  return dst;
}
    80000cee:	6422                	ld	s0,8(sp)
    80000cf0:	0141                	addi	sp,sp,16
    80000cf2:	8082                	ret

0000000080000cf4 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cf4:	1141                	addi	sp,sp,-16
    80000cf6:	e422                	sd	s0,8(sp)
    80000cf8:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cfa:	ca05                	beqz	a2,80000d2a <memcmp+0x36>
    80000cfc:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000d00:	1682                	slli	a3,a3,0x20
    80000d02:	9281                	srli	a3,a3,0x20
    80000d04:	0685                	addi	a3,a3,1
    80000d06:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d08:	00054783          	lbu	a5,0(a0)
    80000d0c:	0005c703          	lbu	a4,0(a1)
    80000d10:	00e79863          	bne	a5,a4,80000d20 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d14:	0505                	addi	a0,a0,1
    80000d16:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d18:	fed518e3          	bne	a0,a3,80000d08 <memcmp+0x14>
  }

  return 0;
    80000d1c:	4501                	li	a0,0
    80000d1e:	a019                	j	80000d24 <memcmp+0x30>
      return *s1 - *s2;
    80000d20:	40e7853b          	subw	a0,a5,a4
}
    80000d24:	6422                	ld	s0,8(sp)
    80000d26:	0141                	addi	sp,sp,16
    80000d28:	8082                	ret
  return 0;
    80000d2a:	4501                	li	a0,0
    80000d2c:	bfe5                	j	80000d24 <memcmp+0x30>

0000000080000d2e <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d2e:	1141                	addi	sp,sp,-16
    80000d30:	e422                	sd	s0,8(sp)
    80000d32:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d34:	c205                	beqz	a2,80000d54 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d36:	02a5e263          	bltu	a1,a0,80000d5a <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d3a:	1602                	slli	a2,a2,0x20
    80000d3c:	9201                	srli	a2,a2,0x20
    80000d3e:	00c587b3          	add	a5,a1,a2
{
    80000d42:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d44:	0585                	addi	a1,a1,1
    80000d46:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffdc021>
    80000d48:	fff5c683          	lbu	a3,-1(a1)
    80000d4c:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d50:	fef59ae3          	bne	a1,a5,80000d44 <memmove+0x16>

  return dst;
}
    80000d54:	6422                	ld	s0,8(sp)
    80000d56:	0141                	addi	sp,sp,16
    80000d58:	8082                	ret
  if(s < d && s + n > d){
    80000d5a:	02061693          	slli	a3,a2,0x20
    80000d5e:	9281                	srli	a3,a3,0x20
    80000d60:	00d58733          	add	a4,a1,a3
    80000d64:	fce57be3          	bgeu	a0,a4,80000d3a <memmove+0xc>
    d += n;
    80000d68:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d6a:	fff6079b          	addiw	a5,a2,-1
    80000d6e:	1782                	slli	a5,a5,0x20
    80000d70:	9381                	srli	a5,a5,0x20
    80000d72:	fff7c793          	not	a5,a5
    80000d76:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d78:	177d                	addi	a4,a4,-1
    80000d7a:	16fd                	addi	a3,a3,-1
    80000d7c:	00074603          	lbu	a2,0(a4)
    80000d80:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d84:	fee79ae3          	bne	a5,a4,80000d78 <memmove+0x4a>
    80000d88:	b7f1                	j	80000d54 <memmove+0x26>

0000000080000d8a <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d8a:	1141                	addi	sp,sp,-16
    80000d8c:	e406                	sd	ra,8(sp)
    80000d8e:	e022                	sd	s0,0(sp)
    80000d90:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d92:	00000097          	auipc	ra,0x0
    80000d96:	f9c080e7          	jalr	-100(ra) # 80000d2e <memmove>
}
    80000d9a:	60a2                	ld	ra,8(sp)
    80000d9c:	6402                	ld	s0,0(sp)
    80000d9e:	0141                	addi	sp,sp,16
    80000da0:	8082                	ret

0000000080000da2 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000da2:	1141                	addi	sp,sp,-16
    80000da4:	e422                	sd	s0,8(sp)
    80000da6:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000da8:	ce11                	beqz	a2,80000dc4 <strncmp+0x22>
    80000daa:	00054783          	lbu	a5,0(a0)
    80000dae:	cf89                	beqz	a5,80000dc8 <strncmp+0x26>
    80000db0:	0005c703          	lbu	a4,0(a1)
    80000db4:	00f71a63          	bne	a4,a5,80000dc8 <strncmp+0x26>
    n--, p++, q++;
    80000db8:	367d                	addiw	a2,a2,-1
    80000dba:	0505                	addi	a0,a0,1
    80000dbc:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dbe:	f675                	bnez	a2,80000daa <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dc0:	4501                	li	a0,0
    80000dc2:	a809                	j	80000dd4 <strncmp+0x32>
    80000dc4:	4501                	li	a0,0
    80000dc6:	a039                	j	80000dd4 <strncmp+0x32>
  if(n == 0)
    80000dc8:	ca09                	beqz	a2,80000dda <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dca:	00054503          	lbu	a0,0(a0)
    80000dce:	0005c783          	lbu	a5,0(a1)
    80000dd2:	9d1d                	subw	a0,a0,a5
}
    80000dd4:	6422                	ld	s0,8(sp)
    80000dd6:	0141                	addi	sp,sp,16
    80000dd8:	8082                	ret
    return 0;
    80000dda:	4501                	li	a0,0
    80000ddc:	bfe5                	j	80000dd4 <strncmp+0x32>

0000000080000dde <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dde:	1141                	addi	sp,sp,-16
    80000de0:	e422                	sd	s0,8(sp)
    80000de2:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000de4:	872a                	mv	a4,a0
    80000de6:	8832                	mv	a6,a2
    80000de8:	367d                	addiw	a2,a2,-1
    80000dea:	01005963          	blez	a6,80000dfc <strncpy+0x1e>
    80000dee:	0705                	addi	a4,a4,1
    80000df0:	0005c783          	lbu	a5,0(a1)
    80000df4:	fef70fa3          	sb	a5,-1(a4)
    80000df8:	0585                	addi	a1,a1,1
    80000dfa:	f7f5                	bnez	a5,80000de6 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000dfc:	86ba                	mv	a3,a4
    80000dfe:	00c05c63          	blez	a2,80000e16 <strncpy+0x38>
    *s++ = 0;
    80000e02:	0685                	addi	a3,a3,1
    80000e04:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e08:	40d707bb          	subw	a5,a4,a3
    80000e0c:	37fd                	addiw	a5,a5,-1
    80000e0e:	010787bb          	addw	a5,a5,a6
    80000e12:	fef048e3          	bgtz	a5,80000e02 <strncpy+0x24>
  return os;
}
    80000e16:	6422                	ld	s0,8(sp)
    80000e18:	0141                	addi	sp,sp,16
    80000e1a:	8082                	ret

0000000080000e1c <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e1c:	1141                	addi	sp,sp,-16
    80000e1e:	e422                	sd	s0,8(sp)
    80000e20:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e22:	02c05363          	blez	a2,80000e48 <safestrcpy+0x2c>
    80000e26:	fff6069b          	addiw	a3,a2,-1
    80000e2a:	1682                	slli	a3,a3,0x20
    80000e2c:	9281                	srli	a3,a3,0x20
    80000e2e:	96ae                	add	a3,a3,a1
    80000e30:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e32:	00d58963          	beq	a1,a3,80000e44 <safestrcpy+0x28>
    80000e36:	0585                	addi	a1,a1,1
    80000e38:	0785                	addi	a5,a5,1
    80000e3a:	fff5c703          	lbu	a4,-1(a1)
    80000e3e:	fee78fa3          	sb	a4,-1(a5)
    80000e42:	fb65                	bnez	a4,80000e32 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e44:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e48:	6422                	ld	s0,8(sp)
    80000e4a:	0141                	addi	sp,sp,16
    80000e4c:	8082                	ret

0000000080000e4e <strlen>:

int
strlen(const char *s)
{
    80000e4e:	1141                	addi	sp,sp,-16
    80000e50:	e422                	sd	s0,8(sp)
    80000e52:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e54:	00054783          	lbu	a5,0(a0)
    80000e58:	cf91                	beqz	a5,80000e74 <strlen+0x26>
    80000e5a:	0505                	addi	a0,a0,1
    80000e5c:	87aa                	mv	a5,a0
    80000e5e:	4685                	li	a3,1
    80000e60:	9e89                	subw	a3,a3,a0
    80000e62:	00f6853b          	addw	a0,a3,a5
    80000e66:	0785                	addi	a5,a5,1
    80000e68:	fff7c703          	lbu	a4,-1(a5)
    80000e6c:	fb7d                	bnez	a4,80000e62 <strlen+0x14>
    ;
  return n;
}
    80000e6e:	6422                	ld	s0,8(sp)
    80000e70:	0141                	addi	sp,sp,16
    80000e72:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e74:	4501                	li	a0,0
    80000e76:	bfe5                	j	80000e6e <strlen+0x20>

0000000080000e78 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e78:	1141                	addi	sp,sp,-16
    80000e7a:	e406                	sd	ra,8(sp)
    80000e7c:	e022                	sd	s0,0(sp)
    80000e7e:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e80:	00001097          	auipc	ra,0x1
    80000e84:	b00080e7          	jalr	-1280(ra) # 80001980 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e88:	00008717          	auipc	a4,0x8
    80000e8c:	cc070713          	addi	a4,a4,-832 # 80008b48 <started>
  if(cpuid() == 0){
    80000e90:	c139                	beqz	a0,80000ed6 <main+0x5e>
    while(started == 0)
    80000e92:	431c                	lw	a5,0(a4)
    80000e94:	2781                	sext.w	a5,a5
    80000e96:	dff5                	beqz	a5,80000e92 <main+0x1a>
      ;
    __sync_synchronize();
    80000e98:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e9c:	00001097          	auipc	ra,0x1
    80000ea0:	ae4080e7          	jalr	-1308(ra) # 80001980 <cpuid>
    80000ea4:	85aa                	mv	a1,a0
    80000ea6:	00007517          	auipc	a0,0x7
    80000eaa:	21250513          	addi	a0,a0,530 # 800080b8 <digits+0x78>
    80000eae:	fffff097          	auipc	ra,0xfffff
    80000eb2:	6dc080e7          	jalr	1756(ra) # 8000058a <printf>
    kvminithart();    // turn on paging
    80000eb6:	00000097          	auipc	ra,0x0
    80000eba:	0d8080e7          	jalr	216(ra) # 80000f8e <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ebe:	00002097          	auipc	ra,0x2
    80000ec2:	b38080e7          	jalr	-1224(ra) # 800029f6 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec6:	00005097          	auipc	ra,0x5
    80000eca:	38a080e7          	jalr	906(ra) # 80006250 <plicinithart>
  }

  scheduler();        
    80000ece:	00001097          	auipc	ra,0x1
    80000ed2:	0c2080e7          	jalr	194(ra) # 80001f90 <scheduler>
    consoleinit();
    80000ed6:	fffff097          	auipc	ra,0xfffff
    80000eda:	57a080e7          	jalr	1402(ra) # 80000450 <consoleinit>
    printfinit();
    80000ede:	00000097          	auipc	ra,0x0
    80000ee2:	88c080e7          	jalr	-1908(ra) # 8000076a <printfinit>
    printf("\n");
    80000ee6:	00007517          	auipc	a0,0x7
    80000eea:	1e250513          	addi	a0,a0,482 # 800080c8 <digits+0x88>
    80000eee:	fffff097          	auipc	ra,0xfffff
    80000ef2:	69c080e7          	jalr	1692(ra) # 8000058a <printf>
    printf("xv6 kernel is booting\n");
    80000ef6:	00007517          	auipc	a0,0x7
    80000efa:	1aa50513          	addi	a0,a0,426 # 800080a0 <digits+0x60>
    80000efe:	fffff097          	auipc	ra,0xfffff
    80000f02:	68c080e7          	jalr	1676(ra) # 8000058a <printf>
    printf("\n");
    80000f06:	00007517          	auipc	a0,0x7
    80000f0a:	1c250513          	addi	a0,a0,450 # 800080c8 <digits+0x88>
    80000f0e:	fffff097          	auipc	ra,0xfffff
    80000f12:	67c080e7          	jalr	1660(ra) # 8000058a <printf>
    kinit();         // physical page allocator
    80000f16:	00000097          	auipc	ra,0x0
    80000f1a:	b94080e7          	jalr	-1132(ra) # 80000aaa <kinit>
    kvminit();       // create kernel page table
    80000f1e:	00000097          	auipc	ra,0x0
    80000f22:	326080e7          	jalr	806(ra) # 80001244 <kvminit>
    kvminithart();   // turn on paging
    80000f26:	00000097          	auipc	ra,0x0
    80000f2a:	068080e7          	jalr	104(ra) # 80000f8e <kvminithart>
    procinit();      // process table
    80000f2e:	00001097          	auipc	ra,0x1
    80000f32:	99e080e7          	jalr	-1634(ra) # 800018cc <procinit>
    trapinit();      // trap vectors
    80000f36:	00002097          	auipc	ra,0x2
    80000f3a:	a98080e7          	jalr	-1384(ra) # 800029ce <trapinit>
    trapinithart();  // install kernel trap vector
    80000f3e:	00002097          	auipc	ra,0x2
    80000f42:	ab8080e7          	jalr	-1352(ra) # 800029f6 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f46:	00005097          	auipc	ra,0x5
    80000f4a:	2f4080e7          	jalr	756(ra) # 8000623a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f4e:	00005097          	auipc	ra,0x5
    80000f52:	302080e7          	jalr	770(ra) # 80006250 <plicinithart>
    binit();         // buffer cache
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	4a0080e7          	jalr	1184(ra) # 800033f6 <binit>
    iinit();         // inode table
    80000f5e:	00003097          	auipc	ra,0x3
    80000f62:	b40080e7          	jalr	-1216(ra) # 80003a9e <iinit>
    fileinit();      // file table
    80000f66:	00004097          	auipc	ra,0x4
    80000f6a:	ae6080e7          	jalr	-1306(ra) # 80004a4c <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f6e:	00005097          	auipc	ra,0x5
    80000f72:	3ea080e7          	jalr	1002(ra) # 80006358 <virtio_disk_init>
    userinit();      // first user process
    80000f76:	00001097          	auipc	ra,0x1
    80000f7a:	d46080e7          	jalr	-698(ra) # 80001cbc <userinit>
    __sync_synchronize();
    80000f7e:	0ff0000f          	fence
    started = 1;
    80000f82:	4785                	li	a5,1
    80000f84:	00008717          	auipc	a4,0x8
    80000f88:	bcf72223          	sw	a5,-1084(a4) # 80008b48 <started>
    80000f8c:	b789                	j	80000ece <main+0x56>

0000000080000f8e <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f8e:	1141                	addi	sp,sp,-16
    80000f90:	e422                	sd	s0,8(sp)
    80000f92:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000f94:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000f98:	00008797          	auipc	a5,0x8
    80000f9c:	bb87b783          	ld	a5,-1096(a5) # 80008b50 <kernel_pagetable>
    80000fa0:	83b1                	srli	a5,a5,0xc
    80000fa2:	577d                	li	a4,-1
    80000fa4:	177e                	slli	a4,a4,0x3f
    80000fa6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fa8:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000fac:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000fb0:	6422                	ld	s0,8(sp)
    80000fb2:	0141                	addi	sp,sp,16
    80000fb4:	8082                	ret

0000000080000fb6 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fb6:	7139                	addi	sp,sp,-64
    80000fb8:	fc06                	sd	ra,56(sp)
    80000fba:	f822                	sd	s0,48(sp)
    80000fbc:	f426                	sd	s1,40(sp)
    80000fbe:	f04a                	sd	s2,32(sp)
    80000fc0:	ec4e                	sd	s3,24(sp)
    80000fc2:	e852                	sd	s4,16(sp)
    80000fc4:	e456                	sd	s5,8(sp)
    80000fc6:	e05a                	sd	s6,0(sp)
    80000fc8:	0080                	addi	s0,sp,64
    80000fca:	84aa                	mv	s1,a0
    80000fcc:	89ae                	mv	s3,a1
    80000fce:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fd0:	57fd                	li	a5,-1
    80000fd2:	83e9                	srli	a5,a5,0x1a
    80000fd4:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fd6:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fd8:	04b7f263          	bgeu	a5,a1,8000101c <walk+0x66>
    panic("walk");
    80000fdc:	00007517          	auipc	a0,0x7
    80000fe0:	0f450513          	addi	a0,a0,244 # 800080d0 <digits+0x90>
    80000fe4:	fffff097          	auipc	ra,0xfffff
    80000fe8:	55c080e7          	jalr	1372(ra) # 80000540 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fec:	060a8663          	beqz	s5,80001058 <walk+0xa2>
    80000ff0:	00000097          	auipc	ra,0x0
    80000ff4:	af6080e7          	jalr	-1290(ra) # 80000ae6 <kalloc>
    80000ff8:	84aa                	mv	s1,a0
    80000ffa:	c529                	beqz	a0,80001044 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000ffc:	6605                	lui	a2,0x1
    80000ffe:	4581                	li	a1,0
    80001000:	00000097          	auipc	ra,0x0
    80001004:	cd2080e7          	jalr	-814(ra) # 80000cd2 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001008:	00c4d793          	srli	a5,s1,0xc
    8000100c:	07aa                	slli	a5,a5,0xa
    8000100e:	0017e793          	ori	a5,a5,1
    80001012:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001016:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffdc017>
    80001018:	036a0063          	beq	s4,s6,80001038 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000101c:	0149d933          	srl	s2,s3,s4
    80001020:	1ff97913          	andi	s2,s2,511
    80001024:	090e                	slli	s2,s2,0x3
    80001026:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001028:	00093483          	ld	s1,0(s2)
    8000102c:	0014f793          	andi	a5,s1,1
    80001030:	dfd5                	beqz	a5,80000fec <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001032:	80a9                	srli	s1,s1,0xa
    80001034:	04b2                	slli	s1,s1,0xc
    80001036:	b7c5                	j	80001016 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001038:	00c9d513          	srli	a0,s3,0xc
    8000103c:	1ff57513          	andi	a0,a0,511
    80001040:	050e                	slli	a0,a0,0x3
    80001042:	9526                	add	a0,a0,s1
}
    80001044:	70e2                	ld	ra,56(sp)
    80001046:	7442                	ld	s0,48(sp)
    80001048:	74a2                	ld	s1,40(sp)
    8000104a:	7902                	ld	s2,32(sp)
    8000104c:	69e2                	ld	s3,24(sp)
    8000104e:	6a42                	ld	s4,16(sp)
    80001050:	6aa2                	ld	s5,8(sp)
    80001052:	6b02                	ld	s6,0(sp)
    80001054:	6121                	addi	sp,sp,64
    80001056:	8082                	ret
        return 0;
    80001058:	4501                	li	a0,0
    8000105a:	b7ed                	j	80001044 <walk+0x8e>

000000008000105c <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000105c:	57fd                	li	a5,-1
    8000105e:	83e9                	srli	a5,a5,0x1a
    80001060:	00b7f463          	bgeu	a5,a1,80001068 <walkaddr+0xc>
    return 0;
    80001064:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001066:	8082                	ret
{
    80001068:	1141                	addi	sp,sp,-16
    8000106a:	e406                	sd	ra,8(sp)
    8000106c:	e022                	sd	s0,0(sp)
    8000106e:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001070:	4601                	li	a2,0
    80001072:	00000097          	auipc	ra,0x0
    80001076:	f44080e7          	jalr	-188(ra) # 80000fb6 <walk>
  if(pte == 0)
    8000107a:	c105                	beqz	a0,8000109a <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000107c:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000107e:	0117f693          	andi	a3,a5,17
    80001082:	4745                	li	a4,17
    return 0;
    80001084:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001086:	00e68663          	beq	a3,a4,80001092 <walkaddr+0x36>
}
    8000108a:	60a2                	ld	ra,8(sp)
    8000108c:	6402                	ld	s0,0(sp)
    8000108e:	0141                	addi	sp,sp,16
    80001090:	8082                	ret
  pa = PTE2PA(*pte);
    80001092:	83a9                	srli	a5,a5,0xa
    80001094:	00c79513          	slli	a0,a5,0xc
  return pa;
    80001098:	bfcd                	j	8000108a <walkaddr+0x2e>
    return 0;
    8000109a:	4501                	li	a0,0
    8000109c:	b7fd                	j	8000108a <walkaddr+0x2e>

000000008000109e <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000109e:	715d                	addi	sp,sp,-80
    800010a0:	e486                	sd	ra,72(sp)
    800010a2:	e0a2                	sd	s0,64(sp)
    800010a4:	fc26                	sd	s1,56(sp)
    800010a6:	f84a                	sd	s2,48(sp)
    800010a8:	f44e                	sd	s3,40(sp)
    800010aa:	f052                	sd	s4,32(sp)
    800010ac:	ec56                	sd	s5,24(sp)
    800010ae:	e85a                	sd	s6,16(sp)
    800010b0:	e45e                	sd	s7,8(sp)
    800010b2:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010b4:	c639                	beqz	a2,80001102 <mappages+0x64>
    800010b6:	8aaa                	mv	s5,a0
    800010b8:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010ba:	777d                	lui	a4,0xfffff
    800010bc:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010c0:	fff58993          	addi	s3,a1,-1
    800010c4:	99b2                	add	s3,s3,a2
    800010c6:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010ca:	893e                	mv	s2,a5
    800010cc:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010d0:	6b85                	lui	s7,0x1
    800010d2:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010d6:	4605                	li	a2,1
    800010d8:	85ca                	mv	a1,s2
    800010da:	8556                	mv	a0,s5
    800010dc:	00000097          	auipc	ra,0x0
    800010e0:	eda080e7          	jalr	-294(ra) # 80000fb6 <walk>
    800010e4:	cd1d                	beqz	a0,80001122 <mappages+0x84>
    if(*pte & PTE_V)
    800010e6:	611c                	ld	a5,0(a0)
    800010e8:	8b85                	andi	a5,a5,1
    800010ea:	e785                	bnez	a5,80001112 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010ec:	80b1                	srli	s1,s1,0xc
    800010ee:	04aa                	slli	s1,s1,0xa
    800010f0:	0164e4b3          	or	s1,s1,s6
    800010f4:	0014e493          	ori	s1,s1,1
    800010f8:	e104                	sd	s1,0(a0)
    if(a == last)
    800010fa:	05390063          	beq	s2,s3,8000113a <mappages+0x9c>
    a += PGSIZE;
    800010fe:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001100:	bfc9                	j	800010d2 <mappages+0x34>
    panic("mappages: size");
    80001102:	00007517          	auipc	a0,0x7
    80001106:	fd650513          	addi	a0,a0,-42 # 800080d8 <digits+0x98>
    8000110a:	fffff097          	auipc	ra,0xfffff
    8000110e:	436080e7          	jalr	1078(ra) # 80000540 <panic>
      panic("mappages: remap");
    80001112:	00007517          	auipc	a0,0x7
    80001116:	fd650513          	addi	a0,a0,-42 # 800080e8 <digits+0xa8>
    8000111a:	fffff097          	auipc	ra,0xfffff
    8000111e:	426080e7          	jalr	1062(ra) # 80000540 <panic>
      return -1;
    80001122:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001124:	60a6                	ld	ra,72(sp)
    80001126:	6406                	ld	s0,64(sp)
    80001128:	74e2                	ld	s1,56(sp)
    8000112a:	7942                	ld	s2,48(sp)
    8000112c:	79a2                	ld	s3,40(sp)
    8000112e:	7a02                	ld	s4,32(sp)
    80001130:	6ae2                	ld	s5,24(sp)
    80001132:	6b42                	ld	s6,16(sp)
    80001134:	6ba2                	ld	s7,8(sp)
    80001136:	6161                	addi	sp,sp,80
    80001138:	8082                	ret
  return 0;
    8000113a:	4501                	li	a0,0
    8000113c:	b7e5                	j	80001124 <mappages+0x86>

000000008000113e <kvmmap>:
{
    8000113e:	1141                	addi	sp,sp,-16
    80001140:	e406                	sd	ra,8(sp)
    80001142:	e022                	sd	s0,0(sp)
    80001144:	0800                	addi	s0,sp,16
    80001146:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001148:	86b2                	mv	a3,a2
    8000114a:	863e                	mv	a2,a5
    8000114c:	00000097          	auipc	ra,0x0
    80001150:	f52080e7          	jalr	-174(ra) # 8000109e <mappages>
    80001154:	e509                	bnez	a0,8000115e <kvmmap+0x20>
}
    80001156:	60a2                	ld	ra,8(sp)
    80001158:	6402                	ld	s0,0(sp)
    8000115a:	0141                	addi	sp,sp,16
    8000115c:	8082                	ret
    panic("kvmmap");
    8000115e:	00007517          	auipc	a0,0x7
    80001162:	f9a50513          	addi	a0,a0,-102 # 800080f8 <digits+0xb8>
    80001166:	fffff097          	auipc	ra,0xfffff
    8000116a:	3da080e7          	jalr	986(ra) # 80000540 <panic>

000000008000116e <kvmmake>:
{
    8000116e:	1101                	addi	sp,sp,-32
    80001170:	ec06                	sd	ra,24(sp)
    80001172:	e822                	sd	s0,16(sp)
    80001174:	e426                	sd	s1,8(sp)
    80001176:	e04a                	sd	s2,0(sp)
    80001178:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000117a:	00000097          	auipc	ra,0x0
    8000117e:	96c080e7          	jalr	-1684(ra) # 80000ae6 <kalloc>
    80001182:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001184:	6605                	lui	a2,0x1
    80001186:	4581                	li	a1,0
    80001188:	00000097          	auipc	ra,0x0
    8000118c:	b4a080e7          	jalr	-1206(ra) # 80000cd2 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001190:	4719                	li	a4,6
    80001192:	6685                	lui	a3,0x1
    80001194:	10000637          	lui	a2,0x10000
    80001198:	100005b7          	lui	a1,0x10000
    8000119c:	8526                	mv	a0,s1
    8000119e:	00000097          	auipc	ra,0x0
    800011a2:	fa0080e7          	jalr	-96(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011a6:	4719                	li	a4,6
    800011a8:	6685                	lui	a3,0x1
    800011aa:	10001637          	lui	a2,0x10001
    800011ae:	100015b7          	lui	a1,0x10001
    800011b2:	8526                	mv	a0,s1
    800011b4:	00000097          	auipc	ra,0x0
    800011b8:	f8a080e7          	jalr	-118(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011bc:	4719                	li	a4,6
    800011be:	004006b7          	lui	a3,0x400
    800011c2:	0c000637          	lui	a2,0xc000
    800011c6:	0c0005b7          	lui	a1,0xc000
    800011ca:	8526                	mv	a0,s1
    800011cc:	00000097          	auipc	ra,0x0
    800011d0:	f72080e7          	jalr	-142(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011d4:	00007917          	auipc	s2,0x7
    800011d8:	e2c90913          	addi	s2,s2,-468 # 80008000 <etext>
    800011dc:	4729                	li	a4,10
    800011de:	80007697          	auipc	a3,0x80007
    800011e2:	e2268693          	addi	a3,a3,-478 # 8000 <_entry-0x7fff8000>
    800011e6:	4605                	li	a2,1
    800011e8:	067e                	slli	a2,a2,0x1f
    800011ea:	85b2                	mv	a1,a2
    800011ec:	8526                	mv	a0,s1
    800011ee:	00000097          	auipc	ra,0x0
    800011f2:	f50080e7          	jalr	-176(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011f6:	4719                	li	a4,6
    800011f8:	46c5                	li	a3,17
    800011fa:	06ee                	slli	a3,a3,0x1b
    800011fc:	412686b3          	sub	a3,a3,s2
    80001200:	864a                	mv	a2,s2
    80001202:	85ca                	mv	a1,s2
    80001204:	8526                	mv	a0,s1
    80001206:	00000097          	auipc	ra,0x0
    8000120a:	f38080e7          	jalr	-200(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000120e:	4729                	li	a4,10
    80001210:	6685                	lui	a3,0x1
    80001212:	00006617          	auipc	a2,0x6
    80001216:	dee60613          	addi	a2,a2,-530 # 80007000 <_trampoline>
    8000121a:	040005b7          	lui	a1,0x4000
    8000121e:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001220:	05b2                	slli	a1,a1,0xc
    80001222:	8526                	mv	a0,s1
    80001224:	00000097          	auipc	ra,0x0
    80001228:	f1a080e7          	jalr	-230(ra) # 8000113e <kvmmap>
  proc_mapstacks(kpgtbl);
    8000122c:	8526                	mv	a0,s1
    8000122e:	00000097          	auipc	ra,0x0
    80001232:	608080e7          	jalr	1544(ra) # 80001836 <proc_mapstacks>
}
    80001236:	8526                	mv	a0,s1
    80001238:	60e2                	ld	ra,24(sp)
    8000123a:	6442                	ld	s0,16(sp)
    8000123c:	64a2                	ld	s1,8(sp)
    8000123e:	6902                	ld	s2,0(sp)
    80001240:	6105                	addi	sp,sp,32
    80001242:	8082                	ret

0000000080001244 <kvminit>:
{
    80001244:	1141                	addi	sp,sp,-16
    80001246:	e406                	sd	ra,8(sp)
    80001248:	e022                	sd	s0,0(sp)
    8000124a:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000124c:	00000097          	auipc	ra,0x0
    80001250:	f22080e7          	jalr	-222(ra) # 8000116e <kvmmake>
    80001254:	00008797          	auipc	a5,0x8
    80001258:	8ea7be23          	sd	a0,-1796(a5) # 80008b50 <kernel_pagetable>
}
    8000125c:	60a2                	ld	ra,8(sp)
    8000125e:	6402                	ld	s0,0(sp)
    80001260:	0141                	addi	sp,sp,16
    80001262:	8082                	ret

0000000080001264 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001264:	715d                	addi	sp,sp,-80
    80001266:	e486                	sd	ra,72(sp)
    80001268:	e0a2                	sd	s0,64(sp)
    8000126a:	fc26                	sd	s1,56(sp)
    8000126c:	f84a                	sd	s2,48(sp)
    8000126e:	f44e                	sd	s3,40(sp)
    80001270:	f052                	sd	s4,32(sp)
    80001272:	ec56                	sd	s5,24(sp)
    80001274:	e85a                	sd	s6,16(sp)
    80001276:	e45e                	sd	s7,8(sp)
    80001278:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000127a:	03459793          	slli	a5,a1,0x34
    8000127e:	e795                	bnez	a5,800012aa <uvmunmap+0x46>
    80001280:	8a2a                	mv	s4,a0
    80001282:	892e                	mv	s2,a1
    80001284:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001286:	0632                	slli	a2,a2,0xc
    80001288:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000128c:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000128e:	6b05                	lui	s6,0x1
    80001290:	0735e263          	bltu	a1,s3,800012f4 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001294:	60a6                	ld	ra,72(sp)
    80001296:	6406                	ld	s0,64(sp)
    80001298:	74e2                	ld	s1,56(sp)
    8000129a:	7942                	ld	s2,48(sp)
    8000129c:	79a2                	ld	s3,40(sp)
    8000129e:	7a02                	ld	s4,32(sp)
    800012a0:	6ae2                	ld	s5,24(sp)
    800012a2:	6b42                	ld	s6,16(sp)
    800012a4:	6ba2                	ld	s7,8(sp)
    800012a6:	6161                	addi	sp,sp,80
    800012a8:	8082                	ret
    panic("uvmunmap: not aligned");
    800012aa:	00007517          	auipc	a0,0x7
    800012ae:	e5650513          	addi	a0,a0,-426 # 80008100 <digits+0xc0>
    800012b2:	fffff097          	auipc	ra,0xfffff
    800012b6:	28e080e7          	jalr	654(ra) # 80000540 <panic>
      panic("uvmunmap: walk");
    800012ba:	00007517          	auipc	a0,0x7
    800012be:	e5e50513          	addi	a0,a0,-418 # 80008118 <digits+0xd8>
    800012c2:	fffff097          	auipc	ra,0xfffff
    800012c6:	27e080e7          	jalr	638(ra) # 80000540 <panic>
      panic("uvmunmap: not mapped");
    800012ca:	00007517          	auipc	a0,0x7
    800012ce:	e5e50513          	addi	a0,a0,-418 # 80008128 <digits+0xe8>
    800012d2:	fffff097          	auipc	ra,0xfffff
    800012d6:	26e080e7          	jalr	622(ra) # 80000540 <panic>
      panic("uvmunmap: not a leaf");
    800012da:	00007517          	auipc	a0,0x7
    800012de:	e6650513          	addi	a0,a0,-410 # 80008140 <digits+0x100>
    800012e2:	fffff097          	auipc	ra,0xfffff
    800012e6:	25e080e7          	jalr	606(ra) # 80000540 <panic>
    *pte = 0;
    800012ea:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012ee:	995a                	add	s2,s2,s6
    800012f0:	fb3972e3          	bgeu	s2,s3,80001294 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012f4:	4601                	li	a2,0
    800012f6:	85ca                	mv	a1,s2
    800012f8:	8552                	mv	a0,s4
    800012fa:	00000097          	auipc	ra,0x0
    800012fe:	cbc080e7          	jalr	-836(ra) # 80000fb6 <walk>
    80001302:	84aa                	mv	s1,a0
    80001304:	d95d                	beqz	a0,800012ba <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001306:	6108                	ld	a0,0(a0)
    80001308:	00157793          	andi	a5,a0,1
    8000130c:	dfdd                	beqz	a5,800012ca <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000130e:	3ff57793          	andi	a5,a0,1023
    80001312:	fd7784e3          	beq	a5,s7,800012da <uvmunmap+0x76>
    if(do_free){
    80001316:	fc0a8ae3          	beqz	s5,800012ea <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    8000131a:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    8000131c:	0532                	slli	a0,a0,0xc
    8000131e:	fffff097          	auipc	ra,0xfffff
    80001322:	6ca080e7          	jalr	1738(ra) # 800009e8 <kfree>
    80001326:	b7d1                	j	800012ea <uvmunmap+0x86>

0000000080001328 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001328:	1101                	addi	sp,sp,-32
    8000132a:	ec06                	sd	ra,24(sp)
    8000132c:	e822                	sd	s0,16(sp)
    8000132e:	e426                	sd	s1,8(sp)
    80001330:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001332:	fffff097          	auipc	ra,0xfffff
    80001336:	7b4080e7          	jalr	1972(ra) # 80000ae6 <kalloc>
    8000133a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000133c:	c519                	beqz	a0,8000134a <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000133e:	6605                	lui	a2,0x1
    80001340:	4581                	li	a1,0
    80001342:	00000097          	auipc	ra,0x0
    80001346:	990080e7          	jalr	-1648(ra) # 80000cd2 <memset>
  return pagetable;
}
    8000134a:	8526                	mv	a0,s1
    8000134c:	60e2                	ld	ra,24(sp)
    8000134e:	6442                	ld	s0,16(sp)
    80001350:	64a2                	ld	s1,8(sp)
    80001352:	6105                	addi	sp,sp,32
    80001354:	8082                	ret

0000000080001356 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001356:	7179                	addi	sp,sp,-48
    80001358:	f406                	sd	ra,40(sp)
    8000135a:	f022                	sd	s0,32(sp)
    8000135c:	ec26                	sd	s1,24(sp)
    8000135e:	e84a                	sd	s2,16(sp)
    80001360:	e44e                	sd	s3,8(sp)
    80001362:	e052                	sd	s4,0(sp)
    80001364:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001366:	6785                	lui	a5,0x1
    80001368:	04f67863          	bgeu	a2,a5,800013b8 <uvmfirst+0x62>
    8000136c:	8a2a                	mv	s4,a0
    8000136e:	89ae                	mv	s3,a1
    80001370:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    80001372:	fffff097          	auipc	ra,0xfffff
    80001376:	774080e7          	jalr	1908(ra) # 80000ae6 <kalloc>
    8000137a:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000137c:	6605                	lui	a2,0x1
    8000137e:	4581                	li	a1,0
    80001380:	00000097          	auipc	ra,0x0
    80001384:	952080e7          	jalr	-1710(ra) # 80000cd2 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001388:	4779                	li	a4,30
    8000138a:	86ca                	mv	a3,s2
    8000138c:	6605                	lui	a2,0x1
    8000138e:	4581                	li	a1,0
    80001390:	8552                	mv	a0,s4
    80001392:	00000097          	auipc	ra,0x0
    80001396:	d0c080e7          	jalr	-756(ra) # 8000109e <mappages>
  memmove(mem, src, sz);
    8000139a:	8626                	mv	a2,s1
    8000139c:	85ce                	mv	a1,s3
    8000139e:	854a                	mv	a0,s2
    800013a0:	00000097          	auipc	ra,0x0
    800013a4:	98e080e7          	jalr	-1650(ra) # 80000d2e <memmove>
}
    800013a8:	70a2                	ld	ra,40(sp)
    800013aa:	7402                	ld	s0,32(sp)
    800013ac:	64e2                	ld	s1,24(sp)
    800013ae:	6942                	ld	s2,16(sp)
    800013b0:	69a2                	ld	s3,8(sp)
    800013b2:	6a02                	ld	s4,0(sp)
    800013b4:	6145                	addi	sp,sp,48
    800013b6:	8082                	ret
    panic("uvmfirst: more than a page");
    800013b8:	00007517          	auipc	a0,0x7
    800013bc:	da050513          	addi	a0,a0,-608 # 80008158 <digits+0x118>
    800013c0:	fffff097          	auipc	ra,0xfffff
    800013c4:	180080e7          	jalr	384(ra) # 80000540 <panic>

00000000800013c8 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013c8:	1101                	addi	sp,sp,-32
    800013ca:	ec06                	sd	ra,24(sp)
    800013cc:	e822                	sd	s0,16(sp)
    800013ce:	e426                	sd	s1,8(sp)
    800013d0:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013d2:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013d4:	00b67d63          	bgeu	a2,a1,800013ee <uvmdealloc+0x26>
    800013d8:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013da:	6785                	lui	a5,0x1
    800013dc:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800013de:	00f60733          	add	a4,a2,a5
    800013e2:	76fd                	lui	a3,0xfffff
    800013e4:	8f75                	and	a4,a4,a3
    800013e6:	97ae                	add	a5,a5,a1
    800013e8:	8ff5                	and	a5,a5,a3
    800013ea:	00f76863          	bltu	a4,a5,800013fa <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013ee:	8526                	mv	a0,s1
    800013f0:	60e2                	ld	ra,24(sp)
    800013f2:	6442                	ld	s0,16(sp)
    800013f4:	64a2                	ld	s1,8(sp)
    800013f6:	6105                	addi	sp,sp,32
    800013f8:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013fa:	8f99                	sub	a5,a5,a4
    800013fc:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013fe:	4685                	li	a3,1
    80001400:	0007861b          	sext.w	a2,a5
    80001404:	85ba                	mv	a1,a4
    80001406:	00000097          	auipc	ra,0x0
    8000140a:	e5e080e7          	jalr	-418(ra) # 80001264 <uvmunmap>
    8000140e:	b7c5                	j	800013ee <uvmdealloc+0x26>

0000000080001410 <uvmalloc>:
  if(newsz < oldsz)
    80001410:	0ab66563          	bltu	a2,a1,800014ba <uvmalloc+0xaa>
{
    80001414:	7139                	addi	sp,sp,-64
    80001416:	fc06                	sd	ra,56(sp)
    80001418:	f822                	sd	s0,48(sp)
    8000141a:	f426                	sd	s1,40(sp)
    8000141c:	f04a                	sd	s2,32(sp)
    8000141e:	ec4e                	sd	s3,24(sp)
    80001420:	e852                	sd	s4,16(sp)
    80001422:	e456                	sd	s5,8(sp)
    80001424:	e05a                	sd	s6,0(sp)
    80001426:	0080                	addi	s0,sp,64
    80001428:	8aaa                	mv	s5,a0
    8000142a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000142c:	6785                	lui	a5,0x1
    8000142e:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001430:	95be                	add	a1,a1,a5
    80001432:	77fd                	lui	a5,0xfffff
    80001434:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001438:	08c9f363          	bgeu	s3,a2,800014be <uvmalloc+0xae>
    8000143c:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000143e:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    80001442:	fffff097          	auipc	ra,0xfffff
    80001446:	6a4080e7          	jalr	1700(ra) # 80000ae6 <kalloc>
    8000144a:	84aa                	mv	s1,a0
    if(mem == 0){
    8000144c:	c51d                	beqz	a0,8000147a <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    8000144e:	6605                	lui	a2,0x1
    80001450:	4581                	li	a1,0
    80001452:	00000097          	auipc	ra,0x0
    80001456:	880080e7          	jalr	-1920(ra) # 80000cd2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000145a:	875a                	mv	a4,s6
    8000145c:	86a6                	mv	a3,s1
    8000145e:	6605                	lui	a2,0x1
    80001460:	85ca                	mv	a1,s2
    80001462:	8556                	mv	a0,s5
    80001464:	00000097          	auipc	ra,0x0
    80001468:	c3a080e7          	jalr	-966(ra) # 8000109e <mappages>
    8000146c:	e90d                	bnez	a0,8000149e <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000146e:	6785                	lui	a5,0x1
    80001470:	993e                	add	s2,s2,a5
    80001472:	fd4968e3          	bltu	s2,s4,80001442 <uvmalloc+0x32>
  return newsz;
    80001476:	8552                	mv	a0,s4
    80001478:	a809                	j	8000148a <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    8000147a:	864e                	mv	a2,s3
    8000147c:	85ca                	mv	a1,s2
    8000147e:	8556                	mv	a0,s5
    80001480:	00000097          	auipc	ra,0x0
    80001484:	f48080e7          	jalr	-184(ra) # 800013c8 <uvmdealloc>
      return 0;
    80001488:	4501                	li	a0,0
}
    8000148a:	70e2                	ld	ra,56(sp)
    8000148c:	7442                	ld	s0,48(sp)
    8000148e:	74a2                	ld	s1,40(sp)
    80001490:	7902                	ld	s2,32(sp)
    80001492:	69e2                	ld	s3,24(sp)
    80001494:	6a42                	ld	s4,16(sp)
    80001496:	6aa2                	ld	s5,8(sp)
    80001498:	6b02                	ld	s6,0(sp)
    8000149a:	6121                	addi	sp,sp,64
    8000149c:	8082                	ret
      kfree(mem);
    8000149e:	8526                	mv	a0,s1
    800014a0:	fffff097          	auipc	ra,0xfffff
    800014a4:	548080e7          	jalr	1352(ra) # 800009e8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014a8:	864e                	mv	a2,s3
    800014aa:	85ca                	mv	a1,s2
    800014ac:	8556                	mv	a0,s5
    800014ae:	00000097          	auipc	ra,0x0
    800014b2:	f1a080e7          	jalr	-230(ra) # 800013c8 <uvmdealloc>
      return 0;
    800014b6:	4501                	li	a0,0
    800014b8:	bfc9                	j	8000148a <uvmalloc+0x7a>
    return oldsz;
    800014ba:	852e                	mv	a0,a1
}
    800014bc:	8082                	ret
  return newsz;
    800014be:	8532                	mv	a0,a2
    800014c0:	b7e9                	j	8000148a <uvmalloc+0x7a>

00000000800014c2 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014c2:	7179                	addi	sp,sp,-48
    800014c4:	f406                	sd	ra,40(sp)
    800014c6:	f022                	sd	s0,32(sp)
    800014c8:	ec26                	sd	s1,24(sp)
    800014ca:	e84a                	sd	s2,16(sp)
    800014cc:	e44e                	sd	s3,8(sp)
    800014ce:	e052                	sd	s4,0(sp)
    800014d0:	1800                	addi	s0,sp,48
    800014d2:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014d4:	84aa                	mv	s1,a0
    800014d6:	6905                	lui	s2,0x1
    800014d8:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014da:	4985                	li	s3,1
    800014dc:	a829                	j	800014f6 <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014de:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    800014e0:	00c79513          	slli	a0,a5,0xc
    800014e4:	00000097          	auipc	ra,0x0
    800014e8:	fde080e7          	jalr	-34(ra) # 800014c2 <freewalk>
      pagetable[i] = 0;
    800014ec:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014f0:	04a1                	addi	s1,s1,8
    800014f2:	03248163          	beq	s1,s2,80001514 <freewalk+0x52>
    pte_t pte = pagetable[i];
    800014f6:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014f8:	00f7f713          	andi	a4,a5,15
    800014fc:	ff3701e3          	beq	a4,s3,800014de <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001500:	8b85                	andi	a5,a5,1
    80001502:	d7fd                	beqz	a5,800014f0 <freewalk+0x2e>
      panic("freewalk: leaf");
    80001504:	00007517          	auipc	a0,0x7
    80001508:	c7450513          	addi	a0,a0,-908 # 80008178 <digits+0x138>
    8000150c:	fffff097          	auipc	ra,0xfffff
    80001510:	034080e7          	jalr	52(ra) # 80000540 <panic>
    }
  }
  kfree((void*)pagetable);
    80001514:	8552                	mv	a0,s4
    80001516:	fffff097          	auipc	ra,0xfffff
    8000151a:	4d2080e7          	jalr	1234(ra) # 800009e8 <kfree>
}
    8000151e:	70a2                	ld	ra,40(sp)
    80001520:	7402                	ld	s0,32(sp)
    80001522:	64e2                	ld	s1,24(sp)
    80001524:	6942                	ld	s2,16(sp)
    80001526:	69a2                	ld	s3,8(sp)
    80001528:	6a02                	ld	s4,0(sp)
    8000152a:	6145                	addi	sp,sp,48
    8000152c:	8082                	ret

000000008000152e <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000152e:	1101                	addi	sp,sp,-32
    80001530:	ec06                	sd	ra,24(sp)
    80001532:	e822                	sd	s0,16(sp)
    80001534:	e426                	sd	s1,8(sp)
    80001536:	1000                	addi	s0,sp,32
    80001538:	84aa                	mv	s1,a0
  if(sz > 0)
    8000153a:	e999                	bnez	a1,80001550 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000153c:	8526                	mv	a0,s1
    8000153e:	00000097          	auipc	ra,0x0
    80001542:	f84080e7          	jalr	-124(ra) # 800014c2 <freewalk>
}
    80001546:	60e2                	ld	ra,24(sp)
    80001548:	6442                	ld	s0,16(sp)
    8000154a:	64a2                	ld	s1,8(sp)
    8000154c:	6105                	addi	sp,sp,32
    8000154e:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001550:	6785                	lui	a5,0x1
    80001552:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001554:	95be                	add	a1,a1,a5
    80001556:	4685                	li	a3,1
    80001558:	00c5d613          	srli	a2,a1,0xc
    8000155c:	4581                	li	a1,0
    8000155e:	00000097          	auipc	ra,0x0
    80001562:	d06080e7          	jalr	-762(ra) # 80001264 <uvmunmap>
    80001566:	bfd9                	j	8000153c <uvmfree+0xe>

0000000080001568 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001568:	c679                	beqz	a2,80001636 <uvmcopy+0xce>
{
    8000156a:	715d                	addi	sp,sp,-80
    8000156c:	e486                	sd	ra,72(sp)
    8000156e:	e0a2                	sd	s0,64(sp)
    80001570:	fc26                	sd	s1,56(sp)
    80001572:	f84a                	sd	s2,48(sp)
    80001574:	f44e                	sd	s3,40(sp)
    80001576:	f052                	sd	s4,32(sp)
    80001578:	ec56                	sd	s5,24(sp)
    8000157a:	e85a                	sd	s6,16(sp)
    8000157c:	e45e                	sd	s7,8(sp)
    8000157e:	0880                	addi	s0,sp,80
    80001580:	8b2a                	mv	s6,a0
    80001582:	8aae                	mv	s5,a1
    80001584:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001586:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001588:	4601                	li	a2,0
    8000158a:	85ce                	mv	a1,s3
    8000158c:	855a                	mv	a0,s6
    8000158e:	00000097          	auipc	ra,0x0
    80001592:	a28080e7          	jalr	-1496(ra) # 80000fb6 <walk>
    80001596:	c531                	beqz	a0,800015e2 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001598:	6118                	ld	a4,0(a0)
    8000159a:	00177793          	andi	a5,a4,1
    8000159e:	cbb1                	beqz	a5,800015f2 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015a0:	00a75593          	srli	a1,a4,0xa
    800015a4:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015a8:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015ac:	fffff097          	auipc	ra,0xfffff
    800015b0:	53a080e7          	jalr	1338(ra) # 80000ae6 <kalloc>
    800015b4:	892a                	mv	s2,a0
    800015b6:	c939                	beqz	a0,8000160c <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015b8:	6605                	lui	a2,0x1
    800015ba:	85de                	mv	a1,s7
    800015bc:	fffff097          	auipc	ra,0xfffff
    800015c0:	772080e7          	jalr	1906(ra) # 80000d2e <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015c4:	8726                	mv	a4,s1
    800015c6:	86ca                	mv	a3,s2
    800015c8:	6605                	lui	a2,0x1
    800015ca:	85ce                	mv	a1,s3
    800015cc:	8556                	mv	a0,s5
    800015ce:	00000097          	auipc	ra,0x0
    800015d2:	ad0080e7          	jalr	-1328(ra) # 8000109e <mappages>
    800015d6:	e515                	bnez	a0,80001602 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015d8:	6785                	lui	a5,0x1
    800015da:	99be                	add	s3,s3,a5
    800015dc:	fb49e6e3          	bltu	s3,s4,80001588 <uvmcopy+0x20>
    800015e0:	a081                	j	80001620 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015e2:	00007517          	auipc	a0,0x7
    800015e6:	ba650513          	addi	a0,a0,-1114 # 80008188 <digits+0x148>
    800015ea:	fffff097          	auipc	ra,0xfffff
    800015ee:	f56080e7          	jalr	-170(ra) # 80000540 <panic>
      panic("uvmcopy: page not present");
    800015f2:	00007517          	auipc	a0,0x7
    800015f6:	bb650513          	addi	a0,a0,-1098 # 800081a8 <digits+0x168>
    800015fa:	fffff097          	auipc	ra,0xfffff
    800015fe:	f46080e7          	jalr	-186(ra) # 80000540 <panic>
      kfree(mem);
    80001602:	854a                	mv	a0,s2
    80001604:	fffff097          	auipc	ra,0xfffff
    80001608:	3e4080e7          	jalr	996(ra) # 800009e8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000160c:	4685                	li	a3,1
    8000160e:	00c9d613          	srli	a2,s3,0xc
    80001612:	4581                	li	a1,0
    80001614:	8556                	mv	a0,s5
    80001616:	00000097          	auipc	ra,0x0
    8000161a:	c4e080e7          	jalr	-946(ra) # 80001264 <uvmunmap>
  return -1;
    8000161e:	557d                	li	a0,-1
}
    80001620:	60a6                	ld	ra,72(sp)
    80001622:	6406                	ld	s0,64(sp)
    80001624:	74e2                	ld	s1,56(sp)
    80001626:	7942                	ld	s2,48(sp)
    80001628:	79a2                	ld	s3,40(sp)
    8000162a:	7a02                	ld	s4,32(sp)
    8000162c:	6ae2                	ld	s5,24(sp)
    8000162e:	6b42                	ld	s6,16(sp)
    80001630:	6ba2                	ld	s7,8(sp)
    80001632:	6161                	addi	sp,sp,80
    80001634:	8082                	ret
  return 0;
    80001636:	4501                	li	a0,0
}
    80001638:	8082                	ret

000000008000163a <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000163a:	1141                	addi	sp,sp,-16
    8000163c:	e406                	sd	ra,8(sp)
    8000163e:	e022                	sd	s0,0(sp)
    80001640:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001642:	4601                	li	a2,0
    80001644:	00000097          	auipc	ra,0x0
    80001648:	972080e7          	jalr	-1678(ra) # 80000fb6 <walk>
  if(pte == 0)
    8000164c:	c901                	beqz	a0,8000165c <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000164e:	611c                	ld	a5,0(a0)
    80001650:	9bbd                	andi	a5,a5,-17
    80001652:	e11c                	sd	a5,0(a0)
}
    80001654:	60a2                	ld	ra,8(sp)
    80001656:	6402                	ld	s0,0(sp)
    80001658:	0141                	addi	sp,sp,16
    8000165a:	8082                	ret
    panic("uvmclear");
    8000165c:	00007517          	auipc	a0,0x7
    80001660:	b6c50513          	addi	a0,a0,-1172 # 800081c8 <digits+0x188>
    80001664:	fffff097          	auipc	ra,0xfffff
    80001668:	edc080e7          	jalr	-292(ra) # 80000540 <panic>

000000008000166c <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000166c:	c6bd                	beqz	a3,800016da <copyout+0x6e>
{
    8000166e:	715d                	addi	sp,sp,-80
    80001670:	e486                	sd	ra,72(sp)
    80001672:	e0a2                	sd	s0,64(sp)
    80001674:	fc26                	sd	s1,56(sp)
    80001676:	f84a                	sd	s2,48(sp)
    80001678:	f44e                	sd	s3,40(sp)
    8000167a:	f052                	sd	s4,32(sp)
    8000167c:	ec56                	sd	s5,24(sp)
    8000167e:	e85a                	sd	s6,16(sp)
    80001680:	e45e                	sd	s7,8(sp)
    80001682:	e062                	sd	s8,0(sp)
    80001684:	0880                	addi	s0,sp,80
    80001686:	8b2a                	mv	s6,a0
    80001688:	8c2e                	mv	s8,a1
    8000168a:	8a32                	mv	s4,a2
    8000168c:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000168e:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001690:	6a85                	lui	s5,0x1
    80001692:	a015                	j	800016b6 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001694:	9562                	add	a0,a0,s8
    80001696:	0004861b          	sext.w	a2,s1
    8000169a:	85d2                	mv	a1,s4
    8000169c:	41250533          	sub	a0,a0,s2
    800016a0:	fffff097          	auipc	ra,0xfffff
    800016a4:	68e080e7          	jalr	1678(ra) # 80000d2e <memmove>

    len -= n;
    800016a8:	409989b3          	sub	s3,s3,s1
    src += n;
    800016ac:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016ae:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016b2:	02098263          	beqz	s3,800016d6 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016b6:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016ba:	85ca                	mv	a1,s2
    800016bc:	855a                	mv	a0,s6
    800016be:	00000097          	auipc	ra,0x0
    800016c2:	99e080e7          	jalr	-1634(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800016c6:	cd01                	beqz	a0,800016de <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016c8:	418904b3          	sub	s1,s2,s8
    800016cc:	94d6                	add	s1,s1,s5
    800016ce:	fc99f3e3          	bgeu	s3,s1,80001694 <copyout+0x28>
    800016d2:	84ce                	mv	s1,s3
    800016d4:	b7c1                	j	80001694 <copyout+0x28>
  }
  return 0;
    800016d6:	4501                	li	a0,0
    800016d8:	a021                	j	800016e0 <copyout+0x74>
    800016da:	4501                	li	a0,0
}
    800016dc:	8082                	ret
      return -1;
    800016de:	557d                	li	a0,-1
}
    800016e0:	60a6                	ld	ra,72(sp)
    800016e2:	6406                	ld	s0,64(sp)
    800016e4:	74e2                	ld	s1,56(sp)
    800016e6:	7942                	ld	s2,48(sp)
    800016e8:	79a2                	ld	s3,40(sp)
    800016ea:	7a02                	ld	s4,32(sp)
    800016ec:	6ae2                	ld	s5,24(sp)
    800016ee:	6b42                	ld	s6,16(sp)
    800016f0:	6ba2                	ld	s7,8(sp)
    800016f2:	6c02                	ld	s8,0(sp)
    800016f4:	6161                	addi	sp,sp,80
    800016f6:	8082                	ret

00000000800016f8 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016f8:	caa5                	beqz	a3,80001768 <copyin+0x70>
{
    800016fa:	715d                	addi	sp,sp,-80
    800016fc:	e486                	sd	ra,72(sp)
    800016fe:	e0a2                	sd	s0,64(sp)
    80001700:	fc26                	sd	s1,56(sp)
    80001702:	f84a                	sd	s2,48(sp)
    80001704:	f44e                	sd	s3,40(sp)
    80001706:	f052                	sd	s4,32(sp)
    80001708:	ec56                	sd	s5,24(sp)
    8000170a:	e85a                	sd	s6,16(sp)
    8000170c:	e45e                	sd	s7,8(sp)
    8000170e:	e062                	sd	s8,0(sp)
    80001710:	0880                	addi	s0,sp,80
    80001712:	8b2a                	mv	s6,a0
    80001714:	8a2e                	mv	s4,a1
    80001716:	8c32                	mv	s8,a2
    80001718:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    8000171a:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000171c:	6a85                	lui	s5,0x1
    8000171e:	a01d                	j	80001744 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001720:	018505b3          	add	a1,a0,s8
    80001724:	0004861b          	sext.w	a2,s1
    80001728:	412585b3          	sub	a1,a1,s2
    8000172c:	8552                	mv	a0,s4
    8000172e:	fffff097          	auipc	ra,0xfffff
    80001732:	600080e7          	jalr	1536(ra) # 80000d2e <memmove>

    len -= n;
    80001736:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000173a:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000173c:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001740:	02098263          	beqz	s3,80001764 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001744:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001748:	85ca                	mv	a1,s2
    8000174a:	855a                	mv	a0,s6
    8000174c:	00000097          	auipc	ra,0x0
    80001750:	910080e7          	jalr	-1776(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    80001754:	cd01                	beqz	a0,8000176c <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001756:	418904b3          	sub	s1,s2,s8
    8000175a:	94d6                	add	s1,s1,s5
    8000175c:	fc99f2e3          	bgeu	s3,s1,80001720 <copyin+0x28>
    80001760:	84ce                	mv	s1,s3
    80001762:	bf7d                	j	80001720 <copyin+0x28>
  }
  return 0;
    80001764:	4501                	li	a0,0
    80001766:	a021                	j	8000176e <copyin+0x76>
    80001768:	4501                	li	a0,0
}
    8000176a:	8082                	ret
      return -1;
    8000176c:	557d                	li	a0,-1
}
    8000176e:	60a6                	ld	ra,72(sp)
    80001770:	6406                	ld	s0,64(sp)
    80001772:	74e2                	ld	s1,56(sp)
    80001774:	7942                	ld	s2,48(sp)
    80001776:	79a2                	ld	s3,40(sp)
    80001778:	7a02                	ld	s4,32(sp)
    8000177a:	6ae2                	ld	s5,24(sp)
    8000177c:	6b42                	ld	s6,16(sp)
    8000177e:	6ba2                	ld	s7,8(sp)
    80001780:	6c02                	ld	s8,0(sp)
    80001782:	6161                	addi	sp,sp,80
    80001784:	8082                	ret

0000000080001786 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001786:	c2dd                	beqz	a3,8000182c <copyinstr+0xa6>
{
    80001788:	715d                	addi	sp,sp,-80
    8000178a:	e486                	sd	ra,72(sp)
    8000178c:	e0a2                	sd	s0,64(sp)
    8000178e:	fc26                	sd	s1,56(sp)
    80001790:	f84a                	sd	s2,48(sp)
    80001792:	f44e                	sd	s3,40(sp)
    80001794:	f052                	sd	s4,32(sp)
    80001796:	ec56                	sd	s5,24(sp)
    80001798:	e85a                	sd	s6,16(sp)
    8000179a:	e45e                	sd	s7,8(sp)
    8000179c:	0880                	addi	s0,sp,80
    8000179e:	8a2a                	mv	s4,a0
    800017a0:	8b2e                	mv	s6,a1
    800017a2:	8bb2                	mv	s7,a2
    800017a4:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017a6:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017a8:	6985                	lui	s3,0x1
    800017aa:	a02d                	j	800017d4 <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017ac:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017b0:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017b2:	37fd                	addiw	a5,a5,-1
    800017b4:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017b8:	60a6                	ld	ra,72(sp)
    800017ba:	6406                	ld	s0,64(sp)
    800017bc:	74e2                	ld	s1,56(sp)
    800017be:	7942                	ld	s2,48(sp)
    800017c0:	79a2                	ld	s3,40(sp)
    800017c2:	7a02                	ld	s4,32(sp)
    800017c4:	6ae2                	ld	s5,24(sp)
    800017c6:	6b42                	ld	s6,16(sp)
    800017c8:	6ba2                	ld	s7,8(sp)
    800017ca:	6161                	addi	sp,sp,80
    800017cc:	8082                	ret
    srcva = va0 + PGSIZE;
    800017ce:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d2:	c8a9                	beqz	s1,80001824 <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    800017d4:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017d8:	85ca                	mv	a1,s2
    800017da:	8552                	mv	a0,s4
    800017dc:	00000097          	auipc	ra,0x0
    800017e0:	880080e7          	jalr	-1920(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800017e4:	c131                	beqz	a0,80001828 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    800017e6:	417906b3          	sub	a3,s2,s7
    800017ea:	96ce                	add	a3,a3,s3
    800017ec:	00d4f363          	bgeu	s1,a3,800017f2 <copyinstr+0x6c>
    800017f0:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f2:	955e                	add	a0,a0,s7
    800017f4:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017f8:	daf9                	beqz	a3,800017ce <copyinstr+0x48>
    800017fa:	87da                	mv	a5,s6
      if(*p == '\0'){
    800017fc:	41650633          	sub	a2,a0,s6
    80001800:	fff48593          	addi	a1,s1,-1
    80001804:	95da                	add	a1,a1,s6
    while(n > 0){
    80001806:	96da                	add	a3,a3,s6
      if(*p == '\0'){
    80001808:	00f60733          	add	a4,a2,a5
    8000180c:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffdc020>
    80001810:	df51                	beqz	a4,800017ac <copyinstr+0x26>
        *dst = *p;
    80001812:	00e78023          	sb	a4,0(a5)
      --max;
    80001816:	40f584b3          	sub	s1,a1,a5
      dst++;
    8000181a:	0785                	addi	a5,a5,1
    while(n > 0){
    8000181c:	fed796e3          	bne	a5,a3,80001808 <copyinstr+0x82>
      dst++;
    80001820:	8b3e                	mv	s6,a5
    80001822:	b775                	j	800017ce <copyinstr+0x48>
    80001824:	4781                	li	a5,0
    80001826:	b771                	j	800017b2 <copyinstr+0x2c>
      return -1;
    80001828:	557d                	li	a0,-1
    8000182a:	b779                	j	800017b8 <copyinstr+0x32>
  int got_null = 0;
    8000182c:	4781                	li	a5,0
  if(got_null){
    8000182e:	37fd                	addiw	a5,a5,-1
    80001830:	0007851b          	sext.w	a0,a5
}
    80001834:	8082                	ret

0000000080001836 <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    80001836:	7139                	addi	sp,sp,-64
    80001838:	fc06                	sd	ra,56(sp)
    8000183a:	f822                	sd	s0,48(sp)
    8000183c:	f426                	sd	s1,40(sp)
    8000183e:	f04a                	sd	s2,32(sp)
    80001840:	ec4e                	sd	s3,24(sp)
    80001842:	e852                	sd	s4,16(sp)
    80001844:	e456                	sd	s5,8(sp)
    80001846:	e05a                	sd	s6,0(sp)
    80001848:	0080                	addi	s0,sp,64
    8000184a:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    8000184c:	00010497          	auipc	s1,0x10
    80001850:	9b448493          	addi	s1,s1,-1612 # 80011200 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001854:	8b26                	mv	s6,s1
    80001856:	00006a97          	auipc	s5,0x6
    8000185a:	7aaa8a93          	addi	s5,s5,1962 # 80008000 <etext>
    8000185e:	04000937          	lui	s2,0x4000
    80001862:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001864:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001866:	00016a17          	auipc	s4,0x16
    8000186a:	39aa0a13          	addi	s4,s4,922 # 80017c00 <tickslock>
    char *pa = kalloc();
    8000186e:	fffff097          	auipc	ra,0xfffff
    80001872:	278080e7          	jalr	632(ra) # 80000ae6 <kalloc>
    80001876:	862a                	mv	a2,a0
    if(pa == 0)
    80001878:	c131                	beqz	a0,800018bc <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    8000187a:	416485b3          	sub	a1,s1,s6
    8000187e:	858d                	srai	a1,a1,0x3
    80001880:	000ab783          	ld	a5,0(s5)
    80001884:	02f585b3          	mul	a1,a1,a5
    80001888:	2585                	addiw	a1,a1,1
    8000188a:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000188e:	4719                	li	a4,6
    80001890:	6685                	lui	a3,0x1
    80001892:	40b905b3          	sub	a1,s2,a1
    80001896:	854e                	mv	a0,s3
    80001898:	00000097          	auipc	ra,0x0
    8000189c:	8a6080e7          	jalr	-1882(ra) # 8000113e <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018a0:	1a848493          	addi	s1,s1,424
    800018a4:	fd4495e3          	bne	s1,s4,8000186e <proc_mapstacks+0x38>
  }
}
    800018a8:	70e2                	ld	ra,56(sp)
    800018aa:	7442                	ld	s0,48(sp)
    800018ac:	74a2                	ld	s1,40(sp)
    800018ae:	7902                	ld	s2,32(sp)
    800018b0:	69e2                	ld	s3,24(sp)
    800018b2:	6a42                	ld	s4,16(sp)
    800018b4:	6aa2                	ld	s5,8(sp)
    800018b6:	6b02                	ld	s6,0(sp)
    800018b8:	6121                	addi	sp,sp,64
    800018ba:	8082                	ret
      panic("kalloc");
    800018bc:	00007517          	auipc	a0,0x7
    800018c0:	91c50513          	addi	a0,a0,-1764 # 800081d8 <digits+0x198>
    800018c4:	fffff097          	auipc	ra,0xfffff
    800018c8:	c7c080e7          	jalr	-900(ra) # 80000540 <panic>

00000000800018cc <procinit>:

// initialize the proc table.
void
procinit(void)
{
    800018cc:	7139                	addi	sp,sp,-64
    800018ce:	fc06                	sd	ra,56(sp)
    800018d0:	f822                	sd	s0,48(sp)
    800018d2:	f426                	sd	s1,40(sp)
    800018d4:	f04a                	sd	s2,32(sp)
    800018d6:	ec4e                	sd	s3,24(sp)
    800018d8:	e852                	sd	s4,16(sp)
    800018da:	e456                	sd	s5,8(sp)
    800018dc:	e05a                	sd	s6,0(sp)
    800018de:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800018e0:	00007597          	auipc	a1,0x7
    800018e4:	90058593          	addi	a1,a1,-1792 # 800081e0 <digits+0x1a0>
    800018e8:	0000f517          	auipc	a0,0xf
    800018ec:	4e850513          	addi	a0,a0,1256 # 80010dd0 <pid_lock>
    800018f0:	fffff097          	auipc	ra,0xfffff
    800018f4:	256080e7          	jalr	598(ra) # 80000b46 <initlock>
  initlock(&wait_lock, "wait_lock");
    800018f8:	00007597          	auipc	a1,0x7
    800018fc:	8f058593          	addi	a1,a1,-1808 # 800081e8 <digits+0x1a8>
    80001900:	0000f517          	auipc	a0,0xf
    80001904:	4e850513          	addi	a0,a0,1256 # 80010de8 <wait_lock>
    80001908:	fffff097          	auipc	ra,0xfffff
    8000190c:	23e080e7          	jalr	574(ra) # 80000b46 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001910:	00010497          	auipc	s1,0x10
    80001914:	8f048493          	addi	s1,s1,-1808 # 80011200 <proc>
      initlock(&p->lock, "proc");
    80001918:	00007b17          	auipc	s6,0x7
    8000191c:	8e0b0b13          	addi	s6,s6,-1824 # 800081f8 <digits+0x1b8>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    80001920:	8aa6                	mv	s5,s1
    80001922:	00006a17          	auipc	s4,0x6
    80001926:	6dea0a13          	addi	s4,s4,1758 # 80008000 <etext>
    8000192a:	04000937          	lui	s2,0x4000
    8000192e:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001930:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001932:	00016997          	auipc	s3,0x16
    80001936:	2ce98993          	addi	s3,s3,718 # 80017c00 <tickslock>
      initlock(&p->lock, "proc");
    8000193a:	85da                	mv	a1,s6
    8000193c:	8526                	mv	a0,s1
    8000193e:	fffff097          	auipc	ra,0xfffff
    80001942:	208080e7          	jalr	520(ra) # 80000b46 <initlock>
      p->state = UNUSED;
    80001946:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    8000194a:	415487b3          	sub	a5,s1,s5
    8000194e:	878d                	srai	a5,a5,0x3
    80001950:	000a3703          	ld	a4,0(s4)
    80001954:	02e787b3          	mul	a5,a5,a4
    80001958:	2785                	addiw	a5,a5,1
    8000195a:	00d7979b          	slliw	a5,a5,0xd
    8000195e:	40f907b3          	sub	a5,s2,a5
    80001962:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001964:	1a848493          	addi	s1,s1,424
    80001968:	fd3499e3          	bne	s1,s3,8000193a <procinit+0x6e>
  }
}
    8000196c:	70e2                	ld	ra,56(sp)
    8000196e:	7442                	ld	s0,48(sp)
    80001970:	74a2                	ld	s1,40(sp)
    80001972:	7902                	ld	s2,32(sp)
    80001974:	69e2                	ld	s3,24(sp)
    80001976:	6a42                	ld	s4,16(sp)
    80001978:	6aa2                	ld	s5,8(sp)
    8000197a:	6b02                	ld	s6,0(sp)
    8000197c:	6121                	addi	sp,sp,64
    8000197e:	8082                	ret

0000000080001980 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001980:	1141                	addi	sp,sp,-16
    80001982:	e422                	sd	s0,8(sp)
    80001984:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001986:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001988:	2501                	sext.w	a0,a0
    8000198a:	6422                	ld	s0,8(sp)
    8000198c:	0141                	addi	sp,sp,16
    8000198e:	8082                	ret

0000000080001990 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    80001990:	1141                	addi	sp,sp,-16
    80001992:	e422                	sd	s0,8(sp)
    80001994:	0800                	addi	s0,sp,16
    80001996:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001998:	2781                	sext.w	a5,a5
    8000199a:	079e                	slli	a5,a5,0x7
  return c;
}
    8000199c:	0000f517          	auipc	a0,0xf
    800019a0:	46450513          	addi	a0,a0,1124 # 80010e00 <cpus>
    800019a4:	953e                	add	a0,a0,a5
    800019a6:	6422                	ld	s0,8(sp)
    800019a8:	0141                	addi	sp,sp,16
    800019aa:	8082                	ret

00000000800019ac <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    800019ac:	1101                	addi	sp,sp,-32
    800019ae:	ec06                	sd	ra,24(sp)
    800019b0:	e822                	sd	s0,16(sp)
    800019b2:	e426                	sd	s1,8(sp)
    800019b4:	1000                	addi	s0,sp,32
  push_off();
    800019b6:	fffff097          	auipc	ra,0xfffff
    800019ba:	1d4080e7          	jalr	468(ra) # 80000b8a <push_off>
    800019be:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019c0:	2781                	sext.w	a5,a5
    800019c2:	079e                	slli	a5,a5,0x7
    800019c4:	0000f717          	auipc	a4,0xf
    800019c8:	40c70713          	addi	a4,a4,1036 # 80010dd0 <pid_lock>
    800019cc:	97ba                	add	a5,a5,a4
    800019ce:	7b84                	ld	s1,48(a5)
  pop_off();
    800019d0:	fffff097          	auipc	ra,0xfffff
    800019d4:	25a080e7          	jalr	602(ra) # 80000c2a <pop_off>
  return p;
}
    800019d8:	8526                	mv	a0,s1
    800019da:	60e2                	ld	ra,24(sp)
    800019dc:	6442                	ld	s0,16(sp)
    800019de:	64a2                	ld	s1,8(sp)
    800019e0:	6105                	addi	sp,sp,32
    800019e2:	8082                	ret

00000000800019e4 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800019e4:	1141                	addi	sp,sp,-16
    800019e6:	e406                	sd	ra,8(sp)
    800019e8:	e022                	sd	s0,0(sp)
    800019ea:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019ec:	00000097          	auipc	ra,0x0
    800019f0:	fc0080e7          	jalr	-64(ra) # 800019ac <myproc>
    800019f4:	fffff097          	auipc	ra,0xfffff
    800019f8:	296080e7          	jalr	662(ra) # 80000c8a <release>

  if (first) {
    800019fc:	00007797          	auipc	a5,0x7
    80001a00:	0647a783          	lw	a5,100(a5) # 80008a60 <first.1>
    80001a04:	eb89                	bnez	a5,80001a16 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a06:	00001097          	auipc	ra,0x1
    80001a0a:	008080e7          	jalr	8(ra) # 80002a0e <usertrapret>
}
    80001a0e:	60a2                	ld	ra,8(sp)
    80001a10:	6402                	ld	s0,0(sp)
    80001a12:	0141                	addi	sp,sp,16
    80001a14:	8082                	ret
    first = 0;
    80001a16:	00007797          	auipc	a5,0x7
    80001a1a:	0407a523          	sw	zero,74(a5) # 80008a60 <first.1>
    fsinit(ROOTDEV);
    80001a1e:	4505                	li	a0,1
    80001a20:	00002097          	auipc	ra,0x2
    80001a24:	ffe080e7          	jalr	-2(ra) # 80003a1e <fsinit>
    80001a28:	bff9                	j	80001a06 <forkret+0x22>

0000000080001a2a <allocpid>:
{
    80001a2a:	1101                	addi	sp,sp,-32
    80001a2c:	ec06                	sd	ra,24(sp)
    80001a2e:	e822                	sd	s0,16(sp)
    80001a30:	e426                	sd	s1,8(sp)
    80001a32:	e04a                	sd	s2,0(sp)
    80001a34:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a36:	0000f917          	auipc	s2,0xf
    80001a3a:	39a90913          	addi	s2,s2,922 # 80010dd0 <pid_lock>
    80001a3e:	854a                	mv	a0,s2
    80001a40:	fffff097          	auipc	ra,0xfffff
    80001a44:	196080e7          	jalr	406(ra) # 80000bd6 <acquire>
  pid = nextpid;
    80001a48:	00007797          	auipc	a5,0x7
    80001a4c:	01c78793          	addi	a5,a5,28 # 80008a64 <nextpid>
    80001a50:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a52:	0014871b          	addiw	a4,s1,1
    80001a56:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a58:	854a                	mv	a0,s2
    80001a5a:	fffff097          	auipc	ra,0xfffff
    80001a5e:	230080e7          	jalr	560(ra) # 80000c8a <release>
}
    80001a62:	8526                	mv	a0,s1
    80001a64:	60e2                	ld	ra,24(sp)
    80001a66:	6442                	ld	s0,16(sp)
    80001a68:	64a2                	ld	s1,8(sp)
    80001a6a:	6902                	ld	s2,0(sp)
    80001a6c:	6105                	addi	sp,sp,32
    80001a6e:	8082                	ret

0000000080001a70 <proc_pagetable>:
{
    80001a70:	1101                	addi	sp,sp,-32
    80001a72:	ec06                	sd	ra,24(sp)
    80001a74:	e822                	sd	s0,16(sp)
    80001a76:	e426                	sd	s1,8(sp)
    80001a78:	e04a                	sd	s2,0(sp)
    80001a7a:	1000                	addi	s0,sp,32
    80001a7c:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a7e:	00000097          	auipc	ra,0x0
    80001a82:	8aa080e7          	jalr	-1878(ra) # 80001328 <uvmcreate>
    80001a86:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001a88:	c121                	beqz	a0,80001ac8 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a8a:	4729                	li	a4,10
    80001a8c:	00005697          	auipc	a3,0x5
    80001a90:	57468693          	addi	a3,a3,1396 # 80007000 <_trampoline>
    80001a94:	6605                	lui	a2,0x1
    80001a96:	040005b7          	lui	a1,0x4000
    80001a9a:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001a9c:	05b2                	slli	a1,a1,0xc
    80001a9e:	fffff097          	auipc	ra,0xfffff
    80001aa2:	600080e7          	jalr	1536(ra) # 8000109e <mappages>
    80001aa6:	02054863          	bltz	a0,80001ad6 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001aaa:	4719                	li	a4,6
    80001aac:	05893683          	ld	a3,88(s2)
    80001ab0:	6605                	lui	a2,0x1
    80001ab2:	020005b7          	lui	a1,0x2000
    80001ab6:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001ab8:	05b6                	slli	a1,a1,0xd
    80001aba:	8526                	mv	a0,s1
    80001abc:	fffff097          	auipc	ra,0xfffff
    80001ac0:	5e2080e7          	jalr	1506(ra) # 8000109e <mappages>
    80001ac4:	02054163          	bltz	a0,80001ae6 <proc_pagetable+0x76>
}
    80001ac8:	8526                	mv	a0,s1
    80001aca:	60e2                	ld	ra,24(sp)
    80001acc:	6442                	ld	s0,16(sp)
    80001ace:	64a2                	ld	s1,8(sp)
    80001ad0:	6902                	ld	s2,0(sp)
    80001ad2:	6105                	addi	sp,sp,32
    80001ad4:	8082                	ret
    uvmfree(pagetable, 0);
    80001ad6:	4581                	li	a1,0
    80001ad8:	8526                	mv	a0,s1
    80001ada:	00000097          	auipc	ra,0x0
    80001ade:	a54080e7          	jalr	-1452(ra) # 8000152e <uvmfree>
    return 0;
    80001ae2:	4481                	li	s1,0
    80001ae4:	b7d5                	j	80001ac8 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ae6:	4681                	li	a3,0
    80001ae8:	4605                	li	a2,1
    80001aea:	040005b7          	lui	a1,0x4000
    80001aee:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001af0:	05b2                	slli	a1,a1,0xc
    80001af2:	8526                	mv	a0,s1
    80001af4:	fffff097          	auipc	ra,0xfffff
    80001af8:	770080e7          	jalr	1904(ra) # 80001264 <uvmunmap>
    uvmfree(pagetable, 0);
    80001afc:	4581                	li	a1,0
    80001afe:	8526                	mv	a0,s1
    80001b00:	00000097          	auipc	ra,0x0
    80001b04:	a2e080e7          	jalr	-1490(ra) # 8000152e <uvmfree>
    return 0;
    80001b08:	4481                	li	s1,0
    80001b0a:	bf7d                	j	80001ac8 <proc_pagetable+0x58>

0000000080001b0c <proc_freepagetable>:
{
    80001b0c:	1101                	addi	sp,sp,-32
    80001b0e:	ec06                	sd	ra,24(sp)
    80001b10:	e822                	sd	s0,16(sp)
    80001b12:	e426                	sd	s1,8(sp)
    80001b14:	e04a                	sd	s2,0(sp)
    80001b16:	1000                	addi	s0,sp,32
    80001b18:	84aa                	mv	s1,a0
    80001b1a:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b1c:	4681                	li	a3,0
    80001b1e:	4605                	li	a2,1
    80001b20:	040005b7          	lui	a1,0x4000
    80001b24:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b26:	05b2                	slli	a1,a1,0xc
    80001b28:	fffff097          	auipc	ra,0xfffff
    80001b2c:	73c080e7          	jalr	1852(ra) # 80001264 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b30:	4681                	li	a3,0
    80001b32:	4605                	li	a2,1
    80001b34:	020005b7          	lui	a1,0x2000
    80001b38:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b3a:	05b6                	slli	a1,a1,0xd
    80001b3c:	8526                	mv	a0,s1
    80001b3e:	fffff097          	auipc	ra,0xfffff
    80001b42:	726080e7          	jalr	1830(ra) # 80001264 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b46:	85ca                	mv	a1,s2
    80001b48:	8526                	mv	a0,s1
    80001b4a:	00000097          	auipc	ra,0x0
    80001b4e:	9e4080e7          	jalr	-1564(ra) # 8000152e <uvmfree>
}
    80001b52:	60e2                	ld	ra,24(sp)
    80001b54:	6442                	ld	s0,16(sp)
    80001b56:	64a2                	ld	s1,8(sp)
    80001b58:	6902                	ld	s2,0(sp)
    80001b5a:	6105                	addi	sp,sp,32
    80001b5c:	8082                	ret

0000000080001b5e <freeproc>:
{
    80001b5e:	1101                	addi	sp,sp,-32
    80001b60:	ec06                	sd	ra,24(sp)
    80001b62:	e822                	sd	s0,16(sp)
    80001b64:	e426                	sd	s1,8(sp)
    80001b66:	1000                	addi	s0,sp,32
    80001b68:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b6a:	6d28                	ld	a0,88(a0)
    80001b6c:	c509                	beqz	a0,80001b76 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b6e:	fffff097          	auipc	ra,0xfffff
    80001b72:	e7a080e7          	jalr	-390(ra) # 800009e8 <kfree>
  p->trapframe = 0;
    80001b76:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001b7a:	68a8                	ld	a0,80(s1)
    80001b7c:	c511                	beqz	a0,80001b88 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b7e:	64ac                	ld	a1,72(s1)
    80001b80:	00000097          	auipc	ra,0x0
    80001b84:	f8c080e7          	jalr	-116(ra) # 80001b0c <proc_freepagetable>
  p->pagetable = 0;
    80001b88:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b8c:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b90:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b94:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001b98:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001b9c:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001ba0:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001ba4:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001ba8:	0004ac23          	sw	zero,24(s1)
}
    80001bac:	60e2                	ld	ra,24(sp)
    80001bae:	6442                	ld	s0,16(sp)
    80001bb0:	64a2                	ld	s1,8(sp)
    80001bb2:	6105                	addi	sp,sp,32
    80001bb4:	8082                	ret

0000000080001bb6 <allocproc>:
{
    80001bb6:	1101                	addi	sp,sp,-32
    80001bb8:	ec06                	sd	ra,24(sp)
    80001bba:	e822                	sd	s0,16(sp)
    80001bbc:	e426                	sd	s1,8(sp)
    80001bbe:	e04a                	sd	s2,0(sp)
    80001bc0:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bc2:	0000f497          	auipc	s1,0xf
    80001bc6:	63e48493          	addi	s1,s1,1598 # 80011200 <proc>
    80001bca:	00016917          	auipc	s2,0x16
    80001bce:	03690913          	addi	s2,s2,54 # 80017c00 <tickslock>
    acquire(&p->lock);
    80001bd2:	8526                	mv	a0,s1
    80001bd4:	fffff097          	auipc	ra,0xfffff
    80001bd8:	002080e7          	jalr	2(ra) # 80000bd6 <acquire>
    if(p->state == UNUSED) {
    80001bdc:	4c9c                	lw	a5,24(s1)
    80001bde:	cf81                	beqz	a5,80001bf6 <allocproc+0x40>
      release(&p->lock);
    80001be0:	8526                	mv	a0,s1
    80001be2:	fffff097          	auipc	ra,0xfffff
    80001be6:	0a8080e7          	jalr	168(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bea:	1a848493          	addi	s1,s1,424
    80001bee:	ff2492e3          	bne	s1,s2,80001bd2 <allocproc+0x1c>
  return 0;
    80001bf2:	4481                	li	s1,0
    80001bf4:	a069                	j	80001c7e <allocproc+0xc8>
  p->pid = allocpid();
    80001bf6:	00000097          	auipc	ra,0x0
    80001bfa:	e34080e7          	jalr	-460(ra) # 80001a2a <allocpid>
    80001bfe:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c00:	4785                	li	a5,1
    80001c02:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c04:	fffff097          	auipc	ra,0xfffff
    80001c08:	ee2080e7          	jalr	-286(ra) # 80000ae6 <kalloc>
    80001c0c:	892a                	mv	s2,a0
    80001c0e:	eca8                	sd	a0,88(s1)
    80001c10:	cd35                	beqz	a0,80001c8c <allocproc+0xd6>
  p->pagetable = proc_pagetable(p);
    80001c12:	8526                	mv	a0,s1
    80001c14:	00000097          	auipc	ra,0x0
    80001c18:	e5c080e7          	jalr	-420(ra) # 80001a70 <proc_pagetable>
    80001c1c:	892a                	mv	s2,a0
    80001c1e:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c20:	c151                	beqz	a0,80001ca4 <allocproc+0xee>
  memset(&p->context, 0, sizeof(p->context));
    80001c22:	07000613          	li	a2,112
    80001c26:	4581                	li	a1,0
    80001c28:	06048513          	addi	a0,s1,96
    80001c2c:	fffff097          	auipc	ra,0xfffff
    80001c30:	0a6080e7          	jalr	166(ra) # 80000cd2 <memset>
  p->context.ra = (uint64)forkret;
    80001c34:	00000797          	auipc	a5,0x0
    80001c38:	db078793          	addi	a5,a5,-592 # 800019e4 <forkret>
    80001c3c:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c3e:	60bc                	ld	a5,64(s1)
    80001c40:	6705                	lui	a4,0x1
    80001c42:	97ba                	add	a5,a5,a4
    80001c44:	f4bc                	sd	a5,104(s1)
  	  p->rtime = 0;	
    80001c46:	1604ac23          	sw	zero,376(s1)
  p->etime = 0;	
    80001c4a:	1804a023          	sw	zero,384(s1)
  p->ctime = ticks;	
    80001c4e:	00007797          	auipc	a5,0x7
    80001c52:	f127a783          	lw	a5,-238(a5) # 80008b60 <ticks>
    80001c56:	16f4ae23          	sw	a5,380(s1)
  p->mask = 0;	
    80001c5a:	1604a423          	sw	zero,360(s1)
  p->no_of_times_scheduled = 0;	
    80001c5e:	1804a223          	sw	zero,388(s1)
    p->entry_time = ticks;	
    80001c62:	18f4a423          	sw	a5,392(s1)
    p->current_queue = 0;	
    80001c66:	1a04a023          	sw	zero,416(s1)
      p->queue_ticks[i] = 0;	
    80001c6a:	1804a623          	sw	zero,396(s1)
    80001c6e:	1804a823          	sw	zero,400(s1)
    80001c72:	1804aa23          	sw	zero,404(s1)
    80001c76:	1804ac23          	sw	zero,408(s1)
    80001c7a:	1804ae23          	sw	zero,412(s1)
}
    80001c7e:	8526                	mv	a0,s1
    80001c80:	60e2                	ld	ra,24(sp)
    80001c82:	6442                	ld	s0,16(sp)
    80001c84:	64a2                	ld	s1,8(sp)
    80001c86:	6902                	ld	s2,0(sp)
    80001c88:	6105                	addi	sp,sp,32
    80001c8a:	8082                	ret
    freeproc(p);
    80001c8c:	8526                	mv	a0,s1
    80001c8e:	00000097          	auipc	ra,0x0
    80001c92:	ed0080e7          	jalr	-304(ra) # 80001b5e <freeproc>
    release(&p->lock);
    80001c96:	8526                	mv	a0,s1
    80001c98:	fffff097          	auipc	ra,0xfffff
    80001c9c:	ff2080e7          	jalr	-14(ra) # 80000c8a <release>
    return 0;
    80001ca0:	84ca                	mv	s1,s2
    80001ca2:	bff1                	j	80001c7e <allocproc+0xc8>
    freeproc(p);
    80001ca4:	8526                	mv	a0,s1
    80001ca6:	00000097          	auipc	ra,0x0
    80001caa:	eb8080e7          	jalr	-328(ra) # 80001b5e <freeproc>
    release(&p->lock);
    80001cae:	8526                	mv	a0,s1
    80001cb0:	fffff097          	auipc	ra,0xfffff
    80001cb4:	fda080e7          	jalr	-38(ra) # 80000c8a <release>
    return 0;
    80001cb8:	84ca                	mv	s1,s2
    80001cba:	b7d1                	j	80001c7e <allocproc+0xc8>

0000000080001cbc <userinit>:
{
    80001cbc:	1101                	addi	sp,sp,-32
    80001cbe:	ec06                	sd	ra,24(sp)
    80001cc0:	e822                	sd	s0,16(sp)
    80001cc2:	e426                	sd	s1,8(sp)
    80001cc4:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cc6:	00000097          	auipc	ra,0x0
    80001cca:	ef0080e7          	jalr	-272(ra) # 80001bb6 <allocproc>
    80001cce:	84aa                	mv	s1,a0
  initproc = p;
    80001cd0:	00007797          	auipc	a5,0x7
    80001cd4:	e8a7b423          	sd	a0,-376(a5) # 80008b58 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001cd8:	03400613          	li	a2,52
    80001cdc:	00007597          	auipc	a1,0x7
    80001ce0:	d9458593          	addi	a1,a1,-620 # 80008a70 <initcode>
    80001ce4:	6928                	ld	a0,80(a0)
    80001ce6:	fffff097          	auipc	ra,0xfffff
    80001cea:	670080e7          	jalr	1648(ra) # 80001356 <uvmfirst>
  p->sz = PGSIZE;
    80001cee:	6785                	lui	a5,0x1
    80001cf0:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cf2:	6cb8                	ld	a4,88(s1)
    80001cf4:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cf8:	6cb8                	ld	a4,88(s1)
    80001cfa:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cfc:	4641                	li	a2,16
    80001cfe:	00006597          	auipc	a1,0x6
    80001d02:	50258593          	addi	a1,a1,1282 # 80008200 <digits+0x1c0>
    80001d06:	15848513          	addi	a0,s1,344
    80001d0a:	fffff097          	auipc	ra,0xfffff
    80001d0e:	112080e7          	jalr	274(ra) # 80000e1c <safestrcpy>
  p->cwd = namei("/");
    80001d12:	00006517          	auipc	a0,0x6
    80001d16:	4fe50513          	addi	a0,a0,1278 # 80008210 <digits+0x1d0>
    80001d1a:	00002097          	auipc	ra,0x2
    80001d1e:	72e080e7          	jalr	1838(ra) # 80004448 <namei>
    80001d22:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d26:	478d                	li	a5,3
    80001d28:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d2a:	8526                	mv	a0,s1
    80001d2c:	fffff097          	auipc	ra,0xfffff
    80001d30:	f5e080e7          	jalr	-162(ra) # 80000c8a <release>
}
    80001d34:	60e2                	ld	ra,24(sp)
    80001d36:	6442                	ld	s0,16(sp)
    80001d38:	64a2                	ld	s1,8(sp)
    80001d3a:	6105                	addi	sp,sp,32
    80001d3c:	8082                	ret

0000000080001d3e <growproc>:
{
    80001d3e:	1101                	addi	sp,sp,-32
    80001d40:	ec06                	sd	ra,24(sp)
    80001d42:	e822                	sd	s0,16(sp)
    80001d44:	e426                	sd	s1,8(sp)
    80001d46:	e04a                	sd	s2,0(sp)
    80001d48:	1000                	addi	s0,sp,32
    80001d4a:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d4c:	00000097          	auipc	ra,0x0
    80001d50:	c60080e7          	jalr	-928(ra) # 800019ac <myproc>
    80001d54:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d56:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001d58:	01204c63          	bgtz	s2,80001d70 <growproc+0x32>
  } else if(n < 0){
    80001d5c:	02094663          	bltz	s2,80001d88 <growproc+0x4a>
  p->sz = sz;
    80001d60:	e4ac                	sd	a1,72(s1)
  return 0;
    80001d62:	4501                	li	a0,0
}
    80001d64:	60e2                	ld	ra,24(sp)
    80001d66:	6442                	ld	s0,16(sp)
    80001d68:	64a2                	ld	s1,8(sp)
    80001d6a:	6902                	ld	s2,0(sp)
    80001d6c:	6105                	addi	sp,sp,32
    80001d6e:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001d70:	4691                	li	a3,4
    80001d72:	00b90633          	add	a2,s2,a1
    80001d76:	6928                	ld	a0,80(a0)
    80001d78:	fffff097          	auipc	ra,0xfffff
    80001d7c:	698080e7          	jalr	1688(ra) # 80001410 <uvmalloc>
    80001d80:	85aa                	mv	a1,a0
    80001d82:	fd79                	bnez	a0,80001d60 <growproc+0x22>
      return -1;
    80001d84:	557d                	li	a0,-1
    80001d86:	bff9                	j	80001d64 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d88:	00b90633          	add	a2,s2,a1
    80001d8c:	6928                	ld	a0,80(a0)
    80001d8e:	fffff097          	auipc	ra,0xfffff
    80001d92:	63a080e7          	jalr	1594(ra) # 800013c8 <uvmdealloc>
    80001d96:	85aa                	mv	a1,a0
    80001d98:	b7e1                	j	80001d60 <growproc+0x22>

0000000080001d9a <fork>:
{
    80001d9a:	7139                	addi	sp,sp,-64
    80001d9c:	fc06                	sd	ra,56(sp)
    80001d9e:	f822                	sd	s0,48(sp)
    80001da0:	f426                	sd	s1,40(sp)
    80001da2:	f04a                	sd	s2,32(sp)
    80001da4:	ec4e                	sd	s3,24(sp)
    80001da6:	e852                	sd	s4,16(sp)
    80001da8:	e456                	sd	s5,8(sp)
    80001daa:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001dac:	00000097          	auipc	ra,0x0
    80001db0:	c00080e7          	jalr	-1024(ra) # 800019ac <myproc>
    80001db4:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001db6:	00000097          	auipc	ra,0x0
    80001dba:	e00080e7          	jalr	-512(ra) # 80001bb6 <allocproc>
    80001dbe:	12050063          	beqz	a0,80001ede <fork+0x144>
    80001dc2:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001dc4:	048ab603          	ld	a2,72(s5)
    80001dc8:	692c                	ld	a1,80(a0)
    80001dca:	050ab503          	ld	a0,80(s5)
    80001dce:	fffff097          	auipc	ra,0xfffff
    80001dd2:	79a080e7          	jalr	1946(ra) # 80001568 <uvmcopy>
    80001dd6:	04054c63          	bltz	a0,80001e2e <fork+0x94>
  np->sz = p->sz;
    80001dda:	048ab783          	ld	a5,72(s5)
    80001dde:	04f9b423          	sd	a5,72(s3)
  np->mask = p->mask; // strace sys call
    80001de2:	168aa783          	lw	a5,360(s5)
    80001de6:	16f9a423          	sw	a5,360(s3)
  *(np->trapframe) = *(p->trapframe);
    80001dea:	058ab683          	ld	a3,88(s5)
    80001dee:	87b6                	mv	a5,a3
    80001df0:	0589b703          	ld	a4,88(s3)
    80001df4:	12068693          	addi	a3,a3,288
    80001df8:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dfc:	6788                	ld	a0,8(a5)
    80001dfe:	6b8c                	ld	a1,16(a5)
    80001e00:	6f90                	ld	a2,24(a5)
    80001e02:	01073023          	sd	a6,0(a4)
    80001e06:	e708                	sd	a0,8(a4)
    80001e08:	eb0c                	sd	a1,16(a4)
    80001e0a:	ef10                	sd	a2,24(a4)
    80001e0c:	02078793          	addi	a5,a5,32
    80001e10:	02070713          	addi	a4,a4,32
    80001e14:	fed792e3          	bne	a5,a3,80001df8 <fork+0x5e>
  np->trapframe->a0 = 0;
    80001e18:	0589b783          	ld	a5,88(s3)
    80001e1c:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001e20:	0d0a8493          	addi	s1,s5,208
    80001e24:	0d098913          	addi	s2,s3,208
    80001e28:	150a8a13          	addi	s4,s5,336
    80001e2c:	a00d                	j	80001e4e <fork+0xb4>
    freeproc(np);
    80001e2e:	854e                	mv	a0,s3
    80001e30:	00000097          	auipc	ra,0x0
    80001e34:	d2e080e7          	jalr	-722(ra) # 80001b5e <freeproc>
    release(&np->lock);
    80001e38:	854e                	mv	a0,s3
    80001e3a:	fffff097          	auipc	ra,0xfffff
    80001e3e:	e50080e7          	jalr	-432(ra) # 80000c8a <release>
    return -1;
    80001e42:	597d                	li	s2,-1
    80001e44:	a059                	j	80001eca <fork+0x130>
  for(i = 0; i < NOFILE; i++)
    80001e46:	04a1                	addi	s1,s1,8
    80001e48:	0921                	addi	s2,s2,8
    80001e4a:	01448b63          	beq	s1,s4,80001e60 <fork+0xc6>
    if(p->ofile[i])
    80001e4e:	6088                	ld	a0,0(s1)
    80001e50:	d97d                	beqz	a0,80001e46 <fork+0xac>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e52:	00003097          	auipc	ra,0x3
    80001e56:	c8c080e7          	jalr	-884(ra) # 80004ade <filedup>
    80001e5a:	00a93023          	sd	a0,0(s2)
    80001e5e:	b7e5                	j	80001e46 <fork+0xac>
  np->cwd = idup(p->cwd);
    80001e60:	150ab503          	ld	a0,336(s5)
    80001e64:	00002097          	auipc	ra,0x2
    80001e68:	dfa080e7          	jalr	-518(ra) # 80003c5e <idup>
    80001e6c:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e70:	4641                	li	a2,16
    80001e72:	158a8593          	addi	a1,s5,344
    80001e76:	15898513          	addi	a0,s3,344
    80001e7a:	fffff097          	auipc	ra,0xfffff
    80001e7e:	fa2080e7          	jalr	-94(ra) # 80000e1c <safestrcpy>
  pid = np->pid;
    80001e82:	0309a903          	lw	s2,48(s3)
  release(&np->lock);
    80001e86:	854e                	mv	a0,s3
    80001e88:	fffff097          	auipc	ra,0xfffff
    80001e8c:	e02080e7          	jalr	-510(ra) # 80000c8a <release>
  acquire(&wait_lock);
    80001e90:	0000f497          	auipc	s1,0xf
    80001e94:	f5848493          	addi	s1,s1,-168 # 80010de8 <wait_lock>
    80001e98:	8526                	mv	a0,s1
    80001e9a:	fffff097          	auipc	ra,0xfffff
    80001e9e:	d3c080e7          	jalr	-708(ra) # 80000bd6 <acquire>
  np->parent = p;
    80001ea2:	0359bc23          	sd	s5,56(s3)
  release(&wait_lock);
    80001ea6:	8526                	mv	a0,s1
    80001ea8:	fffff097          	auipc	ra,0xfffff
    80001eac:	de2080e7          	jalr	-542(ra) # 80000c8a <release>
  acquire(&np->lock);
    80001eb0:	854e                	mv	a0,s3
    80001eb2:	fffff097          	auipc	ra,0xfffff
    80001eb6:	d24080e7          	jalr	-732(ra) # 80000bd6 <acquire>
  np->state = RUNNABLE;
    80001eba:	478d                	li	a5,3
    80001ebc:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001ec0:	854e                	mv	a0,s3
    80001ec2:	fffff097          	auipc	ra,0xfffff
    80001ec6:	dc8080e7          	jalr	-568(ra) # 80000c8a <release>
}
    80001eca:	854a                	mv	a0,s2
    80001ecc:	70e2                	ld	ra,56(sp)
    80001ece:	7442                	ld	s0,48(sp)
    80001ed0:	74a2                	ld	s1,40(sp)
    80001ed2:	7902                	ld	s2,32(sp)
    80001ed4:	69e2                	ld	s3,24(sp)
    80001ed6:	6a42                	ld	s4,16(sp)
    80001ed8:	6aa2                	ld	s5,8(sp)
    80001eda:	6121                	addi	sp,sp,64
    80001edc:	8082                	ret
    return -1;
    80001ede:	597d                	li	s2,-1
    80001ee0:	b7ed                	j	80001eca <fork+0x130>

0000000080001ee2 <update_time>:
{	
    80001ee2:	7179                	addi	sp,sp,-48
    80001ee4:	f406                	sd	ra,40(sp)
    80001ee6:	f022                	sd	s0,32(sp)
    80001ee8:	ec26                	sd	s1,24(sp)
    80001eea:	e84a                	sd	s2,16(sp)
    80001eec:	e44e                	sd	s3,8(sp)
    80001eee:	1800                	addi	s0,sp,48
  for (p = proc; p < &proc[NPROC]; p++) {	
    80001ef0:	0000f497          	auipc	s1,0xf
    80001ef4:	31048493          	addi	s1,s1,784 # 80011200 <proc>
    if (p->state == RUNNING) {	
    80001ef8:	4991                	li	s3,4
  for (p = proc; p < &proc[NPROC]; p++) {	
    80001efa:	00016917          	auipc	s2,0x16
    80001efe:	d0690913          	addi	s2,s2,-762 # 80017c00 <tickslock>
    80001f02:	a811                	j	80001f16 <update_time+0x34>
    release(&p->lock); 	
    80001f04:	8526                	mv	a0,s1
    80001f06:	fffff097          	auipc	ra,0xfffff
    80001f0a:	d84080e7          	jalr	-636(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++) {	
    80001f0e:	1a848493          	addi	s1,s1,424
    80001f12:	03248063          	beq	s1,s2,80001f32 <update_time+0x50>
    acquire(&p->lock);	
    80001f16:	8526                	mv	a0,s1
    80001f18:	fffff097          	auipc	ra,0xfffff
    80001f1c:	cbe080e7          	jalr	-834(ra) # 80000bd6 <acquire>
    if (p->state == RUNNING) {	
    80001f20:	4c9c                	lw	a5,24(s1)
    80001f22:	ff3791e3          	bne	a5,s3,80001f04 <update_time+0x22>
      p->rtime++;	
    80001f26:	1784a783          	lw	a5,376(s1)
    80001f2a:	2785                	addiw	a5,a5,1
    80001f2c:	16f4ac23          	sw	a5,376(s1)
    80001f30:	bfd1                	j	80001f04 <update_time+0x22>
}	
    80001f32:	70a2                	ld	ra,40(sp)
    80001f34:	7402                	ld	s0,32(sp)
    80001f36:	64e2                	ld	s1,24(sp)
    80001f38:	6942                	ld	s2,16(sp)
    80001f3a:	69a2                	ld	s3,8(sp)
    80001f3c:	6145                	addi	sp,sp,48
    80001f3e:	8082                	ret

0000000080001f40 <trace>:
{	
    80001f40:	1101                	addi	sp,sp,-32
    80001f42:	ec06                	sd	ra,24(sp)
    80001f44:	e822                	sd	s0,16(sp)
    80001f46:	e426                	sd	s1,8(sp)
    80001f48:	e04a                	sd	s2,0(sp)
    80001f4a:	1000                	addi	s0,sp,32
    80001f4c:	892a                	mv	s2,a0
  struct proc *p = myproc();	
    80001f4e:	00000097          	auipc	ra,0x0
    80001f52:	a5e080e7          	jalr	-1442(ra) # 800019ac <myproc>
    80001f56:	84aa                	mv	s1,a0
  acquire(&p->lock);	
    80001f58:	fffff097          	auipc	ra,0xfffff
    80001f5c:	c7e080e7          	jalr	-898(ra) # 80000bd6 <acquire>
  p->mask = mask;	
    80001f60:	1724a423          	sw	s2,360(s1)
  release(&p->lock);	
    80001f64:	8526                	mv	a0,s1
    80001f66:	fffff097          	auipc	ra,0xfffff
    80001f6a:	d24080e7          	jalr	-732(ra) # 80000c8a <release>
}	
    80001f6e:	60e2                	ld	ra,24(sp)
    80001f70:	6442                	ld	s0,16(sp)
    80001f72:	64a2                	ld	s1,8(sp)
    80001f74:	6902                	ld	s2,0(sp)
    80001f76:	6105                	addi	sp,sp,32
    80001f78:	8082                	ret

0000000080001f7a <set_priority>:
{	
    80001f7a:	1141                	addi	sp,sp,-16
    80001f7c:	e422                	sd	s0,8(sp)
    80001f7e:	0800                	addi	s0,sp,16
    80001f80:	04000793          	li	a5,64
  for (p = proc; p < &proc[NPROC]; p++) {	
    80001f84:	17fd                	addi	a5,a5,-1
    80001f86:	fffd                	bnez	a5,80001f84 <set_priority+0xa>
}
    80001f88:	557d                	li	a0,-1
    80001f8a:	6422                	ld	s0,8(sp)
    80001f8c:	0141                	addi	sp,sp,16
    80001f8e:	8082                	ret

0000000080001f90 <scheduler>:
{
    80001f90:	715d                	addi	sp,sp,-80
    80001f92:	e486                	sd	ra,72(sp)
    80001f94:	e0a2                	sd	s0,64(sp)
    80001f96:	fc26                	sd	s1,56(sp)
    80001f98:	f84a                	sd	s2,48(sp)
    80001f9a:	f44e                	sd	s3,40(sp)
    80001f9c:	f052                	sd	s4,32(sp)
    80001f9e:	ec56                	sd	s5,24(sp)
    80001fa0:	e85a                	sd	s6,16(sp)
    80001fa2:	e45e                	sd	s7,8(sp)
    80001fa4:	e062                	sd	s8,0(sp)
    80001fa6:	0880                	addi	s0,sp,80
    80001fa8:	8792                	mv	a5,tp
  int id = r_tp();
    80001faa:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001fac:	00779693          	slli	a3,a5,0x7
    80001fb0:	0000f717          	auipc	a4,0xf
    80001fb4:	e2070713          	addi	a4,a4,-480 # 80010dd0 <pid_lock>
    80001fb8:	9736                	add	a4,a4,a3
    80001fba:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &chosenProc->context);	
    80001fbe:	0000f717          	auipc	a4,0xf
    80001fc2:	e4a70713          	addi	a4,a4,-438 # 80010e08 <cpus+0x8>
    80001fc6:	00e68c33          	add	s8,a3,a4
        if ((ticks - p->entry_time > WAITING_LIMIT) && p->current_queue > 0) {	
    80001fca:	00007a17          	auipc	s4,0x7
    80001fce:	b96a0a13          	addi	s4,s4,-1130 # 80008b60 <ticks>
    for (p = proc; p < &proc[NPROC]; p++) {	
    80001fd2:	00016997          	auipc	s3,0x16
    80001fd6:	c2e98993          	addi	s3,s3,-978 # 80017c00 <tickslock>
        c->proc = chosenProc;	
    80001fda:	0000fb97          	auipc	s7,0xf
    80001fde:	df6b8b93          	addi	s7,s7,-522 # 80010dd0 <pid_lock>
    80001fe2:	9bb6                	add	s7,s7,a3
    80001fe4:	aa35                	j	80002120 <scheduler+0x190>
    for (p = proc; p < &proc[NPROC]; p++) {	
    80001fe6:	1a848493          	addi	s1,s1,424
    80001fea:	07348063          	beq	s1,s3,8000204a <scheduler+0xba>
      if (p->state == RUNNABLE) {	
    80001fee:	4c9c                	lw	a5,24(s1)
    80001ff0:	ff279be3          	bne	a5,s2,80001fe6 <scheduler+0x56>
        if ((ticks - p->entry_time > WAITING_LIMIT) && p->current_queue > 0) {	
    80001ff4:	000a2783          	lw	a5,0(s4)
    80001ff8:	1884a703          	lw	a4,392(s1)
    80001ffc:	9f99                	subw	a5,a5,a4
    80001ffe:	fefaf4e3          	bgeu	s5,a5,80001fe6 <scheduler+0x56>
    80002002:	1a04a783          	lw	a5,416(s1)
    80002006:	d3e5                	beqz	a5,80001fe6 <scheduler+0x56>
          acquire(&p->lock);	
    80002008:	8526                	mv	a0,s1
    8000200a:	fffff097          	auipc	ra,0xfffff
    8000200e:	bcc080e7          	jalr	-1076(ra) # 80000bd6 <acquire>
          p->queue_ticks[p->current_queue] += (ticks - p->entry_time);	
    80002012:	1a04a703          	lw	a4,416(s1)
    80002016:	02071793          	slli	a5,a4,0x20
    8000201a:	01e7d693          	srli	a3,a5,0x1e
    8000201e:	96a6                	add	a3,a3,s1
    80002020:	000a2603          	lw	a2,0(s4)
    80002024:	18c6a783          	lw	a5,396(a3)
    80002028:	1884a583          	lw	a1,392(s1)
    8000202c:	9f8d                	subw	a5,a5,a1
    8000202e:	9fb1                	addw	a5,a5,a2
    80002030:	18f6a623          	sw	a5,396(a3)
          p->current_queue--;	
    80002034:	377d                	addiw	a4,a4,-1
    80002036:	1ae4a023          	sw	a4,416(s1)
          p->entry_time = ticks;	
    8000203a:	18c4a423          	sw	a2,392(s1)
          release(&p->lock);	
    8000203e:	8526                	mv	a0,s1
    80002040:	fffff097          	auipc	ra,0xfffff
    80002044:	c4a080e7          	jalr	-950(ra) # 80000c8a <release>
    80002048:	bf79                	j	80001fe6 <scheduler+0x56>
    8000204a:	0000f797          	auipc	a5,0xf
    8000204e:	35e78793          	addi	a5,a5,862 # 800113a8 <proc+0x1a8>
    int highest_queue = 5;	
    80002052:	855a                	mv	a0,s6
    struct proc *chosenProc = 0;	
    80002054:	4481                	li	s1,0
    80002056:	a839                	j	80002074 <scheduler+0xe4>
        if (chosenProc == 0) {	
    80002058:	c0b9                	beqz	s1,8000209e <scheduler+0x10e>
        else if (p->current_queue < highest_queue) {	
    8000205a:	ff87a683          	lw	a3,-8(a5)
    8000205e:	0005059b          	sext.w	a1,a0
    80002062:	04b6f263          	bgeu	a3,a1,800020a6 <scheduler+0x116>
          highest_queue = chosenProc->current_queue;	
    80002066:	0006851b          	sext.w	a0,a3
    8000206a:	84b2                	mv	s1,a2
    for (p = proc; p < &proc[NPROC]; p++) {	
    8000206c:	05377763          	bgeu	a4,s3,800020ba <scheduler+0x12a>
    80002070:	1a878793          	addi	a5,a5,424
    80002074:	e5878613          	addi	a2,a5,-424
      if (p->state == RUNNABLE) {	
    80002078:	873e                	mv	a4,a5
    8000207a:	e707a683          	lw	a3,-400(a5)
    8000207e:	fd268de3          	beq	a3,s2,80002058 <scheduler+0xc8>
    for (p = proc; p < &proc[NPROC]; p++) {	
    80002082:	ff37e7e3          	bltu	a5,s3,80002070 <scheduler+0xe0>
    if (chosenProc != 0) {	
    80002086:	e895                	bnez	s1,800020ba <scheduler+0x12a>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002088:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000208c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002090:	10079073          	csrw	sstatus,a5
    for (p = proc; p < &proc[NPROC]; p++) {	
    80002094:	0000f497          	auipc	s1,0xf
    80002098:	16c48493          	addi	s1,s1,364 # 80011200 <proc>
    8000209c:	bf89                	j	80001fee <scheduler+0x5e>
          highest_queue = chosenProc->current_queue;	
    8000209e:	ff87a503          	lw	a0,-8(a5)
    800020a2:	84b2                	mv	s1,a2
    800020a4:	b7e1                	j	8000206c <scheduler+0xdc>
        else if (p->current_queue == highest_queue && p->entry_time < chosenProc->entry_time) {	
    800020a6:	fcb693e3          	bne	a3,a1,8000206c <scheduler+0xdc>
    800020aa:	fe07a583          	lw	a1,-32(a5)
    800020ae:	1884a683          	lw	a3,392(s1)
    800020b2:	fad5fde3          	bgeu	a1,a3,8000206c <scheduler+0xdc>
    800020b6:	84b2                	mv	s1,a2
    800020b8:	bf55                	j	8000206c <scheduler+0xdc>
      acquire(&chosenProc->lock);	
    800020ba:	8926                	mv	s2,s1
    800020bc:	8526                	mv	a0,s1
    800020be:	fffff097          	auipc	ra,0xfffff
    800020c2:	b18080e7          	jalr	-1256(ra) # 80000bd6 <acquire>
      if (chosenProc->state == RUNNABLE) {	
    800020c6:	4c98                	lw	a4,24(s1)
    800020c8:	478d                	li	a5,3
    800020ca:	04f71663          	bne	a4,a5,80002116 <scheduler+0x186>
        chosenProc->no_of_times_scheduled++;	
    800020ce:	1844a783          	lw	a5,388(s1)
    800020d2:	2785                	addiw	a5,a5,1
    800020d4:	18f4a223          	sw	a5,388(s1)
        chosenProc->entry_time = ticks;	
    800020d8:	000a2783          	lw	a5,0(s4)
    800020dc:	18f4a423          	sw	a5,392(s1)
        chosenProc->state = RUNNING;	
    800020e0:	4791                	li	a5,4
    800020e2:	cc9c                	sw	a5,24(s1)
        c->proc = chosenProc;	
    800020e4:	029bb823          	sd	s1,48(s7)
        swtch(&c->context, &chosenProc->context);	
    800020e8:	06048593          	addi	a1,s1,96
    800020ec:	8562                	mv	a0,s8
    800020ee:	00001097          	auipc	ra,0x1
    800020f2:	876080e7          	jalr	-1930(ra) # 80002964 <swtch>
        c->proc = 0;	
    800020f6:	020bb823          	sd	zero,48(s7)
        chosenProc->queue_ticks[chosenProc->current_queue] += (ticks - chosenProc->entry_time);	
    800020fa:	1a04e783          	lwu	a5,416(s1)
    800020fe:	078a                	slli	a5,a5,0x2
    80002100:	97a6                	add	a5,a5,s1
    80002102:	18c7a703          	lw	a4,396(a5)
    80002106:	1884a683          	lw	a3,392(s1)
    8000210a:	9f15                	subw	a4,a4,a3
    8000210c:	000a2683          	lw	a3,0(s4)
    80002110:	9f35                	addw	a4,a4,a3
    80002112:	18e7a623          	sw	a4,396(a5)
      release(&chosenProc->lock);	
    80002116:	854a                	mv	a0,s2
    80002118:	fffff097          	auipc	ra,0xfffff
    8000211c:	b72080e7          	jalr	-1166(ra) # 80000c8a <release>
      if (p->state == RUNNABLE) {	
    80002120:	490d                	li	s2,3
        if ((ticks - p->entry_time > WAITING_LIMIT) && p->current_queue > 0) {	
    80002122:	4ac1                	li	s5,16
    int highest_queue = 5;	
    80002124:	4b15                	li	s6,5
    80002126:	b78d                	j	80002088 <scheduler+0xf8>

0000000080002128 <sched>:
{
    80002128:	7179                	addi	sp,sp,-48
    8000212a:	f406                	sd	ra,40(sp)
    8000212c:	f022                	sd	s0,32(sp)
    8000212e:	ec26                	sd	s1,24(sp)
    80002130:	e84a                	sd	s2,16(sp)
    80002132:	e44e                	sd	s3,8(sp)
    80002134:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002136:	00000097          	auipc	ra,0x0
    8000213a:	876080e7          	jalr	-1930(ra) # 800019ac <myproc>
    8000213e:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002140:	fffff097          	auipc	ra,0xfffff
    80002144:	a1c080e7          	jalr	-1508(ra) # 80000b5c <holding>
    80002148:	c93d                	beqz	a0,800021be <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000214a:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    8000214c:	2781                	sext.w	a5,a5
    8000214e:	079e                	slli	a5,a5,0x7
    80002150:	0000f717          	auipc	a4,0xf
    80002154:	c8070713          	addi	a4,a4,-896 # 80010dd0 <pid_lock>
    80002158:	97ba                	add	a5,a5,a4
    8000215a:	0a87a703          	lw	a4,168(a5)
    8000215e:	4785                	li	a5,1
    80002160:	06f71763          	bne	a4,a5,800021ce <sched+0xa6>
  if(p->state == RUNNING)
    80002164:	4c98                	lw	a4,24(s1)
    80002166:	4791                	li	a5,4
    80002168:	06f70b63          	beq	a4,a5,800021de <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000216c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002170:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002172:	efb5                	bnez	a5,800021ee <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002174:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002176:	0000f917          	auipc	s2,0xf
    8000217a:	c5a90913          	addi	s2,s2,-934 # 80010dd0 <pid_lock>
    8000217e:	2781                	sext.w	a5,a5
    80002180:	079e                	slli	a5,a5,0x7
    80002182:	97ca                	add	a5,a5,s2
    80002184:	0ac7a983          	lw	s3,172(a5)
    80002188:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000218a:	2781                	sext.w	a5,a5
    8000218c:	079e                	slli	a5,a5,0x7
    8000218e:	0000f597          	auipc	a1,0xf
    80002192:	c7a58593          	addi	a1,a1,-902 # 80010e08 <cpus+0x8>
    80002196:	95be                	add	a1,a1,a5
    80002198:	06048513          	addi	a0,s1,96
    8000219c:	00000097          	auipc	ra,0x0
    800021a0:	7c8080e7          	jalr	1992(ra) # 80002964 <swtch>
    800021a4:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800021a6:	2781                	sext.w	a5,a5
    800021a8:	079e                	slli	a5,a5,0x7
    800021aa:	993e                	add	s2,s2,a5
    800021ac:	0b392623          	sw	s3,172(s2)
}
    800021b0:	70a2                	ld	ra,40(sp)
    800021b2:	7402                	ld	s0,32(sp)
    800021b4:	64e2                	ld	s1,24(sp)
    800021b6:	6942                	ld	s2,16(sp)
    800021b8:	69a2                	ld	s3,8(sp)
    800021ba:	6145                	addi	sp,sp,48
    800021bc:	8082                	ret
    panic("sched p->lock");
    800021be:	00006517          	auipc	a0,0x6
    800021c2:	05a50513          	addi	a0,a0,90 # 80008218 <digits+0x1d8>
    800021c6:	ffffe097          	auipc	ra,0xffffe
    800021ca:	37a080e7          	jalr	890(ra) # 80000540 <panic>
    panic("sched locks");
    800021ce:	00006517          	auipc	a0,0x6
    800021d2:	05a50513          	addi	a0,a0,90 # 80008228 <digits+0x1e8>
    800021d6:	ffffe097          	auipc	ra,0xffffe
    800021da:	36a080e7          	jalr	874(ra) # 80000540 <panic>
    panic("sched running");
    800021de:	00006517          	auipc	a0,0x6
    800021e2:	05a50513          	addi	a0,a0,90 # 80008238 <digits+0x1f8>
    800021e6:	ffffe097          	auipc	ra,0xffffe
    800021ea:	35a080e7          	jalr	858(ra) # 80000540 <panic>
    panic("sched interruptible");
    800021ee:	00006517          	auipc	a0,0x6
    800021f2:	05a50513          	addi	a0,a0,90 # 80008248 <digits+0x208>
    800021f6:	ffffe097          	auipc	ra,0xffffe
    800021fa:	34a080e7          	jalr	842(ra) # 80000540 <panic>

00000000800021fe <yield>:
{
    800021fe:	1101                	addi	sp,sp,-32
    80002200:	ec06                	sd	ra,24(sp)
    80002202:	e822                	sd	s0,16(sp)
    80002204:	e426                	sd	s1,8(sp)
    80002206:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002208:	fffff097          	auipc	ra,0xfffff
    8000220c:	7a4080e7          	jalr	1956(ra) # 800019ac <myproc>
    80002210:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002212:	fffff097          	auipc	ra,0xfffff
    80002216:	9c4080e7          	jalr	-1596(ra) # 80000bd6 <acquire>
  p->state = RUNNABLE;
    8000221a:	478d                	li	a5,3
    8000221c:	cc9c                	sw	a5,24(s1)
  sched();
    8000221e:	00000097          	auipc	ra,0x0
    80002222:	f0a080e7          	jalr	-246(ra) # 80002128 <sched>
  release(&p->lock);
    80002226:	8526                	mv	a0,s1
    80002228:	fffff097          	auipc	ra,0xfffff
    8000222c:	a62080e7          	jalr	-1438(ra) # 80000c8a <release>
}
    80002230:	60e2                	ld	ra,24(sp)
    80002232:	6442                	ld	s0,16(sp)
    80002234:	64a2                	ld	s1,8(sp)
    80002236:	6105                	addi	sp,sp,32
    80002238:	8082                	ret

000000008000223a <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    8000223a:	7179                	addi	sp,sp,-48
    8000223c:	f406                	sd	ra,40(sp)
    8000223e:	f022                	sd	s0,32(sp)
    80002240:	ec26                	sd	s1,24(sp)
    80002242:	e84a                	sd	s2,16(sp)
    80002244:	e44e                	sd	s3,8(sp)
    80002246:	1800                	addi	s0,sp,48
    80002248:	89aa                	mv	s3,a0
    8000224a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000224c:	fffff097          	auipc	ra,0xfffff
    80002250:	760080e7          	jalr	1888(ra) # 800019ac <myproc>
    80002254:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002256:	fffff097          	auipc	ra,0xfffff
    8000225a:	980080e7          	jalr	-1664(ra) # 80000bd6 <acquire>
  release(lk);
    8000225e:	854a                	mv	a0,s2
    80002260:	fffff097          	auipc	ra,0xfffff
    80002264:	a2a080e7          	jalr	-1494(ra) # 80000c8a <release>

  // Go to sleep.
  p->chan = chan;
    80002268:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    8000226c:	4789                	li	a5,2
    8000226e:	cc9c                	sw	a5,24(s1)
  	  #ifdef PBS	
    p->s_start_time = ticks;	
  #endif

  sched();
    80002270:	00000097          	auipc	ra,0x0
    80002274:	eb8080e7          	jalr	-328(ra) # 80002128 <sched>

  // Tidy up.
  p->chan = 0;
    80002278:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    8000227c:	8526                	mv	a0,s1
    8000227e:	fffff097          	auipc	ra,0xfffff
    80002282:	a0c080e7          	jalr	-1524(ra) # 80000c8a <release>
  acquire(lk);
    80002286:	854a                	mv	a0,s2
    80002288:	fffff097          	auipc	ra,0xfffff
    8000228c:	94e080e7          	jalr	-1714(ra) # 80000bd6 <acquire>
}
    80002290:	70a2                	ld	ra,40(sp)
    80002292:	7402                	ld	s0,32(sp)
    80002294:	64e2                	ld	s1,24(sp)
    80002296:	6942                	ld	s2,16(sp)
    80002298:	69a2                	ld	s3,8(sp)
    8000229a:	6145                	addi	sp,sp,48
    8000229c:	8082                	ret

000000008000229e <waitx>:
{	
    8000229e:	711d                	addi	sp,sp,-96
    800022a0:	ec86                	sd	ra,88(sp)
    800022a2:	e8a2                	sd	s0,80(sp)
    800022a4:	e4a6                	sd	s1,72(sp)
    800022a6:	e0ca                	sd	s2,64(sp)
    800022a8:	fc4e                	sd	s3,56(sp)
    800022aa:	f852                	sd	s4,48(sp)
    800022ac:	f456                	sd	s5,40(sp)
    800022ae:	f05a                	sd	s6,32(sp)
    800022b0:	ec5e                	sd	s7,24(sp)
    800022b2:	e862                	sd	s8,16(sp)
    800022b4:	e466                	sd	s9,8(sp)
    800022b6:	e06a                	sd	s10,0(sp)
    800022b8:	1080                	addi	s0,sp,96
    800022ba:	8b2a                	mv	s6,a0
    800022bc:	8c2e                	mv	s8,a1
    800022be:	8bb2                	mv	s7,a2
  struct proc *p = myproc();	
    800022c0:	fffff097          	auipc	ra,0xfffff
    800022c4:	6ec080e7          	jalr	1772(ra) # 800019ac <myproc>
    800022c8:	892a                	mv	s2,a0
  acquire(&wait_lock);	
    800022ca:	0000f517          	auipc	a0,0xf
    800022ce:	b1e50513          	addi	a0,a0,-1250 # 80010de8 <wait_lock>
    800022d2:	fffff097          	auipc	ra,0xfffff
    800022d6:	904080e7          	jalr	-1788(ra) # 80000bd6 <acquire>
    havekids = 0;	
    800022da:	4c81                	li	s9,0
        if(np->state == ZOMBIE){	
    800022dc:	4a15                	li	s4,5
        havekids = 1;	
    800022de:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){	
    800022e0:	00016997          	auipc	s3,0x16
    800022e4:	92098993          	addi	s3,s3,-1760 # 80017c00 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep	
    800022e8:	0000fd17          	auipc	s10,0xf
    800022ec:	b00d0d13          	addi	s10,s10,-1280 # 80010de8 <wait_lock>
    havekids = 0;	
    800022f0:	8766                	mv	a4,s9
    for(np = proc; np < &proc[NPROC]; np++){	
    800022f2:	0000f497          	auipc	s1,0xf
    800022f6:	f0e48493          	addi	s1,s1,-242 # 80011200 <proc>
    800022fa:	a059                	j	80002380 <waitx+0xe2>
          pid = np->pid;	
    800022fc:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;	
    80002300:	1784a783          	lw	a5,376(s1)
    80002304:	00fc2023          	sw	a5,0(s8)
          *wtime = np->etime - np->ctime - np->rtime;	
    80002308:	17c4a703          	lw	a4,380(s1)
    8000230c:	9f3d                	addw	a4,a4,a5
    8000230e:	1804a783          	lw	a5,384(s1)
    80002312:	9f99                	subw	a5,a5,a4
    80002314:	00fba023          	sw	a5,0(s7)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,	
    80002318:	000b0e63          	beqz	s6,80002334 <waitx+0x96>
    8000231c:	4691                	li	a3,4
    8000231e:	02c48613          	addi	a2,s1,44
    80002322:	85da                	mv	a1,s6
    80002324:	05093503          	ld	a0,80(s2)
    80002328:	fffff097          	auipc	ra,0xfffff
    8000232c:	344080e7          	jalr	836(ra) # 8000166c <copyout>
    80002330:	02054563          	bltz	a0,8000235a <waitx+0xbc>
          freeproc(np);	
    80002334:	8526                	mv	a0,s1
    80002336:	00000097          	auipc	ra,0x0
    8000233a:	828080e7          	jalr	-2008(ra) # 80001b5e <freeproc>
          release(&np->lock);	
    8000233e:	8526                	mv	a0,s1
    80002340:	fffff097          	auipc	ra,0xfffff
    80002344:	94a080e7          	jalr	-1718(ra) # 80000c8a <release>
          release(&wait_lock);	
    80002348:	0000f517          	auipc	a0,0xf
    8000234c:	aa050513          	addi	a0,a0,-1376 # 80010de8 <wait_lock>
    80002350:	fffff097          	auipc	ra,0xfffff
    80002354:	93a080e7          	jalr	-1734(ra) # 80000c8a <release>
          return pid;	
    80002358:	a09d                	j	800023be <waitx+0x120>
            release(&np->lock);	
    8000235a:	8526                	mv	a0,s1
    8000235c:	fffff097          	auipc	ra,0xfffff
    80002360:	92e080e7          	jalr	-1746(ra) # 80000c8a <release>
            release(&wait_lock);	
    80002364:	0000f517          	auipc	a0,0xf
    80002368:	a8450513          	addi	a0,a0,-1404 # 80010de8 <wait_lock>
    8000236c:	fffff097          	auipc	ra,0xfffff
    80002370:	91e080e7          	jalr	-1762(ra) # 80000c8a <release>
            return -1;	
    80002374:	59fd                	li	s3,-1
    80002376:	a0a1                	j	800023be <waitx+0x120>
    for(np = proc; np < &proc[NPROC]; np++){	
    80002378:	1a848493          	addi	s1,s1,424
    8000237c:	03348463          	beq	s1,s3,800023a4 <waitx+0x106>
      if(np->parent == p){	
    80002380:	7c9c                	ld	a5,56(s1)
    80002382:	ff279be3          	bne	a5,s2,80002378 <waitx+0xda>
        acquire(&np->lock);	
    80002386:	8526                	mv	a0,s1
    80002388:	fffff097          	auipc	ra,0xfffff
    8000238c:	84e080e7          	jalr	-1970(ra) # 80000bd6 <acquire>
        if(np->state == ZOMBIE){	
    80002390:	4c9c                	lw	a5,24(s1)
    80002392:	f74785e3          	beq	a5,s4,800022fc <waitx+0x5e>
        release(&np->lock);	
    80002396:	8526                	mv	a0,s1
    80002398:	fffff097          	auipc	ra,0xfffff
    8000239c:	8f2080e7          	jalr	-1806(ra) # 80000c8a <release>
        havekids = 1;	
    800023a0:	8756                	mv	a4,s5
    800023a2:	bfd9                	j	80002378 <waitx+0xda>
    if(!havekids || p->killed){	
    800023a4:	c701                	beqz	a4,800023ac <waitx+0x10e>
    800023a6:	02892783          	lw	a5,40(s2)
    800023aa:	cb8d                	beqz	a5,800023dc <waitx+0x13e>
      release(&wait_lock);	
    800023ac:	0000f517          	auipc	a0,0xf
    800023b0:	a3c50513          	addi	a0,a0,-1476 # 80010de8 <wait_lock>
    800023b4:	fffff097          	auipc	ra,0xfffff
    800023b8:	8d6080e7          	jalr	-1834(ra) # 80000c8a <release>
      return -1;	
    800023bc:	59fd                	li	s3,-1
}	
    800023be:	854e                	mv	a0,s3
    800023c0:	60e6                	ld	ra,88(sp)
    800023c2:	6446                	ld	s0,80(sp)
    800023c4:	64a6                	ld	s1,72(sp)
    800023c6:	6906                	ld	s2,64(sp)
    800023c8:	79e2                	ld	s3,56(sp)
    800023ca:	7a42                	ld	s4,48(sp)
    800023cc:	7aa2                	ld	s5,40(sp)
    800023ce:	7b02                	ld	s6,32(sp)
    800023d0:	6be2                	ld	s7,24(sp)
    800023d2:	6c42                	ld	s8,16(sp)
    800023d4:	6ca2                	ld	s9,8(sp)
    800023d6:	6d02                	ld	s10,0(sp)
    800023d8:	6125                	addi	sp,sp,96
    800023da:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep	
    800023dc:	85ea                	mv	a1,s10
    800023de:	854a                	mv	a0,s2
    800023e0:	00000097          	auipc	ra,0x0
    800023e4:	e5a080e7          	jalr	-422(ra) # 8000223a <sleep>
    havekids = 0;	
    800023e8:	b721                	j	800022f0 <waitx+0x52>

00000000800023ea <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800023ea:	7139                	addi	sp,sp,-64
    800023ec:	fc06                	sd	ra,56(sp)
    800023ee:	f822                	sd	s0,48(sp)
    800023f0:	f426                	sd	s1,40(sp)
    800023f2:	f04a                	sd	s2,32(sp)
    800023f4:	ec4e                	sd	s3,24(sp)
    800023f6:	e852                	sd	s4,16(sp)
    800023f8:	e456                	sd	s5,8(sp)
    800023fa:	0080                	addi	s0,sp,64
    800023fc:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800023fe:	0000f497          	auipc	s1,0xf
    80002402:	e0248493          	addi	s1,s1,-510 # 80011200 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002406:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002408:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    8000240a:	00015917          	auipc	s2,0x15
    8000240e:	7f690913          	addi	s2,s2,2038 # 80017c00 <tickslock>
    80002412:	a811                	j	80002426 <wakeup+0x3c>
         #ifdef PBS	
          p->stime = ticks - p->s_start_time;	
        #endif
      }
      release(&p->lock);
    80002414:	8526                	mv	a0,s1
    80002416:	fffff097          	auipc	ra,0xfffff
    8000241a:	874080e7          	jalr	-1932(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000241e:	1a848493          	addi	s1,s1,424
    80002422:	03248663          	beq	s1,s2,8000244e <wakeup+0x64>
    if(p != myproc()){
    80002426:	fffff097          	auipc	ra,0xfffff
    8000242a:	586080e7          	jalr	1414(ra) # 800019ac <myproc>
    8000242e:	fea488e3          	beq	s1,a0,8000241e <wakeup+0x34>
      acquire(&p->lock);
    80002432:	8526                	mv	a0,s1
    80002434:	ffffe097          	auipc	ra,0xffffe
    80002438:	7a2080e7          	jalr	1954(ra) # 80000bd6 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    8000243c:	4c9c                	lw	a5,24(s1)
    8000243e:	fd379be3          	bne	a5,s3,80002414 <wakeup+0x2a>
    80002442:	709c                	ld	a5,32(s1)
    80002444:	fd4798e3          	bne	a5,s4,80002414 <wakeup+0x2a>
        p->state = RUNNABLE;
    80002448:	0154ac23          	sw	s5,24(s1)
    8000244c:	b7e1                	j	80002414 <wakeup+0x2a>
    }
  }
}
    8000244e:	70e2                	ld	ra,56(sp)
    80002450:	7442                	ld	s0,48(sp)
    80002452:	74a2                	ld	s1,40(sp)
    80002454:	7902                	ld	s2,32(sp)
    80002456:	69e2                	ld	s3,24(sp)
    80002458:	6a42                	ld	s4,16(sp)
    8000245a:	6aa2                	ld	s5,8(sp)
    8000245c:	6121                	addi	sp,sp,64
    8000245e:	8082                	ret

0000000080002460 <reparent>:
{
    80002460:	7179                	addi	sp,sp,-48
    80002462:	f406                	sd	ra,40(sp)
    80002464:	f022                	sd	s0,32(sp)
    80002466:	ec26                	sd	s1,24(sp)
    80002468:	e84a                	sd	s2,16(sp)
    8000246a:	e44e                	sd	s3,8(sp)
    8000246c:	e052                	sd	s4,0(sp)
    8000246e:	1800                	addi	s0,sp,48
    80002470:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002472:	0000f497          	auipc	s1,0xf
    80002476:	d8e48493          	addi	s1,s1,-626 # 80011200 <proc>
      pp->parent = initproc;
    8000247a:	00006a17          	auipc	s4,0x6
    8000247e:	6dea0a13          	addi	s4,s4,1758 # 80008b58 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002482:	00015997          	auipc	s3,0x15
    80002486:	77e98993          	addi	s3,s3,1918 # 80017c00 <tickslock>
    8000248a:	a029                	j	80002494 <reparent+0x34>
    8000248c:	1a848493          	addi	s1,s1,424
    80002490:	01348d63          	beq	s1,s3,800024aa <reparent+0x4a>
    if(pp->parent == p){
    80002494:	7c9c                	ld	a5,56(s1)
    80002496:	ff279be3          	bne	a5,s2,8000248c <reparent+0x2c>
      pp->parent = initproc;
    8000249a:	000a3503          	ld	a0,0(s4)
    8000249e:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800024a0:	00000097          	auipc	ra,0x0
    800024a4:	f4a080e7          	jalr	-182(ra) # 800023ea <wakeup>
    800024a8:	b7d5                	j	8000248c <reparent+0x2c>
}
    800024aa:	70a2                	ld	ra,40(sp)
    800024ac:	7402                	ld	s0,32(sp)
    800024ae:	64e2                	ld	s1,24(sp)
    800024b0:	6942                	ld	s2,16(sp)
    800024b2:	69a2                	ld	s3,8(sp)
    800024b4:	6a02                	ld	s4,0(sp)
    800024b6:	6145                	addi	sp,sp,48
    800024b8:	8082                	ret

00000000800024ba <exit>:
{
    800024ba:	7179                	addi	sp,sp,-48
    800024bc:	f406                	sd	ra,40(sp)
    800024be:	f022                	sd	s0,32(sp)
    800024c0:	ec26                	sd	s1,24(sp)
    800024c2:	e84a                	sd	s2,16(sp)
    800024c4:	e44e                	sd	s3,8(sp)
    800024c6:	e052                	sd	s4,0(sp)
    800024c8:	1800                	addi	s0,sp,48
    800024ca:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800024cc:	fffff097          	auipc	ra,0xfffff
    800024d0:	4e0080e7          	jalr	1248(ra) # 800019ac <myproc>
    800024d4:	89aa                	mv	s3,a0
  if(p == initproc)
    800024d6:	00006797          	auipc	a5,0x6
    800024da:	6827b783          	ld	a5,1666(a5) # 80008b58 <initproc>
    800024de:	0d050493          	addi	s1,a0,208
    800024e2:	15050913          	addi	s2,a0,336
    800024e6:	02a79363          	bne	a5,a0,8000250c <exit+0x52>
    panic("init exiting");
    800024ea:	00006517          	auipc	a0,0x6
    800024ee:	d7650513          	addi	a0,a0,-650 # 80008260 <digits+0x220>
    800024f2:	ffffe097          	auipc	ra,0xffffe
    800024f6:	04e080e7          	jalr	78(ra) # 80000540 <panic>
      fileclose(f);
    800024fa:	00002097          	auipc	ra,0x2
    800024fe:	636080e7          	jalr	1590(ra) # 80004b30 <fileclose>
      p->ofile[fd] = 0;
    80002502:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002506:	04a1                	addi	s1,s1,8
    80002508:	01248563          	beq	s1,s2,80002512 <exit+0x58>
    if(p->ofile[fd]){
    8000250c:	6088                	ld	a0,0(s1)
    8000250e:	f575                	bnez	a0,800024fa <exit+0x40>
    80002510:	bfdd                	j	80002506 <exit+0x4c>
  begin_op();
    80002512:	00002097          	auipc	ra,0x2
    80002516:	156080e7          	jalr	342(ra) # 80004668 <begin_op>
  iput(p->cwd);
    8000251a:	1509b503          	ld	a0,336(s3)
    8000251e:	00002097          	auipc	ra,0x2
    80002522:	938080e7          	jalr	-1736(ra) # 80003e56 <iput>
  end_op();
    80002526:	00002097          	auipc	ra,0x2
    8000252a:	1c0080e7          	jalr	448(ra) # 800046e6 <end_op>
  p->cwd = 0;
    8000252e:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002532:	0000f497          	auipc	s1,0xf
    80002536:	8b648493          	addi	s1,s1,-1866 # 80010de8 <wait_lock>
    8000253a:	8526                	mv	a0,s1
    8000253c:	ffffe097          	auipc	ra,0xffffe
    80002540:	69a080e7          	jalr	1690(ra) # 80000bd6 <acquire>
  reparent(p);
    80002544:	854e                	mv	a0,s3
    80002546:	00000097          	auipc	ra,0x0
    8000254a:	f1a080e7          	jalr	-230(ra) # 80002460 <reparent>
  wakeup(p->parent);
    8000254e:	0389b503          	ld	a0,56(s3)
    80002552:	00000097          	auipc	ra,0x0
    80002556:	e98080e7          	jalr	-360(ra) # 800023ea <wakeup>
  acquire(&p->lock);
    8000255a:	854e                	mv	a0,s3
    8000255c:	ffffe097          	auipc	ra,0xffffe
    80002560:	67a080e7          	jalr	1658(ra) # 80000bd6 <acquire>
  p->xstate = status;
    80002564:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002568:	4795                	li	a5,5
    8000256a:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    8000256e:	00006797          	auipc	a5,0x6
    80002572:	5f27a783          	lw	a5,1522(a5) # 80008b60 <ticks>
    80002576:	18f9a023          	sw	a5,384(s3)
  release(&wait_lock);
    8000257a:	8526                	mv	a0,s1
    8000257c:	ffffe097          	auipc	ra,0xffffe
    80002580:	70e080e7          	jalr	1806(ra) # 80000c8a <release>
  sched();
    80002584:	00000097          	auipc	ra,0x0
    80002588:	ba4080e7          	jalr	-1116(ra) # 80002128 <sched>
  panic("zombie exit");
    8000258c:	00006517          	auipc	a0,0x6
    80002590:	ce450513          	addi	a0,a0,-796 # 80008270 <digits+0x230>
    80002594:	ffffe097          	auipc	ra,0xffffe
    80002598:	fac080e7          	jalr	-84(ra) # 80000540 <panic>

000000008000259c <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000259c:	7179                	addi	sp,sp,-48
    8000259e:	f406                	sd	ra,40(sp)
    800025a0:	f022                	sd	s0,32(sp)
    800025a2:	ec26                	sd	s1,24(sp)
    800025a4:	e84a                	sd	s2,16(sp)
    800025a6:	e44e                	sd	s3,8(sp)
    800025a8:	1800                	addi	s0,sp,48
    800025aa:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800025ac:	0000f497          	auipc	s1,0xf
    800025b0:	c5448493          	addi	s1,s1,-940 # 80011200 <proc>
    800025b4:	00015997          	auipc	s3,0x15
    800025b8:	64c98993          	addi	s3,s3,1612 # 80017c00 <tickslock>
    acquire(&p->lock);
    800025bc:	8526                	mv	a0,s1
    800025be:	ffffe097          	auipc	ra,0xffffe
    800025c2:	618080e7          	jalr	1560(ra) # 80000bd6 <acquire>
    if(p->pid == pid){
    800025c6:	589c                	lw	a5,48(s1)
    800025c8:	01278d63          	beq	a5,s2,800025e2 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800025cc:	8526                	mv	a0,s1
    800025ce:	ffffe097          	auipc	ra,0xffffe
    800025d2:	6bc080e7          	jalr	1724(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800025d6:	1a848493          	addi	s1,s1,424
    800025da:	ff3491e3          	bne	s1,s3,800025bc <kill+0x20>
  }
  return -1;
    800025de:	557d                	li	a0,-1
    800025e0:	a829                	j	800025fa <kill+0x5e>
      p->killed = 1;
    800025e2:	4785                	li	a5,1
    800025e4:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800025e6:	4c98                	lw	a4,24(s1)
    800025e8:	4789                	li	a5,2
    800025ea:	00f70f63          	beq	a4,a5,80002608 <kill+0x6c>
      release(&p->lock);
    800025ee:	8526                	mv	a0,s1
    800025f0:	ffffe097          	auipc	ra,0xffffe
    800025f4:	69a080e7          	jalr	1690(ra) # 80000c8a <release>
      return 0;
    800025f8:	4501                	li	a0,0
}
    800025fa:	70a2                	ld	ra,40(sp)
    800025fc:	7402                	ld	s0,32(sp)
    800025fe:	64e2                	ld	s1,24(sp)
    80002600:	6942                	ld	s2,16(sp)
    80002602:	69a2                	ld	s3,8(sp)
    80002604:	6145                	addi	sp,sp,48
    80002606:	8082                	ret
        p->state = RUNNABLE;
    80002608:	478d                	li	a5,3
    8000260a:	cc9c                	sw	a5,24(s1)
    8000260c:	b7cd                	j	800025ee <kill+0x52>

000000008000260e <setkilled>:

void
setkilled(struct proc *p)
{
    8000260e:	1101                	addi	sp,sp,-32
    80002610:	ec06                	sd	ra,24(sp)
    80002612:	e822                	sd	s0,16(sp)
    80002614:	e426                	sd	s1,8(sp)
    80002616:	1000                	addi	s0,sp,32
    80002618:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000261a:	ffffe097          	auipc	ra,0xffffe
    8000261e:	5bc080e7          	jalr	1468(ra) # 80000bd6 <acquire>
  p->killed = 1;
    80002622:	4785                	li	a5,1
    80002624:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    80002626:	8526                	mv	a0,s1
    80002628:	ffffe097          	auipc	ra,0xffffe
    8000262c:	662080e7          	jalr	1634(ra) # 80000c8a <release>
}
    80002630:	60e2                	ld	ra,24(sp)
    80002632:	6442                	ld	s0,16(sp)
    80002634:	64a2                	ld	s1,8(sp)
    80002636:	6105                	addi	sp,sp,32
    80002638:	8082                	ret

000000008000263a <killed>:

int
killed(struct proc *p)
{
    8000263a:	1101                	addi	sp,sp,-32
    8000263c:	ec06                	sd	ra,24(sp)
    8000263e:	e822                	sd	s0,16(sp)
    80002640:	e426                	sd	s1,8(sp)
    80002642:	e04a                	sd	s2,0(sp)
    80002644:	1000                	addi	s0,sp,32
    80002646:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    80002648:	ffffe097          	auipc	ra,0xffffe
    8000264c:	58e080e7          	jalr	1422(ra) # 80000bd6 <acquire>
  k = p->killed;
    80002650:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002654:	8526                	mv	a0,s1
    80002656:	ffffe097          	auipc	ra,0xffffe
    8000265a:	634080e7          	jalr	1588(ra) # 80000c8a <release>
  return k;
}
    8000265e:	854a                	mv	a0,s2
    80002660:	60e2                	ld	ra,24(sp)
    80002662:	6442                	ld	s0,16(sp)
    80002664:	64a2                	ld	s1,8(sp)
    80002666:	6902                	ld	s2,0(sp)
    80002668:	6105                	addi	sp,sp,32
    8000266a:	8082                	ret

000000008000266c <wait>:
{
    8000266c:	715d                	addi	sp,sp,-80
    8000266e:	e486                	sd	ra,72(sp)
    80002670:	e0a2                	sd	s0,64(sp)
    80002672:	fc26                	sd	s1,56(sp)
    80002674:	f84a                	sd	s2,48(sp)
    80002676:	f44e                	sd	s3,40(sp)
    80002678:	f052                	sd	s4,32(sp)
    8000267a:	ec56                	sd	s5,24(sp)
    8000267c:	e85a                	sd	s6,16(sp)
    8000267e:	e45e                	sd	s7,8(sp)
    80002680:	e062                	sd	s8,0(sp)
    80002682:	0880                	addi	s0,sp,80
    80002684:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002686:	fffff097          	auipc	ra,0xfffff
    8000268a:	326080e7          	jalr	806(ra) # 800019ac <myproc>
    8000268e:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002690:	0000e517          	auipc	a0,0xe
    80002694:	75850513          	addi	a0,a0,1880 # 80010de8 <wait_lock>
    80002698:	ffffe097          	auipc	ra,0xffffe
    8000269c:	53e080e7          	jalr	1342(ra) # 80000bd6 <acquire>
    havekids = 0;
    800026a0:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    800026a2:	4a15                	li	s4,5
        havekids = 1;
    800026a4:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800026a6:	00015997          	auipc	s3,0x15
    800026aa:	55a98993          	addi	s3,s3,1370 # 80017c00 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800026ae:	0000ec17          	auipc	s8,0xe
    800026b2:	73ac0c13          	addi	s8,s8,1850 # 80010de8 <wait_lock>
    havekids = 0;
    800026b6:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800026b8:	0000f497          	auipc	s1,0xf
    800026bc:	b4848493          	addi	s1,s1,-1208 # 80011200 <proc>
    800026c0:	a0bd                	j	8000272e <wait+0xc2>
          pid = pp->pid;
    800026c2:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    800026c6:	000b0e63          	beqz	s6,800026e2 <wait+0x76>
    800026ca:	4691                	li	a3,4
    800026cc:	02c48613          	addi	a2,s1,44
    800026d0:	85da                	mv	a1,s6
    800026d2:	05093503          	ld	a0,80(s2)
    800026d6:	fffff097          	auipc	ra,0xfffff
    800026da:	f96080e7          	jalr	-106(ra) # 8000166c <copyout>
    800026de:	02054563          	bltz	a0,80002708 <wait+0x9c>
          freeproc(pp);
    800026e2:	8526                	mv	a0,s1
    800026e4:	fffff097          	auipc	ra,0xfffff
    800026e8:	47a080e7          	jalr	1146(ra) # 80001b5e <freeproc>
          release(&pp->lock);
    800026ec:	8526                	mv	a0,s1
    800026ee:	ffffe097          	auipc	ra,0xffffe
    800026f2:	59c080e7          	jalr	1436(ra) # 80000c8a <release>
          release(&wait_lock);
    800026f6:	0000e517          	auipc	a0,0xe
    800026fa:	6f250513          	addi	a0,a0,1778 # 80010de8 <wait_lock>
    800026fe:	ffffe097          	auipc	ra,0xffffe
    80002702:	58c080e7          	jalr	1420(ra) # 80000c8a <release>
          return pid;
    80002706:	a0b5                	j	80002772 <wait+0x106>
            release(&pp->lock);
    80002708:	8526                	mv	a0,s1
    8000270a:	ffffe097          	auipc	ra,0xffffe
    8000270e:	580080e7          	jalr	1408(ra) # 80000c8a <release>
            release(&wait_lock);
    80002712:	0000e517          	auipc	a0,0xe
    80002716:	6d650513          	addi	a0,a0,1750 # 80010de8 <wait_lock>
    8000271a:	ffffe097          	auipc	ra,0xffffe
    8000271e:	570080e7          	jalr	1392(ra) # 80000c8a <release>
            return -1;
    80002722:	59fd                	li	s3,-1
    80002724:	a0b9                	j	80002772 <wait+0x106>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002726:	1a848493          	addi	s1,s1,424
    8000272a:	03348463          	beq	s1,s3,80002752 <wait+0xe6>
      if(pp->parent == p){
    8000272e:	7c9c                	ld	a5,56(s1)
    80002730:	ff279be3          	bne	a5,s2,80002726 <wait+0xba>
        acquire(&pp->lock);
    80002734:	8526                	mv	a0,s1
    80002736:	ffffe097          	auipc	ra,0xffffe
    8000273a:	4a0080e7          	jalr	1184(ra) # 80000bd6 <acquire>
        if(pp->state == ZOMBIE){
    8000273e:	4c9c                	lw	a5,24(s1)
    80002740:	f94781e3          	beq	a5,s4,800026c2 <wait+0x56>
        release(&pp->lock);
    80002744:	8526                	mv	a0,s1
    80002746:	ffffe097          	auipc	ra,0xffffe
    8000274a:	544080e7          	jalr	1348(ra) # 80000c8a <release>
        havekids = 1;
    8000274e:	8756                	mv	a4,s5
    80002750:	bfd9                	j	80002726 <wait+0xba>
    if(!havekids || killed(p)){
    80002752:	c719                	beqz	a4,80002760 <wait+0xf4>
    80002754:	854a                	mv	a0,s2
    80002756:	00000097          	auipc	ra,0x0
    8000275a:	ee4080e7          	jalr	-284(ra) # 8000263a <killed>
    8000275e:	c51d                	beqz	a0,8000278c <wait+0x120>
      release(&wait_lock);
    80002760:	0000e517          	auipc	a0,0xe
    80002764:	68850513          	addi	a0,a0,1672 # 80010de8 <wait_lock>
    80002768:	ffffe097          	auipc	ra,0xffffe
    8000276c:	522080e7          	jalr	1314(ra) # 80000c8a <release>
      return -1;
    80002770:	59fd                	li	s3,-1
}
    80002772:	854e                	mv	a0,s3
    80002774:	60a6                	ld	ra,72(sp)
    80002776:	6406                	ld	s0,64(sp)
    80002778:	74e2                	ld	s1,56(sp)
    8000277a:	7942                	ld	s2,48(sp)
    8000277c:	79a2                	ld	s3,40(sp)
    8000277e:	7a02                	ld	s4,32(sp)
    80002780:	6ae2                	ld	s5,24(sp)
    80002782:	6b42                	ld	s6,16(sp)
    80002784:	6ba2                	ld	s7,8(sp)
    80002786:	6c02                	ld	s8,0(sp)
    80002788:	6161                	addi	sp,sp,80
    8000278a:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000278c:	85e2                	mv	a1,s8
    8000278e:	854a                	mv	a0,s2
    80002790:	00000097          	auipc	ra,0x0
    80002794:	aaa080e7          	jalr	-1366(ra) # 8000223a <sleep>
    havekids = 0;
    80002798:	bf39                	j	800026b6 <wait+0x4a>

000000008000279a <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000279a:	7179                	addi	sp,sp,-48
    8000279c:	f406                	sd	ra,40(sp)
    8000279e:	f022                	sd	s0,32(sp)
    800027a0:	ec26                	sd	s1,24(sp)
    800027a2:	e84a                	sd	s2,16(sp)
    800027a4:	e44e                	sd	s3,8(sp)
    800027a6:	e052                	sd	s4,0(sp)
    800027a8:	1800                	addi	s0,sp,48
    800027aa:	84aa                	mv	s1,a0
    800027ac:	892e                	mv	s2,a1
    800027ae:	89b2                	mv	s3,a2
    800027b0:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800027b2:	fffff097          	auipc	ra,0xfffff
    800027b6:	1fa080e7          	jalr	506(ra) # 800019ac <myproc>
  if(user_dst){
    800027ba:	c08d                	beqz	s1,800027dc <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800027bc:	86d2                	mv	a3,s4
    800027be:	864e                	mv	a2,s3
    800027c0:	85ca                	mv	a1,s2
    800027c2:	6928                	ld	a0,80(a0)
    800027c4:	fffff097          	auipc	ra,0xfffff
    800027c8:	ea8080e7          	jalr	-344(ra) # 8000166c <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800027cc:	70a2                	ld	ra,40(sp)
    800027ce:	7402                	ld	s0,32(sp)
    800027d0:	64e2                	ld	s1,24(sp)
    800027d2:	6942                	ld	s2,16(sp)
    800027d4:	69a2                	ld	s3,8(sp)
    800027d6:	6a02                	ld	s4,0(sp)
    800027d8:	6145                	addi	sp,sp,48
    800027da:	8082                	ret
    memmove((char *)dst, src, len);
    800027dc:	000a061b          	sext.w	a2,s4
    800027e0:	85ce                	mv	a1,s3
    800027e2:	854a                	mv	a0,s2
    800027e4:	ffffe097          	auipc	ra,0xffffe
    800027e8:	54a080e7          	jalr	1354(ra) # 80000d2e <memmove>
    return 0;
    800027ec:	8526                	mv	a0,s1
    800027ee:	bff9                	j	800027cc <either_copyout+0x32>

00000000800027f0 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800027f0:	7179                	addi	sp,sp,-48
    800027f2:	f406                	sd	ra,40(sp)
    800027f4:	f022                	sd	s0,32(sp)
    800027f6:	ec26                	sd	s1,24(sp)
    800027f8:	e84a                	sd	s2,16(sp)
    800027fa:	e44e                	sd	s3,8(sp)
    800027fc:	e052                	sd	s4,0(sp)
    800027fe:	1800                	addi	s0,sp,48
    80002800:	892a                	mv	s2,a0
    80002802:	84ae                	mv	s1,a1
    80002804:	89b2                	mv	s3,a2
    80002806:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002808:	fffff097          	auipc	ra,0xfffff
    8000280c:	1a4080e7          	jalr	420(ra) # 800019ac <myproc>
  if(user_src){
    80002810:	c08d                	beqz	s1,80002832 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002812:	86d2                	mv	a3,s4
    80002814:	864e                	mv	a2,s3
    80002816:	85ca                	mv	a1,s2
    80002818:	6928                	ld	a0,80(a0)
    8000281a:	fffff097          	auipc	ra,0xfffff
    8000281e:	ede080e7          	jalr	-290(ra) # 800016f8 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002822:	70a2                	ld	ra,40(sp)
    80002824:	7402                	ld	s0,32(sp)
    80002826:	64e2                	ld	s1,24(sp)
    80002828:	6942                	ld	s2,16(sp)
    8000282a:	69a2                	ld	s3,8(sp)
    8000282c:	6a02                	ld	s4,0(sp)
    8000282e:	6145                	addi	sp,sp,48
    80002830:	8082                	ret
    memmove(dst, (char*)src, len);
    80002832:	000a061b          	sext.w	a2,s4
    80002836:	85ce                	mv	a1,s3
    80002838:	854a                	mv	a0,s2
    8000283a:	ffffe097          	auipc	ra,0xffffe
    8000283e:	4f4080e7          	jalr	1268(ra) # 80000d2e <memmove>
    return 0;
    80002842:	8526                	mv	a0,s1
    80002844:	bff9                	j	80002822 <either_copyin+0x32>

0000000080002846 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002846:	7119                	addi	sp,sp,-128
    80002848:	fc86                	sd	ra,120(sp)
    8000284a:	f8a2                	sd	s0,112(sp)
    8000284c:	f4a6                	sd	s1,104(sp)
    8000284e:	f0ca                	sd	s2,96(sp)
    80002850:	ecce                	sd	s3,88(sp)
    80002852:	e8d2                	sd	s4,80(sp)
    80002854:	e4d6                	sd	s5,72(sp)
    80002856:	e0da                	sd	s6,64(sp)
    80002858:	fc5e                	sd	s7,56(sp)
    8000285a:	f862                	sd	s8,48(sp)
    8000285c:	f466                	sd	s9,40(sp)
    8000285e:	0100                	addi	s0,sp,128
  #endif	
  #ifdef PBS	
    printf("\nPID\tPrio\tState\trtime\twtime\tnrun");	
  #endif	
  #ifdef MLFQ	
    printf("\nPID\tPrio\tState\trtime\twtime\tnrun\tq0\tq1\tq2\tq3\tq4");	
    80002860:	00006517          	auipc	a0,0x6
    80002864:	a2850513          	addi	a0,a0,-1496 # 80008288 <digits+0x248>
    80002868:	ffffe097          	auipc	ra,0xffffe
    8000286c:	d22080e7          	jalr	-734(ra) # 8000058a <printf>
  #endif

  printf("\n");
    80002870:	00006517          	auipc	a0,0x6
    80002874:	85850513          	addi	a0,a0,-1960 # 800080c8 <digits+0x88>
    80002878:	ffffe097          	auipc	ra,0xffffe
    8000287c:	d12080e7          	jalr	-750(ra) # 8000058a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002880:	0000f497          	auipc	s1,0xf
    80002884:	98048493          	addi	s1,s1,-1664 # 80011200 <proc>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002888:	4915                	li	s2,5
      state = states[p->state];
    else
      state = "???";
    8000288a:	00006b97          	auipc	s7,0x6
    8000288e:	9f6b8b93          	addi	s7,s7,-1546 # 80008280 <digits+0x240>
      if (end_time == 0)	
        end_time = ticks;	
      int current_queue = p->current_queue;	
      if (p->state == ZOMBIE)	
        current_queue = -1;	
      printf("%d\t%d\t%s\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d", p->pid, current_queue, state, p->rtime, end_time - p->ctime - p->rtime, p->no_of_times_scheduled, p->queue_ticks[0], p->queue_ticks[1], p->queue_ticks[2], p->queue_ticks[3], p->queue_ticks[4]);	
    80002892:	00006a97          	auipc	s5,0x6
    80002896:	a26a8a93          	addi	s5,s5,-1498 # 800082b8 <digits+0x278>
      printf("\n");	
    8000289a:	00006a17          	auipc	s4,0x6
    8000289e:	82ea0a13          	addi	s4,s4,-2002 # 800080c8 <digits+0x88>
        current_queue = -1;	
    800028a2:	5b7d                	li	s6,-1
        end_time = ticks;	
    800028a4:	00006c97          	auipc	s9,0x6
    800028a8:	2bcc8c93          	addi	s9,s9,700 # 80008b60 <ticks>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028ac:	00006c17          	auipc	s8,0x6
    800028b0:	a64c0c13          	addi	s8,s8,-1436 # 80008310 <states.0>
  for(p = proc; p < &proc[NPROC]; p++){
    800028b4:	00015997          	auipc	s3,0x15
    800028b8:	34c98993          	addi	s3,s3,844 # 80017c00 <tickslock>
    800028bc:	a08d                	j	8000291e <procdump+0xd8>
      state = "???";
    800028be:	86de                	mv	a3,s7
    800028c0:	a895                	j	80002934 <procdump+0xee>
    800028c2:	86de                	mv	a3,s7
        end_time = ticks;	
    800028c4:	000ca583          	lw	a1,0(s9)
        current_queue = -1;	
    800028c8:	865a                	mv	a2,s6
      if (p->state == ZOMBIE)	
    800028ca:	01270463          	beq	a4,s2,800028d2 <procdump+0x8c>
      int current_queue = p->current_queue;	
    800028ce:	1a04a603          	lw	a2,416(s1)
      printf("%d\t%d\t%s\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d", p->pid, current_queue, state, p->rtime, end_time - p->ctime - p->rtime, p->no_of_times_scheduled, p->queue_ticks[0], p->queue_ticks[1], p->queue_ticks[2], p->queue_ticks[3], p->queue_ticks[4]);	
    800028d2:	1784a703          	lw	a4,376(s1)
    800028d6:	17c4a783          	lw	a5,380(s1)
    800028da:	9fb9                	addw	a5,a5,a4
    800028dc:	19c4a503          	lw	a0,412(s1)
    800028e0:	ec2a                	sd	a0,24(sp)
    800028e2:	1984a503          	lw	a0,408(s1)
    800028e6:	e82a                	sd	a0,16(sp)
    800028e8:	1944a503          	lw	a0,404(s1)
    800028ec:	e42a                	sd	a0,8(sp)
    800028ee:	1904a503          	lw	a0,400(s1)
    800028f2:	e02a                	sd	a0,0(sp)
    800028f4:	18c4a883          	lw	a7,396(s1)
    800028f8:	1844a803          	lw	a6,388(s1)
    800028fc:	40f587bb          	subw	a5,a1,a5
    80002900:	588c                	lw	a1,48(s1)
    80002902:	8556                	mv	a0,s5
    80002904:	ffffe097          	auipc	ra,0xffffe
    80002908:	c86080e7          	jalr	-890(ra) # 8000058a <printf>
      printf("\n");	
    8000290c:	8552                	mv	a0,s4
    8000290e:	ffffe097          	auipc	ra,0xffffe
    80002912:	c7c080e7          	jalr	-900(ra) # 8000058a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002916:	1a848493          	addi	s1,s1,424
    8000291a:	03348863          	beq	s1,s3,8000294a <procdump+0x104>
    if(p->state == UNUSED)
    8000291e:	4c98                	lw	a4,24(s1)
    80002920:	db7d                	beqz	a4,80002916 <procdump+0xd0>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002922:	00e96d63          	bltu	s2,a4,8000293c <procdump+0xf6>
    80002926:	02071693          	slli	a3,a4,0x20
    8000292a:	01d6d793          	srli	a5,a3,0x1d
    8000292e:	97e2                	add	a5,a5,s8
    80002930:	6394                	ld	a3,0(a5)
    80002932:	d6d1                	beqz	a3,800028be <procdump+0x78>
      int end_time = p->etime;	
    80002934:	1804a583          	lw	a1,384(s1)
      if (end_time == 0)	
    80002938:	f9c1                	bnez	a1,800028c8 <procdump+0x82>
    8000293a:	b769                	j	800028c4 <procdump+0x7e>
      int end_time = p->etime;	
    8000293c:	1804a583          	lw	a1,384(s1)
      if (end_time == 0)	
    80002940:	d1c9                	beqz	a1,800028c2 <procdump+0x7c>
      int current_queue = p->current_queue;	
    80002942:	1a04a603          	lw	a2,416(s1)
      state = "???";
    80002946:	86de                	mv	a3,s7
    80002948:	b769                	j	800028d2 <procdump+0x8c>
    #endif
  }
}
    8000294a:	70e6                	ld	ra,120(sp)
    8000294c:	7446                	ld	s0,112(sp)
    8000294e:	74a6                	ld	s1,104(sp)
    80002950:	7906                	ld	s2,96(sp)
    80002952:	69e6                	ld	s3,88(sp)
    80002954:	6a46                	ld	s4,80(sp)
    80002956:	6aa6                	ld	s5,72(sp)
    80002958:	6b06                	ld	s6,64(sp)
    8000295a:	7be2                	ld	s7,56(sp)
    8000295c:	7c42                	ld	s8,48(sp)
    8000295e:	7ca2                	ld	s9,40(sp)
    80002960:	6109                	addi	sp,sp,128
    80002962:	8082                	ret

0000000080002964 <swtch>:
    80002964:	00153023          	sd	ra,0(a0)
    80002968:	00253423          	sd	sp,8(a0)
    8000296c:	e900                	sd	s0,16(a0)
    8000296e:	ed04                	sd	s1,24(a0)
    80002970:	03253023          	sd	s2,32(a0)
    80002974:	03353423          	sd	s3,40(a0)
    80002978:	03453823          	sd	s4,48(a0)
    8000297c:	03553c23          	sd	s5,56(a0)
    80002980:	05653023          	sd	s6,64(a0)
    80002984:	05753423          	sd	s7,72(a0)
    80002988:	05853823          	sd	s8,80(a0)
    8000298c:	05953c23          	sd	s9,88(a0)
    80002990:	07a53023          	sd	s10,96(a0)
    80002994:	07b53423          	sd	s11,104(a0)
    80002998:	0005b083          	ld	ra,0(a1)
    8000299c:	0085b103          	ld	sp,8(a1)
    800029a0:	6980                	ld	s0,16(a1)
    800029a2:	6d84                	ld	s1,24(a1)
    800029a4:	0205b903          	ld	s2,32(a1)
    800029a8:	0285b983          	ld	s3,40(a1)
    800029ac:	0305ba03          	ld	s4,48(a1)
    800029b0:	0385ba83          	ld	s5,56(a1)
    800029b4:	0405bb03          	ld	s6,64(a1)
    800029b8:	0485bb83          	ld	s7,72(a1)
    800029bc:	0505bc03          	ld	s8,80(a1)
    800029c0:	0585bc83          	ld	s9,88(a1)
    800029c4:	0605bd03          	ld	s10,96(a1)
    800029c8:	0685bd83          	ld	s11,104(a1)
    800029cc:	8082                	ret

00000000800029ce <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800029ce:	1141                	addi	sp,sp,-16
    800029d0:	e406                	sd	ra,8(sp)
    800029d2:	e022                	sd	s0,0(sp)
    800029d4:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800029d6:	00006597          	auipc	a1,0x6
    800029da:	96a58593          	addi	a1,a1,-1686 # 80008340 <states.0+0x30>
    800029de:	00015517          	auipc	a0,0x15
    800029e2:	22250513          	addi	a0,a0,546 # 80017c00 <tickslock>
    800029e6:	ffffe097          	auipc	ra,0xffffe
    800029ea:	160080e7          	jalr	352(ra) # 80000b46 <initlock>
}
    800029ee:	60a2                	ld	ra,8(sp)
    800029f0:	6402                	ld	s0,0(sp)
    800029f2:	0141                	addi	sp,sp,16
    800029f4:	8082                	ret

00000000800029f6 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800029f6:	1141                	addi	sp,sp,-16
    800029f8:	e422                	sd	s0,8(sp)
    800029fa:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029fc:	00003797          	auipc	a5,0x3
    80002a00:	78478793          	addi	a5,a5,1924 # 80006180 <kernelvec>
    80002a04:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002a08:	6422                	ld	s0,8(sp)
    80002a0a:	0141                	addi	sp,sp,16
    80002a0c:	8082                	ret

0000000080002a0e <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002a0e:	1141                	addi	sp,sp,-16
    80002a10:	e406                	sd	ra,8(sp)
    80002a12:	e022                	sd	s0,0(sp)
    80002a14:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002a16:	fffff097          	auipc	ra,0xfffff
    80002a1a:	f96080e7          	jalr	-106(ra) # 800019ac <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a1e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002a22:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a24:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002a28:	00004697          	auipc	a3,0x4
    80002a2c:	5d868693          	addi	a3,a3,1496 # 80007000 <_trampoline>
    80002a30:	00004717          	auipc	a4,0x4
    80002a34:	5d070713          	addi	a4,a4,1488 # 80007000 <_trampoline>
    80002a38:	8f15                	sub	a4,a4,a3
    80002a3a:	040007b7          	lui	a5,0x4000
    80002a3e:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002a40:	07b2                	slli	a5,a5,0xc
    80002a42:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a44:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002a48:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002a4a:	18002673          	csrr	a2,satp
    80002a4e:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002a50:	6d30                	ld	a2,88(a0)
    80002a52:	6138                	ld	a4,64(a0)
    80002a54:	6585                	lui	a1,0x1
    80002a56:	972e                	add	a4,a4,a1
    80002a58:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002a5a:	6d38                	ld	a4,88(a0)
    80002a5c:	00000617          	auipc	a2,0x0
    80002a60:	13e60613          	addi	a2,a2,318 # 80002b9a <usertrap>
    80002a64:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002a66:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002a68:	8612                	mv	a2,tp
    80002a6a:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a6c:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002a70:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002a74:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a78:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002a7c:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a7e:	6f18                	ld	a4,24(a4)
    80002a80:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002a84:	6928                	ld	a0,80(a0)
    80002a86:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002a88:	00004717          	auipc	a4,0x4
    80002a8c:	61470713          	addi	a4,a4,1556 # 8000709c <userret>
    80002a90:	8f15                	sub	a4,a4,a3
    80002a92:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002a94:	577d                	li	a4,-1
    80002a96:	177e                	slli	a4,a4,0x3f
    80002a98:	8d59                	or	a0,a0,a4
    80002a9a:	9782                	jalr	a5
}
    80002a9c:	60a2                	ld	ra,8(sp)
    80002a9e:	6402                	ld	s0,0(sp)
    80002aa0:	0141                	addi	sp,sp,16
    80002aa2:	8082                	ret

0000000080002aa4 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002aa4:	1101                	addi	sp,sp,-32
    80002aa6:	ec06                	sd	ra,24(sp)
    80002aa8:	e822                	sd	s0,16(sp)
    80002aaa:	e426                	sd	s1,8(sp)
    80002aac:	e04a                	sd	s2,0(sp)
    80002aae:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002ab0:	00015917          	auipc	s2,0x15
    80002ab4:	15090913          	addi	s2,s2,336 # 80017c00 <tickslock>
    80002ab8:	854a                	mv	a0,s2
    80002aba:	ffffe097          	auipc	ra,0xffffe
    80002abe:	11c080e7          	jalr	284(ra) # 80000bd6 <acquire>
  ticks++;
    80002ac2:	00006497          	auipc	s1,0x6
    80002ac6:	09e48493          	addi	s1,s1,158 # 80008b60 <ticks>
    80002aca:	409c                	lw	a5,0(s1)
    80002acc:	2785                	addiw	a5,a5,1
    80002ace:	c09c                	sw	a5,0(s1)
   update_time();
    80002ad0:	fffff097          	auipc	ra,0xfffff
    80002ad4:	412080e7          	jalr	1042(ra) # 80001ee2 <update_time>
  wakeup(&ticks);
    80002ad8:	8526                	mv	a0,s1
    80002ada:	00000097          	auipc	ra,0x0
    80002ade:	910080e7          	jalr	-1776(ra) # 800023ea <wakeup>
  release(&tickslock);
    80002ae2:	854a                	mv	a0,s2
    80002ae4:	ffffe097          	auipc	ra,0xffffe
    80002ae8:	1a6080e7          	jalr	422(ra) # 80000c8a <release>
}
    80002aec:	60e2                	ld	ra,24(sp)
    80002aee:	6442                	ld	s0,16(sp)
    80002af0:	64a2                	ld	s1,8(sp)
    80002af2:	6902                	ld	s2,0(sp)
    80002af4:	6105                	addi	sp,sp,32
    80002af6:	8082                	ret

0000000080002af8 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002af8:	1101                	addi	sp,sp,-32
    80002afa:	ec06                	sd	ra,24(sp)
    80002afc:	e822                	sd	s0,16(sp)
    80002afe:	e426                	sd	s1,8(sp)
    80002b00:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b02:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002b06:	00074d63          	bltz	a4,80002b20 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002b0a:	57fd                	li	a5,-1
    80002b0c:	17fe                	slli	a5,a5,0x3f
    80002b0e:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002b10:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002b12:	06f70363          	beq	a4,a5,80002b78 <devintr+0x80>
  }
}
    80002b16:	60e2                	ld	ra,24(sp)
    80002b18:	6442                	ld	s0,16(sp)
    80002b1a:	64a2                	ld	s1,8(sp)
    80002b1c:	6105                	addi	sp,sp,32
    80002b1e:	8082                	ret
     (scause & 0xff) == 9){
    80002b20:	0ff77793          	zext.b	a5,a4
  if((scause & 0x8000000000000000L) &&
    80002b24:	46a5                	li	a3,9
    80002b26:	fed792e3          	bne	a5,a3,80002b0a <devintr+0x12>
    int irq = plic_claim();
    80002b2a:	00003097          	auipc	ra,0x3
    80002b2e:	75e080e7          	jalr	1886(ra) # 80006288 <plic_claim>
    80002b32:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002b34:	47a9                	li	a5,10
    80002b36:	02f50763          	beq	a0,a5,80002b64 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002b3a:	4785                	li	a5,1
    80002b3c:	02f50963          	beq	a0,a5,80002b6e <devintr+0x76>
    return 1;
    80002b40:	4505                	li	a0,1
    } else if(irq){
    80002b42:	d8f1                	beqz	s1,80002b16 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002b44:	85a6                	mv	a1,s1
    80002b46:	00006517          	auipc	a0,0x6
    80002b4a:	80250513          	addi	a0,a0,-2046 # 80008348 <states.0+0x38>
    80002b4e:	ffffe097          	auipc	ra,0xffffe
    80002b52:	a3c080e7          	jalr	-1476(ra) # 8000058a <printf>
      plic_complete(irq);
    80002b56:	8526                	mv	a0,s1
    80002b58:	00003097          	auipc	ra,0x3
    80002b5c:	754080e7          	jalr	1876(ra) # 800062ac <plic_complete>
    return 1;
    80002b60:	4505                	li	a0,1
    80002b62:	bf55                	j	80002b16 <devintr+0x1e>
      uartintr();
    80002b64:	ffffe097          	auipc	ra,0xffffe
    80002b68:	e34080e7          	jalr	-460(ra) # 80000998 <uartintr>
    80002b6c:	b7ed                	j	80002b56 <devintr+0x5e>
      virtio_disk_intr();
    80002b6e:	00004097          	auipc	ra,0x4
    80002b72:	c06080e7          	jalr	-1018(ra) # 80006774 <virtio_disk_intr>
    80002b76:	b7c5                	j	80002b56 <devintr+0x5e>
    if(cpuid() == 0){
    80002b78:	fffff097          	auipc	ra,0xfffff
    80002b7c:	e08080e7          	jalr	-504(ra) # 80001980 <cpuid>
    80002b80:	c901                	beqz	a0,80002b90 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002b82:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002b86:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002b88:	14479073          	csrw	sip,a5
    return 2;
    80002b8c:	4509                	li	a0,2
    80002b8e:	b761                	j	80002b16 <devintr+0x1e>
      clockintr();
    80002b90:	00000097          	auipc	ra,0x0
    80002b94:	f14080e7          	jalr	-236(ra) # 80002aa4 <clockintr>
    80002b98:	b7ed                	j	80002b82 <devintr+0x8a>

0000000080002b9a <usertrap>:
{
    80002b9a:	1101                	addi	sp,sp,-32
    80002b9c:	ec06                	sd	ra,24(sp)
    80002b9e:	e822                	sd	s0,16(sp)
    80002ba0:	e426                	sd	s1,8(sp)
    80002ba2:	e04a                	sd	s2,0(sp)
    80002ba4:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ba6:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002baa:	1007f793          	andi	a5,a5,256
    80002bae:	e3b1                	bnez	a5,80002bf2 <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002bb0:	00003797          	auipc	a5,0x3
    80002bb4:	5d078793          	addi	a5,a5,1488 # 80006180 <kernelvec>
    80002bb8:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002bbc:	fffff097          	auipc	ra,0xfffff
    80002bc0:	df0080e7          	jalr	-528(ra) # 800019ac <myproc>
    80002bc4:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002bc6:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bc8:	14102773          	csrr	a4,sepc
    80002bcc:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002bce:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002bd2:	47a1                	li	a5,8
    80002bd4:	02f70763          	beq	a4,a5,80002c02 <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    80002bd8:	00000097          	auipc	ra,0x0
    80002bdc:	f20080e7          	jalr	-224(ra) # 80002af8 <devintr>
    80002be0:	892a                	mv	s2,a0
    80002be2:	c151                	beqz	a0,80002c66 <usertrap+0xcc>
  if(killed(p))
    80002be4:	8526                	mv	a0,s1
    80002be6:	00000097          	auipc	ra,0x0
    80002bea:	a54080e7          	jalr	-1452(ra) # 8000263a <killed>
    80002bee:	c929                	beqz	a0,80002c40 <usertrap+0xa6>
    80002bf0:	a099                	j	80002c36 <usertrap+0x9c>
    panic("usertrap: not from user mode");
    80002bf2:	00005517          	auipc	a0,0x5
    80002bf6:	77650513          	addi	a0,a0,1910 # 80008368 <states.0+0x58>
    80002bfa:	ffffe097          	auipc	ra,0xffffe
    80002bfe:	946080e7          	jalr	-1722(ra) # 80000540 <panic>
    if(killed(p))
    80002c02:	00000097          	auipc	ra,0x0
    80002c06:	a38080e7          	jalr	-1480(ra) # 8000263a <killed>
    80002c0a:	e921                	bnez	a0,80002c5a <usertrap+0xc0>
    p->trapframe->epc += 4;
    80002c0c:	6cb8                	ld	a4,88(s1)
    80002c0e:	6f1c                	ld	a5,24(a4)
    80002c10:	0791                	addi	a5,a5,4
    80002c12:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c14:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002c18:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c1c:	10079073          	csrw	sstatus,a5
    syscall();
    80002c20:	00000097          	auipc	ra,0x0
    80002c24:	374080e7          	jalr	884(ra) # 80002f94 <syscall>
  if(killed(p))
    80002c28:	8526                	mv	a0,s1
    80002c2a:	00000097          	auipc	ra,0x0
    80002c2e:	a10080e7          	jalr	-1520(ra) # 8000263a <killed>
    80002c32:	c911                	beqz	a0,80002c46 <usertrap+0xac>
    80002c34:	4901                	li	s2,0
    exit(-1);
    80002c36:	557d                	li	a0,-1
    80002c38:	00000097          	auipc	ra,0x0
    80002c3c:	882080e7          	jalr	-1918(ra) # 800024ba <exit>
    if(which_dev == 2) {
    80002c40:	4789                	li	a5,2
    80002c42:	04f90f63          	beq	s2,a5,80002ca0 <usertrap+0x106>
  usertrapret();
    80002c46:	00000097          	auipc	ra,0x0
    80002c4a:	dc8080e7          	jalr	-568(ra) # 80002a0e <usertrapret>
}
    80002c4e:	60e2                	ld	ra,24(sp)
    80002c50:	6442                	ld	s0,16(sp)
    80002c52:	64a2                	ld	s1,8(sp)
    80002c54:	6902                	ld	s2,0(sp)
    80002c56:	6105                	addi	sp,sp,32
    80002c58:	8082                	ret
      exit(-1);
    80002c5a:	557d                	li	a0,-1
    80002c5c:	00000097          	auipc	ra,0x0
    80002c60:	85e080e7          	jalr	-1954(ra) # 800024ba <exit>
    80002c64:	b765                	j	80002c0c <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c66:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002c6a:	5890                	lw	a2,48(s1)
    80002c6c:	00005517          	auipc	a0,0x5
    80002c70:	71c50513          	addi	a0,a0,1820 # 80008388 <states.0+0x78>
    80002c74:	ffffe097          	auipc	ra,0xffffe
    80002c78:	916080e7          	jalr	-1770(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c7c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c80:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c84:	00005517          	auipc	a0,0x5
    80002c88:	73450513          	addi	a0,a0,1844 # 800083b8 <states.0+0xa8>
    80002c8c:	ffffe097          	auipc	ra,0xffffe
    80002c90:	8fe080e7          	jalr	-1794(ra) # 8000058a <printf>
    setkilled(p);
    80002c94:	8526                	mv	a0,s1
    80002c96:	00000097          	auipc	ra,0x0
    80002c9a:	978080e7          	jalr	-1672(ra) # 8000260e <setkilled>
    80002c9e:	b769                	j	80002c28 <usertrap+0x8e>
        struct proc *p = myproc();
    80002ca0:	fffff097          	auipc	ra,0xfffff
    80002ca4:	d0c080e7          	jalr	-756(ra) # 800019ac <myproc>
        if ((ticks - p->entry_time) > (1 << p->current_queue)) {
    80002ca8:	00006617          	auipc	a2,0x6
    80002cac:	eb862603          	lw	a2,-328(a2) # 80008b60 <ticks>
    80002cb0:	18852783          	lw	a5,392(a0)
    80002cb4:	40f607bb          	subw	a5,a2,a5
    80002cb8:	0007859b          	sext.w	a1,a5
    80002cbc:	1a052683          	lw	a3,416(a0)
    80002cc0:	4705                	li	a4,1
    80002cc2:	00d7173b          	sllw	a4,a4,a3
    80002cc6:	f8b770e3          	bgeu	a4,a1,80002c46 <usertrap+0xac>
          p->queue_ticks[p->current_queue] += (ticks - p->entry_time);
    80002cca:	02069593          	slli	a1,a3,0x20
    80002cce:	01e5d713          	srli	a4,a1,0x1e
    80002cd2:	972a                	add	a4,a4,a0
    80002cd4:	18c72583          	lw	a1,396(a4)
    80002cd8:	9fad                	addw	a5,a5,a1
    80002cda:	18f72623          	sw	a5,396(a4)
          if (p->current_queue < 4)
    80002cde:	478d                	li	a5,3
    80002ce0:	00d7e563          	bltu	a5,a3,80002cea <usertrap+0x150>
            p->current_queue++;
    80002ce4:	2685                	addiw	a3,a3,1
    80002ce6:	1ad52023          	sw	a3,416(a0)
          p->entry_time = ticks;
    80002cea:	18c52423          	sw	a2,392(a0)
          yield();
    80002cee:	fffff097          	auipc	ra,0xfffff
    80002cf2:	510080e7          	jalr	1296(ra) # 800021fe <yield>
    80002cf6:	bf81                	j	80002c46 <usertrap+0xac>

0000000080002cf8 <kerneltrap>:
{
    80002cf8:	7179                	addi	sp,sp,-48
    80002cfa:	f406                	sd	ra,40(sp)
    80002cfc:	f022                	sd	s0,32(sp)
    80002cfe:	ec26                	sd	s1,24(sp)
    80002d00:	e84a                	sd	s2,16(sp)
    80002d02:	e44e                	sd	s3,8(sp)
    80002d04:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d06:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d0a:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d0e:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002d12:	1004f793          	andi	a5,s1,256
    80002d16:	cb85                	beqz	a5,80002d46 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d18:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002d1c:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002d1e:	ef85                	bnez	a5,80002d56 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002d20:	00000097          	auipc	ra,0x0
    80002d24:	dd8080e7          	jalr	-552(ra) # 80002af8 <devintr>
    80002d28:	cd1d                	beqz	a0,80002d66 <kerneltrap+0x6e>
    if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING) {
    80002d2a:	4789                	li	a5,2
    80002d2c:	06f50a63          	beq	a0,a5,80002da0 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002d30:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d34:	10049073          	csrw	sstatus,s1
}
    80002d38:	70a2                	ld	ra,40(sp)
    80002d3a:	7402                	ld	s0,32(sp)
    80002d3c:	64e2                	ld	s1,24(sp)
    80002d3e:	6942                	ld	s2,16(sp)
    80002d40:	69a2                	ld	s3,8(sp)
    80002d42:	6145                	addi	sp,sp,48
    80002d44:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002d46:	00005517          	auipc	a0,0x5
    80002d4a:	69250513          	addi	a0,a0,1682 # 800083d8 <states.0+0xc8>
    80002d4e:	ffffd097          	auipc	ra,0xffffd
    80002d52:	7f2080e7          	jalr	2034(ra) # 80000540 <panic>
    panic("kerneltrap: interrupts enabled");
    80002d56:	00005517          	auipc	a0,0x5
    80002d5a:	6aa50513          	addi	a0,a0,1706 # 80008400 <states.0+0xf0>
    80002d5e:	ffffd097          	auipc	ra,0xffffd
    80002d62:	7e2080e7          	jalr	2018(ra) # 80000540 <panic>
    printf("scause %p\n", scause);
    80002d66:	85ce                	mv	a1,s3
    80002d68:	00005517          	auipc	a0,0x5
    80002d6c:	6b850513          	addi	a0,a0,1720 # 80008420 <states.0+0x110>
    80002d70:	ffffe097          	auipc	ra,0xffffe
    80002d74:	81a080e7          	jalr	-2022(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d78:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002d7c:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002d80:	00005517          	auipc	a0,0x5
    80002d84:	6b050513          	addi	a0,a0,1712 # 80008430 <states.0+0x120>
    80002d88:	ffffe097          	auipc	ra,0xffffe
    80002d8c:	802080e7          	jalr	-2046(ra) # 8000058a <printf>
    panic("kerneltrap");
    80002d90:	00005517          	auipc	a0,0x5
    80002d94:	6b850513          	addi	a0,a0,1720 # 80008448 <states.0+0x138>
    80002d98:	ffffd097          	auipc	ra,0xffffd
    80002d9c:	7a8080e7          	jalr	1960(ra) # 80000540 <panic>
    if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING) {
    80002da0:	fffff097          	auipc	ra,0xfffff
    80002da4:	c0c080e7          	jalr	-1012(ra) # 800019ac <myproc>
    80002da8:	d541                	beqz	a0,80002d30 <kerneltrap+0x38>
    80002daa:	fffff097          	auipc	ra,0xfffff
    80002dae:	c02080e7          	jalr	-1022(ra) # 800019ac <myproc>
    80002db2:	4d18                	lw	a4,24(a0)
    80002db4:	4791                	li	a5,4
    80002db6:	f6f71de3          	bne	a4,a5,80002d30 <kerneltrap+0x38>
        struct proc *p = myproc();
    80002dba:	fffff097          	auipc	ra,0xfffff
    80002dbe:	bf2080e7          	jalr	-1038(ra) # 800019ac <myproc>
        if ((ticks - p->entry_time) > (1 << p->current_queue)) {
    80002dc2:	00006617          	auipc	a2,0x6
    80002dc6:	d9e62603          	lw	a2,-610(a2) # 80008b60 <ticks>
    80002dca:	18852783          	lw	a5,392(a0)
    80002dce:	40f607bb          	subw	a5,a2,a5
    80002dd2:	0007859b          	sext.w	a1,a5
    80002dd6:	1a052683          	lw	a3,416(a0)
    80002dda:	4705                	li	a4,1
    80002ddc:	00d7173b          	sllw	a4,a4,a3
    80002de0:	f4b778e3          	bgeu	a4,a1,80002d30 <kerneltrap+0x38>
          p->queue_ticks[p->current_queue] += (ticks - p->entry_time);
    80002de4:	02069593          	slli	a1,a3,0x20
    80002de8:	01e5d713          	srli	a4,a1,0x1e
    80002dec:	972a                	add	a4,a4,a0
    80002dee:	18c72583          	lw	a1,396(a4)
    80002df2:	9fad                	addw	a5,a5,a1
    80002df4:	18f72623          	sw	a5,396(a4)
          if (p->current_queue < 4)
    80002df8:	478d                	li	a5,3
    80002dfa:	00d7e563          	bltu	a5,a3,80002e04 <kerneltrap+0x10c>
            p->current_queue++;
    80002dfe:	2685                	addiw	a3,a3,1
    80002e00:	1ad52023          	sw	a3,416(a0)
          p->entry_time = ticks;
    80002e04:	18c52423          	sw	a2,392(a0)
          yield();
    80002e08:	fffff097          	auipc	ra,0xfffff
    80002e0c:	3f6080e7          	jalr	1014(ra) # 800021fe <yield>
    80002e10:	b705                	j	80002d30 <kerneltrap+0x38>

0000000080002e12 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002e12:	1101                	addi	sp,sp,-32
    80002e14:	ec06                	sd	ra,24(sp)
    80002e16:	e822                	sd	s0,16(sp)
    80002e18:	e426                	sd	s1,8(sp)
    80002e1a:	1000                	addi	s0,sp,32
    80002e1c:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002e1e:	fffff097          	auipc	ra,0xfffff
    80002e22:	b8e080e7          	jalr	-1138(ra) # 800019ac <myproc>
  switch (n) {
    80002e26:	4795                	li	a5,5
    80002e28:	0497e163          	bltu	a5,s1,80002e6a <argraw+0x58>
    80002e2c:	048a                	slli	s1,s1,0x2
    80002e2e:	00005717          	auipc	a4,0x5
    80002e32:	74a70713          	addi	a4,a4,1866 # 80008578 <states.0+0x268>
    80002e36:	94ba                	add	s1,s1,a4
    80002e38:	409c                	lw	a5,0(s1)
    80002e3a:	97ba                	add	a5,a5,a4
    80002e3c:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002e3e:	6d3c                	ld	a5,88(a0)
    80002e40:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002e42:	60e2                	ld	ra,24(sp)
    80002e44:	6442                	ld	s0,16(sp)
    80002e46:	64a2                	ld	s1,8(sp)
    80002e48:	6105                	addi	sp,sp,32
    80002e4a:	8082                	ret
    return p->trapframe->a1;
    80002e4c:	6d3c                	ld	a5,88(a0)
    80002e4e:	7fa8                	ld	a0,120(a5)
    80002e50:	bfcd                	j	80002e42 <argraw+0x30>
    return p->trapframe->a2;
    80002e52:	6d3c                	ld	a5,88(a0)
    80002e54:	63c8                	ld	a0,128(a5)
    80002e56:	b7f5                	j	80002e42 <argraw+0x30>
    return p->trapframe->a3;
    80002e58:	6d3c                	ld	a5,88(a0)
    80002e5a:	67c8                	ld	a0,136(a5)
    80002e5c:	b7dd                	j	80002e42 <argraw+0x30>
    return p->trapframe->a4;
    80002e5e:	6d3c                	ld	a5,88(a0)
    80002e60:	6bc8                	ld	a0,144(a5)
    80002e62:	b7c5                	j	80002e42 <argraw+0x30>
    return p->trapframe->a5;
    80002e64:	6d3c                	ld	a5,88(a0)
    80002e66:	6fc8                	ld	a0,152(a5)
    80002e68:	bfe9                	j	80002e42 <argraw+0x30>
  panic("argraw");
    80002e6a:	00005517          	auipc	a0,0x5
    80002e6e:	5ee50513          	addi	a0,a0,1518 # 80008458 <states.0+0x148>
    80002e72:	ffffd097          	auipc	ra,0xffffd
    80002e76:	6ce080e7          	jalr	1742(ra) # 80000540 <panic>

0000000080002e7a <fetchaddr>:
{
    80002e7a:	1101                	addi	sp,sp,-32
    80002e7c:	ec06                	sd	ra,24(sp)
    80002e7e:	e822                	sd	s0,16(sp)
    80002e80:	e426                	sd	s1,8(sp)
    80002e82:	e04a                	sd	s2,0(sp)
    80002e84:	1000                	addi	s0,sp,32
    80002e86:	84aa                	mv	s1,a0
    80002e88:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002e8a:	fffff097          	auipc	ra,0xfffff
    80002e8e:	b22080e7          	jalr	-1246(ra) # 800019ac <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002e92:	653c                	ld	a5,72(a0)
    80002e94:	02f4f863          	bgeu	s1,a5,80002ec4 <fetchaddr+0x4a>
    80002e98:	00848713          	addi	a4,s1,8
    80002e9c:	02e7e663          	bltu	a5,a4,80002ec8 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002ea0:	46a1                	li	a3,8
    80002ea2:	8626                	mv	a2,s1
    80002ea4:	85ca                	mv	a1,s2
    80002ea6:	6928                	ld	a0,80(a0)
    80002ea8:	fffff097          	auipc	ra,0xfffff
    80002eac:	850080e7          	jalr	-1968(ra) # 800016f8 <copyin>
    80002eb0:	00a03533          	snez	a0,a0
    80002eb4:	40a00533          	neg	a0,a0
}
    80002eb8:	60e2                	ld	ra,24(sp)
    80002eba:	6442                	ld	s0,16(sp)
    80002ebc:	64a2                	ld	s1,8(sp)
    80002ebe:	6902                	ld	s2,0(sp)
    80002ec0:	6105                	addi	sp,sp,32
    80002ec2:	8082                	ret
    return -1;
    80002ec4:	557d                	li	a0,-1
    80002ec6:	bfcd                	j	80002eb8 <fetchaddr+0x3e>
    80002ec8:	557d                	li	a0,-1
    80002eca:	b7fd                	j	80002eb8 <fetchaddr+0x3e>

0000000080002ecc <fetchstr>:
{
    80002ecc:	7179                	addi	sp,sp,-48
    80002ece:	f406                	sd	ra,40(sp)
    80002ed0:	f022                	sd	s0,32(sp)
    80002ed2:	ec26                	sd	s1,24(sp)
    80002ed4:	e84a                	sd	s2,16(sp)
    80002ed6:	e44e                	sd	s3,8(sp)
    80002ed8:	1800                	addi	s0,sp,48
    80002eda:	892a                	mv	s2,a0
    80002edc:	84ae                	mv	s1,a1
    80002ede:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002ee0:	fffff097          	auipc	ra,0xfffff
    80002ee4:	acc080e7          	jalr	-1332(ra) # 800019ac <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002ee8:	86ce                	mv	a3,s3
    80002eea:	864a                	mv	a2,s2
    80002eec:	85a6                	mv	a1,s1
    80002eee:	6928                	ld	a0,80(a0)
    80002ef0:	fffff097          	auipc	ra,0xfffff
    80002ef4:	896080e7          	jalr	-1898(ra) # 80001786 <copyinstr>
    80002ef8:	00054e63          	bltz	a0,80002f14 <fetchstr+0x48>
  return strlen(buf);
    80002efc:	8526                	mv	a0,s1
    80002efe:	ffffe097          	auipc	ra,0xffffe
    80002f02:	f50080e7          	jalr	-176(ra) # 80000e4e <strlen>
}
    80002f06:	70a2                	ld	ra,40(sp)
    80002f08:	7402                	ld	s0,32(sp)
    80002f0a:	64e2                	ld	s1,24(sp)
    80002f0c:	6942                	ld	s2,16(sp)
    80002f0e:	69a2                	ld	s3,8(sp)
    80002f10:	6145                	addi	sp,sp,48
    80002f12:	8082                	ret
    return -1;
    80002f14:	557d                	li	a0,-1
    80002f16:	bfc5                	j	80002f06 <fetchstr+0x3a>

0000000080002f18 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002f18:	1101                	addi	sp,sp,-32
    80002f1a:	ec06                	sd	ra,24(sp)
    80002f1c:	e822                	sd	s0,16(sp)
    80002f1e:	e426                	sd	s1,8(sp)
    80002f20:	1000                	addi	s0,sp,32
    80002f22:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002f24:	00000097          	auipc	ra,0x0
    80002f28:	eee080e7          	jalr	-274(ra) # 80002e12 <argraw>
    80002f2c:	c088                	sw	a0,0(s1)
  return 0;
}
    80002f2e:	4501                	li	a0,0
    80002f30:	60e2                	ld	ra,24(sp)
    80002f32:	6442                	ld	s0,16(sp)
    80002f34:	64a2                	ld	s1,8(sp)
    80002f36:	6105                	addi	sp,sp,32
    80002f38:	8082                	ret

0000000080002f3a <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002f3a:	1101                	addi	sp,sp,-32
    80002f3c:	ec06                	sd	ra,24(sp)
    80002f3e:	e822                	sd	s0,16(sp)
    80002f40:	e426                	sd	s1,8(sp)
    80002f42:	1000                	addi	s0,sp,32
    80002f44:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002f46:	00000097          	auipc	ra,0x0
    80002f4a:	ecc080e7          	jalr	-308(ra) # 80002e12 <argraw>
    80002f4e:	e088                	sd	a0,0(s1)
  return 0;
}
    80002f50:	4501                	li	a0,0
    80002f52:	60e2                	ld	ra,24(sp)
    80002f54:	6442                	ld	s0,16(sp)
    80002f56:	64a2                	ld	s1,8(sp)
    80002f58:	6105                	addi	sp,sp,32
    80002f5a:	8082                	ret

0000000080002f5c <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002f5c:	7179                	addi	sp,sp,-48
    80002f5e:	f406                	sd	ra,40(sp)
    80002f60:	f022                	sd	s0,32(sp)
    80002f62:	ec26                	sd	s1,24(sp)
    80002f64:	e84a                	sd	s2,16(sp)
    80002f66:	1800                	addi	s0,sp,48
    80002f68:	84ae                	mv	s1,a1
    80002f6a:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002f6c:	fd840593          	addi	a1,s0,-40
    80002f70:	00000097          	auipc	ra,0x0
    80002f74:	fca080e7          	jalr	-54(ra) # 80002f3a <argaddr>
  return fetchstr(addr, buf, max);
    80002f78:	864a                	mv	a2,s2
    80002f7a:	85a6                	mv	a1,s1
    80002f7c:	fd843503          	ld	a0,-40(s0)
    80002f80:	00000097          	auipc	ra,0x0
    80002f84:	f4c080e7          	jalr	-180(ra) # 80002ecc <fetchstr>
}
    80002f88:	70a2                	ld	ra,40(sp)
    80002f8a:	7402                	ld	s0,32(sp)
    80002f8c:	64e2                	ld	s1,24(sp)
    80002f8e:	6942                	ld	s2,16(sp)
    80002f90:	6145                	addi	sp,sp,48
    80002f92:	8082                	ret

0000000080002f94 <syscall>:
	static char *systemCallsNames[]={"","fork","exit","wait","pipe","read","kill","exec","fstat","chdir","dup","getpid","sbrk","sleep","uptime","open","write","mknod","unlink","link","mkdir","close","trace", "waitx", "setpriority"};	
// Stores the number of arguments corresponsing to each system call in the above order of system calls.	
int systemCallArgs[]={0, 0, 1, 1, 1, 3, 1, 2, 2, 1, 1, 0, 1, 1, 0, 2, 3, 3, 1, 2, 1, 1, 1, 3, 2};
void
syscall(void)
{
    80002f94:	7139                	addi	sp,sp,-64
    80002f96:	fc06                	sd	ra,56(sp)
    80002f98:	f822                	sd	s0,48(sp)
    80002f9a:	f426                	sd	s1,40(sp)
    80002f9c:	f04a                	sd	s2,32(sp)
    80002f9e:	ec4e                	sd	s3,24(sp)
    80002fa0:	e852                	sd	s4,16(sp)
    80002fa2:	e456                	sd	s5,8(sp)
    80002fa4:	e05a                	sd	s6,0(sp)
    80002fa6:	0080                	addi	s0,sp,64
  int num;
  struct proc *p = myproc();
    80002fa8:	fffff097          	auipc	ra,0xfffff
    80002fac:	a04080e7          	jalr	-1532(ra) # 800019ac <myproc>
    80002fb0:	892a                	mv	s2,a0

  num = p->trapframe->a7;
    80002fb2:	6d24                	ld	s1,88(a0)
    80002fb4:	74dc                	ld	a5,168(s1)
    80002fb6:	0007899b          	sext.w	s3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002fba:	37fd                	addiw	a5,a5,-1
    80002fbc:	475d                	li	a4,23
    80002fbe:	0ef76763          	bltu	a4,a5,800030ac <syscall+0x118>
    80002fc2:	00399713          	slli	a4,s3,0x3
    80002fc6:	00005797          	auipc	a5,0x5
    80002fca:	5ca78793          	addi	a5,a5,1482 # 80008590 <syscalls>
    80002fce:	97ba                	add	a5,a5,a4
    80002fd0:	639c                	ld	a5,0(a5)
    80002fd2:	cfe9                	beqz	a5,800030ac <syscall+0x118>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002fd4:	9782                	jalr	a5
    80002fd6:	f8a8                	sd	a0,112(s1)
      if((p->mask>>num)&1){	
    80002fd8:	16892483          	lw	s1,360(s2)
    80002fdc:	4134d4bb          	sraw	s1,s1,s3
    80002fe0:	8885                	andi	s1,s1,1
    80002fe2:	c4f5                	beqz	s1,800030ce <syscall+0x13a>
      printf("%d: syscall %s (", p->pid, systemCallsNames[num]);	
    80002fe4:	00399713          	slli	a4,s3,0x3
    80002fe8:	00005797          	auipc	a5,0x5
    80002fec:	5a878793          	addi	a5,a5,1448 # 80008590 <syscalls>
    80002ff0:	97ba                	add	a5,a5,a4
    80002ff2:	67f0                	ld	a2,200(a5)
    80002ff4:	03092583          	lw	a1,48(s2)
    80002ff8:	00005517          	auipc	a0,0x5
    80002ffc:	46850513          	addi	a0,a0,1128 # 80008460 <states.0+0x150>
    80003000:	ffffd097          	auipc	ra,0xffffd
    80003004:	58a080e7          	jalr	1418(ra) # 8000058a <printf>
      int numberOfArguments = systemCallArgs[num];	
    80003008:	098a                	slli	s3,s3,0x2
    8000300a:	00006797          	auipc	a5,0x6
    8000300e:	a9e78793          	addi	a5,a5,-1378 # 80008aa8 <systemCallArgs>
    80003012:	97ce                	add	a5,a5,s3
    80003014:	0007a983          	lw	s3,0(a5)
      if (numberOfArguments > 1)	
    80003018:	4785                	li	a5,1
    8000301a:	0337d763          	bge	a5,s3,80003048 <syscall+0xb4>
        printf("%d ", p->storedVal);	
    8000301e:	17093583          	ld	a1,368(s2)
    80003022:	00005517          	auipc	a0,0x5
    80003026:	45650513          	addi	a0,a0,1110 # 80008478 <states.0+0x168>
    8000302a:	ffffd097          	auipc	ra,0xffffd
    8000302e:	560080e7          	jalr	1376(ra) # 8000058a <printf>
      else 	
        printf("%d", p->storedVal);	
      for (int i = 1; i < numberOfArguments; i++) {	
        if (i == numberOfArguments - 1) printf("%d", argraw(i));	
    80003032:	fff98a1b          	addiw	s4,s3,-1
        else printf("%d ", argraw(i));	
    80003036:	00005a97          	auipc	s5,0x5
    8000303a:	442a8a93          	addi	s5,s5,1090 # 80008478 <states.0+0x168>
        if (i == numberOfArguments - 1) printf("%d", argraw(i));	
    8000303e:	00005b17          	auipc	s6,0x5
    80003042:	442b0b13          	addi	s6,s6,1090 # 80008480 <states.0+0x170>
    80003046:	a0a9                	j	80003090 <syscall+0xfc>
        printf("%d", p->storedVal);	
    80003048:	17093583          	ld	a1,368(s2)
    8000304c:	00005517          	auipc	a0,0x5
    80003050:	43450513          	addi	a0,a0,1076 # 80008480 <states.0+0x170>
    80003054:	ffffd097          	auipc	ra,0xffffd
    80003058:	536080e7          	jalr	1334(ra) # 8000058a <printf>
      }	
      printf(") -> %d\n", p->trapframe->a0);	
    8000305c:	05893783          	ld	a5,88(s2)
    80003060:	7bac                	ld	a1,112(a5)
    80003062:	00005517          	auipc	a0,0x5
    80003066:	42650513          	addi	a0,a0,1062 # 80008488 <states.0+0x178>
    8000306a:	ffffd097          	auipc	ra,0xffffd
    8000306e:	520080e7          	jalr	1312(ra) # 8000058a <printf>
    80003072:	a8b1                	j	800030ce <syscall+0x13a>
        if (i == numberOfArguments - 1) printf("%d", argraw(i));	
    80003074:	8526                	mv	a0,s1
    80003076:	00000097          	auipc	ra,0x0
    8000307a:	d9c080e7          	jalr	-612(ra) # 80002e12 <argraw>
    8000307e:	85aa                	mv	a1,a0
    80003080:	855a                	mv	a0,s6
    80003082:	ffffd097          	auipc	ra,0xffffd
    80003086:	508080e7          	jalr	1288(ra) # 8000058a <printf>
      for (int i = 1; i < numberOfArguments; i++) {	
    8000308a:	2485                	addiw	s1,s1,1
    8000308c:	fc9988e3          	beq	s3,s1,8000305c <syscall+0xc8>
        if (i == numberOfArguments - 1) printf("%d", argraw(i));	
    80003090:	fe9a02e3          	beq	s4,s1,80003074 <syscall+0xe0>
        else printf("%d ", argraw(i));	
    80003094:	8526                	mv	a0,s1
    80003096:	00000097          	auipc	ra,0x0
    8000309a:	d7c080e7          	jalr	-644(ra) # 80002e12 <argraw>
    8000309e:	85aa                	mv	a1,a0
    800030a0:	8556                	mv	a0,s5
    800030a2:	ffffd097          	auipc	ra,0xffffd
    800030a6:	4e8080e7          	jalr	1256(ra) # 8000058a <printf>
    800030aa:	b7c5                	j	8000308a <syscall+0xf6>
    }
    
  } else {
    printf("%d %s: unknown sys call %d\n",
    800030ac:	86ce                	mv	a3,s3
    800030ae:	15890613          	addi	a2,s2,344
    800030b2:	03092583          	lw	a1,48(s2)
    800030b6:	00005517          	auipc	a0,0x5
    800030ba:	3e250513          	addi	a0,a0,994 # 80008498 <states.0+0x188>
    800030be:	ffffd097          	auipc	ra,0xffffd
    800030c2:	4cc080e7          	jalr	1228(ra) # 8000058a <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    800030c6:	05893783          	ld	a5,88(s2)
    800030ca:	577d                	li	a4,-1
    800030cc:	fbb8                	sd	a4,112(a5)
  }
}
    800030ce:	70e2                	ld	ra,56(sp)
    800030d0:	7442                	ld	s0,48(sp)
    800030d2:	74a2                	ld	s1,40(sp)
    800030d4:	7902                	ld	s2,32(sp)
    800030d6:	69e2                	ld	s3,24(sp)
    800030d8:	6a42                	ld	s4,16(sp)
    800030da:	6aa2                	ld	s5,8(sp)
    800030dc:	6b02                	ld	s6,0(sp)
    800030de:	6121                	addi	sp,sp,64
    800030e0:	8082                	ret

00000000800030e2 <sys_strace>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_strace(void)
{
    800030e2:	1101                	addi	sp,sp,-32
    800030e4:	ec06                	sd	ra,24(sp)
    800030e6:	e822                	sd	s0,16(sp)
    800030e8:	1000                	addi	s0,sp,32
  int trace_mask;

  argint(0, &trace_mask);
    800030ea:	fec40593          	addi	a1,s0,-20
    800030ee:	4501                	li	a0,0
    800030f0:	00000097          	auipc	ra,0x0
    800030f4:	e28080e7          	jalr	-472(ra) # 80002f18 <argint>
  if (trace_mask < 0)
    800030f8:	fec42783          	lw	a5,-20(s0)
    return -1;
    800030fc:	557d                	li	a0,-1
  if (trace_mask < 0)
    800030fe:	0007cb63          	bltz	a5,80003114 <sys_strace+0x32>

  struct proc *p = myproc();
    80003102:	fffff097          	auipc	ra,0xfffff
    80003106:	8aa080e7          	jalr	-1878(ra) # 800019ac <myproc>
  p->mask = trace_mask;
    8000310a:	fec42783          	lw	a5,-20(s0)
    8000310e:	16f52423          	sw	a5,360(a0)

  return 0;
    80003112:	4501                	li	a0,0
}
    80003114:	60e2                	ld	ra,24(sp)
    80003116:	6442                	ld	s0,16(sp)
    80003118:	6105                	addi	sp,sp,32
    8000311a:	8082                	ret

000000008000311c <sys_waitx>:
uint64	
sys_waitx(void)	
{	
    8000311c:	7139                	addi	sp,sp,-64
    8000311e:	fc06                	sd	ra,56(sp)
    80003120:	f822                	sd	s0,48(sp)
    80003122:	f426                	sd	s1,40(sp)
    80003124:	f04a                	sd	s2,32(sp)
    80003126:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;	
  uint wtime, rtime;	
  if(argaddr(0, &addr) < 0)	
    80003128:	fd840593          	addi	a1,s0,-40
    8000312c:	4501                	li	a0,0
    8000312e:	00000097          	auipc	ra,0x0
    80003132:	e0c080e7          	jalr	-500(ra) # 80002f3a <argaddr>
    return -1;	
    80003136:	57fd                	li	a5,-1
  if(argaddr(0, &addr) < 0)	
    80003138:	08054063          	bltz	a0,800031b8 <sys_waitx+0x9c>
  if(argaddr(1, &addr1) < 0) // user virtual memory	
    8000313c:	fd040593          	addi	a1,s0,-48
    80003140:	4505                	li	a0,1
    80003142:	00000097          	auipc	ra,0x0
    80003146:	df8080e7          	jalr	-520(ra) # 80002f3a <argaddr>
    return -1;	
    8000314a:	57fd                	li	a5,-1
  if(argaddr(1, &addr1) < 0) // user virtual memory	
    8000314c:	06054663          	bltz	a0,800031b8 <sys_waitx+0x9c>
  if(argaddr(2, &addr2) < 0)	
    80003150:	fc840593          	addi	a1,s0,-56
    80003154:	4509                	li	a0,2
    80003156:	00000097          	auipc	ra,0x0
    8000315a:	de4080e7          	jalr	-540(ra) # 80002f3a <argaddr>
    return -1;	
    8000315e:	57fd                	li	a5,-1
  if(argaddr(2, &addr2) < 0)	
    80003160:	04054c63          	bltz	a0,800031b8 <sys_waitx+0x9c>
  int ret = waitx(addr, &wtime, &rtime);	
    80003164:	fc040613          	addi	a2,s0,-64
    80003168:	fc440593          	addi	a1,s0,-60
    8000316c:	fd843503          	ld	a0,-40(s0)
    80003170:	fffff097          	auipc	ra,0xfffff
    80003174:	12e080e7          	jalr	302(ra) # 8000229e <waitx>
    80003178:	892a                	mv	s2,a0
  struct proc* p = myproc();	
    8000317a:	fffff097          	auipc	ra,0xfffff
    8000317e:	832080e7          	jalr	-1998(ra) # 800019ac <myproc>
    80003182:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1,(char*)&wtime, sizeof(int)) < 0)	
    80003184:	4691                	li	a3,4
    80003186:	fc440613          	addi	a2,s0,-60
    8000318a:	fd043583          	ld	a1,-48(s0)
    8000318e:	6928                	ld	a0,80(a0)
    80003190:	ffffe097          	auipc	ra,0xffffe
    80003194:	4dc080e7          	jalr	1244(ra) # 8000166c <copyout>
    return -1;	
    80003198:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1,(char*)&wtime, sizeof(int)) < 0)	
    8000319a:	00054f63          	bltz	a0,800031b8 <sys_waitx+0x9c>
  if (copyout(p->pagetable, addr2,(char*)&rtime, sizeof(int)) < 0)	
    8000319e:	4691                	li	a3,4
    800031a0:	fc040613          	addi	a2,s0,-64
    800031a4:	fc843583          	ld	a1,-56(s0)
    800031a8:	68a8                	ld	a0,80(s1)
    800031aa:	ffffe097          	auipc	ra,0xffffe
    800031ae:	4c2080e7          	jalr	1218(ra) # 8000166c <copyout>
    800031b2:	00054a63          	bltz	a0,800031c6 <sys_waitx+0xaa>
    return -1;	
  return ret;	
    800031b6:	87ca                	mv	a5,s2
}	
    800031b8:	853e                	mv	a0,a5
    800031ba:	70e2                	ld	ra,56(sp)
    800031bc:	7442                	ld	s0,48(sp)
    800031be:	74a2                	ld	s1,40(sp)
    800031c0:	7902                	ld	s2,32(sp)
    800031c2:	6121                	addi	sp,sp,64
    800031c4:	8082                	ret
    return -1;	
    800031c6:	57fd                	li	a5,-1
    800031c8:	bfc5                	j	800031b8 <sys_waitx+0x9c>

00000000800031ca <sys_set_priority>:
uint64	
sys_set_priority(void)	
{	
    800031ca:	1101                	addi	sp,sp,-32
    800031cc:	ec06                	sd	ra,24(sp)
    800031ce:	e822                	sd	s0,16(sp)
    800031d0:	1000                	addi	s0,sp,32
  int priority, pid;	
  if (argint(0, &priority) < 0)	
    800031d2:	fec40593          	addi	a1,s0,-20
    800031d6:	4501                	li	a0,0
    800031d8:	00000097          	auipc	ra,0x0
    800031dc:	d40080e7          	jalr	-704(ra) # 80002f18 <argint>
    return -1;	
    800031e0:	57fd                	li	a5,-1
  if (argint(0, &priority) < 0)	
    800031e2:	02054563          	bltz	a0,8000320c <sys_set_priority+0x42>
  if (argint(1, &pid) < 0)	
    800031e6:	fe840593          	addi	a1,s0,-24
    800031ea:	4505                	li	a0,1
    800031ec:	00000097          	auipc	ra,0x0
    800031f0:	d2c080e7          	jalr	-724(ra) # 80002f18 <argint>
    return -1;	
    800031f4:	57fd                	li	a5,-1
  if (argint(1, &pid) < 0)	
    800031f6:	00054b63          	bltz	a0,8000320c <sys_set_priority+0x42>
  return set_priority(priority, pid);	
    800031fa:	fe842583          	lw	a1,-24(s0)
    800031fe:	fec42503          	lw	a0,-20(s0)
    80003202:	fffff097          	auipc	ra,0xfffff
    80003206:	d78080e7          	jalr	-648(ra) # 80001f7a <set_priority>
    8000320a:	87aa                	mv	a5,a0
}
    8000320c:	853e                	mv	a0,a5
    8000320e:	60e2                	ld	ra,24(sp)
    80003210:	6442                	ld	s0,16(sp)
    80003212:	6105                	addi	sp,sp,32
    80003214:	8082                	ret

0000000080003216 <sys_exit>:
uint64
sys_exit(void)
{
    80003216:	1101                	addi	sp,sp,-32
    80003218:	ec06                	sd	ra,24(sp)
    8000321a:	e822                	sd	s0,16(sp)
    8000321c:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    8000321e:	fec40593          	addi	a1,s0,-20
    80003222:	4501                	li	a0,0
    80003224:	00000097          	auipc	ra,0x0
    80003228:	cf4080e7          	jalr	-780(ra) # 80002f18 <argint>
  exit(n);
    8000322c:	fec42503          	lw	a0,-20(s0)
    80003230:	fffff097          	auipc	ra,0xfffff
    80003234:	28a080e7          	jalr	650(ra) # 800024ba <exit>
  return 0;  // not reached
}
    80003238:	4501                	li	a0,0
    8000323a:	60e2                	ld	ra,24(sp)
    8000323c:	6442                	ld	s0,16(sp)
    8000323e:	6105                	addi	sp,sp,32
    80003240:	8082                	ret

0000000080003242 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003242:	1141                	addi	sp,sp,-16
    80003244:	e406                	sd	ra,8(sp)
    80003246:	e022                	sd	s0,0(sp)
    80003248:	0800                	addi	s0,sp,16
  return myproc()->pid;
    8000324a:	ffffe097          	auipc	ra,0xffffe
    8000324e:	762080e7          	jalr	1890(ra) # 800019ac <myproc>
}
    80003252:	5908                	lw	a0,48(a0)
    80003254:	60a2                	ld	ra,8(sp)
    80003256:	6402                	ld	s0,0(sp)
    80003258:	0141                	addi	sp,sp,16
    8000325a:	8082                	ret

000000008000325c <sys_fork>:

uint64
sys_fork(void)
{
    8000325c:	1141                	addi	sp,sp,-16
    8000325e:	e406                	sd	ra,8(sp)
    80003260:	e022                	sd	s0,0(sp)
    80003262:	0800                	addi	s0,sp,16
  return fork();
    80003264:	fffff097          	auipc	ra,0xfffff
    80003268:	b36080e7          	jalr	-1226(ra) # 80001d9a <fork>
}
    8000326c:	60a2                	ld	ra,8(sp)
    8000326e:	6402                	ld	s0,0(sp)
    80003270:	0141                	addi	sp,sp,16
    80003272:	8082                	ret

0000000080003274 <sys_wait>:

uint64
sys_wait(void)
{
    80003274:	1101                	addi	sp,sp,-32
    80003276:	ec06                	sd	ra,24(sp)
    80003278:	e822                	sd	s0,16(sp)
    8000327a:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    8000327c:	fe840593          	addi	a1,s0,-24
    80003280:	4501                	li	a0,0
    80003282:	00000097          	auipc	ra,0x0
    80003286:	cb8080e7          	jalr	-840(ra) # 80002f3a <argaddr>
  return wait(p);
    8000328a:	fe843503          	ld	a0,-24(s0)
    8000328e:	fffff097          	auipc	ra,0xfffff
    80003292:	3de080e7          	jalr	990(ra) # 8000266c <wait>
}
    80003296:	60e2                	ld	ra,24(sp)
    80003298:	6442                	ld	s0,16(sp)
    8000329a:	6105                	addi	sp,sp,32
    8000329c:	8082                	ret

000000008000329e <sys_sbrk>:

uint64
sys_sbrk(void)
{
    8000329e:	7179                	addi	sp,sp,-48
    800032a0:	f406                	sd	ra,40(sp)
    800032a2:	f022                	sd	s0,32(sp)
    800032a4:	ec26                	sd	s1,24(sp)
    800032a6:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    800032a8:	fdc40593          	addi	a1,s0,-36
    800032ac:	4501                	li	a0,0
    800032ae:	00000097          	auipc	ra,0x0
    800032b2:	c6a080e7          	jalr	-918(ra) # 80002f18 <argint>
  addr = myproc()->sz;
    800032b6:	ffffe097          	auipc	ra,0xffffe
    800032ba:	6f6080e7          	jalr	1782(ra) # 800019ac <myproc>
    800032be:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    800032c0:	fdc42503          	lw	a0,-36(s0)
    800032c4:	fffff097          	auipc	ra,0xfffff
    800032c8:	a7a080e7          	jalr	-1414(ra) # 80001d3e <growproc>
    800032cc:	00054863          	bltz	a0,800032dc <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    800032d0:	8526                	mv	a0,s1
    800032d2:	70a2                	ld	ra,40(sp)
    800032d4:	7402                	ld	s0,32(sp)
    800032d6:	64e2                	ld	s1,24(sp)
    800032d8:	6145                	addi	sp,sp,48
    800032da:	8082                	ret
    return -1;
    800032dc:	54fd                	li	s1,-1
    800032de:	bfcd                	j	800032d0 <sys_sbrk+0x32>

00000000800032e0 <sys_sleep>:

uint64
sys_sleep(void)
{
    800032e0:	7139                	addi	sp,sp,-64
    800032e2:	fc06                	sd	ra,56(sp)
    800032e4:	f822                	sd	s0,48(sp)
    800032e6:	f426                	sd	s1,40(sp)
    800032e8:	f04a                	sd	s2,32(sp)
    800032ea:	ec4e                	sd	s3,24(sp)
    800032ec:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    800032ee:	fcc40593          	addi	a1,s0,-52
    800032f2:	4501                	li	a0,0
    800032f4:	00000097          	auipc	ra,0x0
    800032f8:	c24080e7          	jalr	-988(ra) # 80002f18 <argint>
  acquire(&tickslock);
    800032fc:	00015517          	auipc	a0,0x15
    80003300:	90450513          	addi	a0,a0,-1788 # 80017c00 <tickslock>
    80003304:	ffffe097          	auipc	ra,0xffffe
    80003308:	8d2080e7          	jalr	-1838(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    8000330c:	00006917          	auipc	s2,0x6
    80003310:	85492903          	lw	s2,-1964(s2) # 80008b60 <ticks>
  while(ticks - ticks0 < n){
    80003314:	fcc42783          	lw	a5,-52(s0)
    80003318:	cf9d                	beqz	a5,80003356 <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    8000331a:	00015997          	auipc	s3,0x15
    8000331e:	8e698993          	addi	s3,s3,-1818 # 80017c00 <tickslock>
    80003322:	00006497          	auipc	s1,0x6
    80003326:	83e48493          	addi	s1,s1,-1986 # 80008b60 <ticks>
    if(killed(myproc())){
    8000332a:	ffffe097          	auipc	ra,0xffffe
    8000332e:	682080e7          	jalr	1666(ra) # 800019ac <myproc>
    80003332:	fffff097          	auipc	ra,0xfffff
    80003336:	308080e7          	jalr	776(ra) # 8000263a <killed>
    8000333a:	ed15                	bnez	a0,80003376 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    8000333c:	85ce                	mv	a1,s3
    8000333e:	8526                	mv	a0,s1
    80003340:	fffff097          	auipc	ra,0xfffff
    80003344:	efa080e7          	jalr	-262(ra) # 8000223a <sleep>
  while(ticks - ticks0 < n){
    80003348:	409c                	lw	a5,0(s1)
    8000334a:	412787bb          	subw	a5,a5,s2
    8000334e:	fcc42703          	lw	a4,-52(s0)
    80003352:	fce7ece3          	bltu	a5,a4,8000332a <sys_sleep+0x4a>
  }
  release(&tickslock);
    80003356:	00015517          	auipc	a0,0x15
    8000335a:	8aa50513          	addi	a0,a0,-1878 # 80017c00 <tickslock>
    8000335e:	ffffe097          	auipc	ra,0xffffe
    80003362:	92c080e7          	jalr	-1748(ra) # 80000c8a <release>
  return 0;
    80003366:	4501                	li	a0,0
}
    80003368:	70e2                	ld	ra,56(sp)
    8000336a:	7442                	ld	s0,48(sp)
    8000336c:	74a2                	ld	s1,40(sp)
    8000336e:	7902                	ld	s2,32(sp)
    80003370:	69e2                	ld	s3,24(sp)
    80003372:	6121                	addi	sp,sp,64
    80003374:	8082                	ret
      release(&tickslock);
    80003376:	00015517          	auipc	a0,0x15
    8000337a:	88a50513          	addi	a0,a0,-1910 # 80017c00 <tickslock>
    8000337e:	ffffe097          	auipc	ra,0xffffe
    80003382:	90c080e7          	jalr	-1780(ra) # 80000c8a <release>
      return -1;
    80003386:	557d                	li	a0,-1
    80003388:	b7c5                	j	80003368 <sys_sleep+0x88>

000000008000338a <sys_kill>:

uint64
sys_kill(void)
{
    8000338a:	1101                	addi	sp,sp,-32
    8000338c:	ec06                	sd	ra,24(sp)
    8000338e:	e822                	sd	s0,16(sp)
    80003390:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80003392:	fec40593          	addi	a1,s0,-20
    80003396:	4501                	li	a0,0
    80003398:	00000097          	auipc	ra,0x0
    8000339c:	b80080e7          	jalr	-1152(ra) # 80002f18 <argint>
  return kill(pid);
    800033a0:	fec42503          	lw	a0,-20(s0)
    800033a4:	fffff097          	auipc	ra,0xfffff
    800033a8:	1f8080e7          	jalr	504(ra) # 8000259c <kill>
}
    800033ac:	60e2                	ld	ra,24(sp)
    800033ae:	6442                	ld	s0,16(sp)
    800033b0:	6105                	addi	sp,sp,32
    800033b2:	8082                	ret

00000000800033b4 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800033b4:	1101                	addi	sp,sp,-32
    800033b6:	ec06                	sd	ra,24(sp)
    800033b8:	e822                	sd	s0,16(sp)
    800033ba:	e426                	sd	s1,8(sp)
    800033bc:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800033be:	00015517          	auipc	a0,0x15
    800033c2:	84250513          	addi	a0,a0,-1982 # 80017c00 <tickslock>
    800033c6:	ffffe097          	auipc	ra,0xffffe
    800033ca:	810080e7          	jalr	-2032(ra) # 80000bd6 <acquire>
  xticks = ticks;
    800033ce:	00005497          	auipc	s1,0x5
    800033d2:	7924a483          	lw	s1,1938(s1) # 80008b60 <ticks>
  release(&tickslock);
    800033d6:	00015517          	auipc	a0,0x15
    800033da:	82a50513          	addi	a0,a0,-2006 # 80017c00 <tickslock>
    800033de:	ffffe097          	auipc	ra,0xffffe
    800033e2:	8ac080e7          	jalr	-1876(ra) # 80000c8a <release>
  return xticks;
}
    800033e6:	02049513          	slli	a0,s1,0x20
    800033ea:	9101                	srli	a0,a0,0x20
    800033ec:	60e2                	ld	ra,24(sp)
    800033ee:	6442                	ld	s0,16(sp)
    800033f0:	64a2                	ld	s1,8(sp)
    800033f2:	6105                	addi	sp,sp,32
    800033f4:	8082                	ret

00000000800033f6 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800033f6:	7179                	addi	sp,sp,-48
    800033f8:	f406                	sd	ra,40(sp)
    800033fa:	f022                	sd	s0,32(sp)
    800033fc:	ec26                	sd	s1,24(sp)
    800033fe:	e84a                	sd	s2,16(sp)
    80003400:	e44e                	sd	s3,8(sp)
    80003402:	e052                	sd	s4,0(sp)
    80003404:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003406:	00005597          	auipc	a1,0x5
    8000340a:	31a58593          	addi	a1,a1,794 # 80008720 <systemCallsNames+0xc8>
    8000340e:	00015517          	auipc	a0,0x15
    80003412:	80a50513          	addi	a0,a0,-2038 # 80017c18 <bcache>
    80003416:	ffffd097          	auipc	ra,0xffffd
    8000341a:	730080e7          	jalr	1840(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    8000341e:	0001c797          	auipc	a5,0x1c
    80003422:	7fa78793          	addi	a5,a5,2042 # 8001fc18 <bcache+0x8000>
    80003426:	0001d717          	auipc	a4,0x1d
    8000342a:	a5a70713          	addi	a4,a4,-1446 # 8001fe80 <bcache+0x8268>
    8000342e:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003432:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003436:	00014497          	auipc	s1,0x14
    8000343a:	7fa48493          	addi	s1,s1,2042 # 80017c30 <bcache+0x18>
    b->next = bcache.head.next;
    8000343e:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003440:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003442:	00005a17          	auipc	s4,0x5
    80003446:	2e6a0a13          	addi	s4,s4,742 # 80008728 <systemCallsNames+0xd0>
    b->next = bcache.head.next;
    8000344a:	2b893783          	ld	a5,696(s2)
    8000344e:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003450:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003454:	85d2                	mv	a1,s4
    80003456:	01048513          	addi	a0,s1,16
    8000345a:	00001097          	auipc	ra,0x1
    8000345e:	4c8080e7          	jalr	1224(ra) # 80004922 <initsleeplock>
    bcache.head.next->prev = b;
    80003462:	2b893783          	ld	a5,696(s2)
    80003466:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003468:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000346c:	45848493          	addi	s1,s1,1112
    80003470:	fd349de3          	bne	s1,s3,8000344a <binit+0x54>
  }
}
    80003474:	70a2                	ld	ra,40(sp)
    80003476:	7402                	ld	s0,32(sp)
    80003478:	64e2                	ld	s1,24(sp)
    8000347a:	6942                	ld	s2,16(sp)
    8000347c:	69a2                	ld	s3,8(sp)
    8000347e:	6a02                	ld	s4,0(sp)
    80003480:	6145                	addi	sp,sp,48
    80003482:	8082                	ret

0000000080003484 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003484:	7179                	addi	sp,sp,-48
    80003486:	f406                	sd	ra,40(sp)
    80003488:	f022                	sd	s0,32(sp)
    8000348a:	ec26                	sd	s1,24(sp)
    8000348c:	e84a                	sd	s2,16(sp)
    8000348e:	e44e                	sd	s3,8(sp)
    80003490:	1800                	addi	s0,sp,48
    80003492:	892a                	mv	s2,a0
    80003494:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80003496:	00014517          	auipc	a0,0x14
    8000349a:	78250513          	addi	a0,a0,1922 # 80017c18 <bcache>
    8000349e:	ffffd097          	auipc	ra,0xffffd
    800034a2:	738080e7          	jalr	1848(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800034a6:	0001d497          	auipc	s1,0x1d
    800034aa:	a2a4b483          	ld	s1,-1494(s1) # 8001fed0 <bcache+0x82b8>
    800034ae:	0001d797          	auipc	a5,0x1d
    800034b2:	9d278793          	addi	a5,a5,-1582 # 8001fe80 <bcache+0x8268>
    800034b6:	02f48f63          	beq	s1,a5,800034f4 <bread+0x70>
    800034ba:	873e                	mv	a4,a5
    800034bc:	a021                	j	800034c4 <bread+0x40>
    800034be:	68a4                	ld	s1,80(s1)
    800034c0:	02e48a63          	beq	s1,a4,800034f4 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800034c4:	449c                	lw	a5,8(s1)
    800034c6:	ff279ce3          	bne	a5,s2,800034be <bread+0x3a>
    800034ca:	44dc                	lw	a5,12(s1)
    800034cc:	ff3799e3          	bne	a5,s3,800034be <bread+0x3a>
      b->refcnt++;
    800034d0:	40bc                	lw	a5,64(s1)
    800034d2:	2785                	addiw	a5,a5,1
    800034d4:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800034d6:	00014517          	auipc	a0,0x14
    800034da:	74250513          	addi	a0,a0,1858 # 80017c18 <bcache>
    800034de:	ffffd097          	auipc	ra,0xffffd
    800034e2:	7ac080e7          	jalr	1964(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    800034e6:	01048513          	addi	a0,s1,16
    800034ea:	00001097          	auipc	ra,0x1
    800034ee:	472080e7          	jalr	1138(ra) # 8000495c <acquiresleep>
      return b;
    800034f2:	a8b9                	j	80003550 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800034f4:	0001d497          	auipc	s1,0x1d
    800034f8:	9d44b483          	ld	s1,-1580(s1) # 8001fec8 <bcache+0x82b0>
    800034fc:	0001d797          	auipc	a5,0x1d
    80003500:	98478793          	addi	a5,a5,-1660 # 8001fe80 <bcache+0x8268>
    80003504:	00f48863          	beq	s1,a5,80003514 <bread+0x90>
    80003508:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000350a:	40bc                	lw	a5,64(s1)
    8000350c:	cf81                	beqz	a5,80003524 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000350e:	64a4                	ld	s1,72(s1)
    80003510:	fee49de3          	bne	s1,a4,8000350a <bread+0x86>
  panic("bget: no buffers");
    80003514:	00005517          	auipc	a0,0x5
    80003518:	21c50513          	addi	a0,a0,540 # 80008730 <systemCallsNames+0xd8>
    8000351c:	ffffd097          	auipc	ra,0xffffd
    80003520:	024080e7          	jalr	36(ra) # 80000540 <panic>
      b->dev = dev;
    80003524:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003528:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    8000352c:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003530:	4785                	li	a5,1
    80003532:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003534:	00014517          	auipc	a0,0x14
    80003538:	6e450513          	addi	a0,a0,1764 # 80017c18 <bcache>
    8000353c:	ffffd097          	auipc	ra,0xffffd
    80003540:	74e080e7          	jalr	1870(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80003544:	01048513          	addi	a0,s1,16
    80003548:	00001097          	auipc	ra,0x1
    8000354c:	414080e7          	jalr	1044(ra) # 8000495c <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003550:	409c                	lw	a5,0(s1)
    80003552:	cb89                	beqz	a5,80003564 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003554:	8526                	mv	a0,s1
    80003556:	70a2                	ld	ra,40(sp)
    80003558:	7402                	ld	s0,32(sp)
    8000355a:	64e2                	ld	s1,24(sp)
    8000355c:	6942                	ld	s2,16(sp)
    8000355e:	69a2                	ld	s3,8(sp)
    80003560:	6145                	addi	sp,sp,48
    80003562:	8082                	ret
    virtio_disk_rw(b, 0);
    80003564:	4581                	li	a1,0
    80003566:	8526                	mv	a0,s1
    80003568:	00003097          	auipc	ra,0x3
    8000356c:	fda080e7          	jalr	-38(ra) # 80006542 <virtio_disk_rw>
    b->valid = 1;
    80003570:	4785                	li	a5,1
    80003572:	c09c                	sw	a5,0(s1)
  return b;
    80003574:	b7c5                	j	80003554 <bread+0xd0>

0000000080003576 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003576:	1101                	addi	sp,sp,-32
    80003578:	ec06                	sd	ra,24(sp)
    8000357a:	e822                	sd	s0,16(sp)
    8000357c:	e426                	sd	s1,8(sp)
    8000357e:	1000                	addi	s0,sp,32
    80003580:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003582:	0541                	addi	a0,a0,16
    80003584:	00001097          	auipc	ra,0x1
    80003588:	472080e7          	jalr	1138(ra) # 800049f6 <holdingsleep>
    8000358c:	cd01                	beqz	a0,800035a4 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000358e:	4585                	li	a1,1
    80003590:	8526                	mv	a0,s1
    80003592:	00003097          	auipc	ra,0x3
    80003596:	fb0080e7          	jalr	-80(ra) # 80006542 <virtio_disk_rw>
}
    8000359a:	60e2                	ld	ra,24(sp)
    8000359c:	6442                	ld	s0,16(sp)
    8000359e:	64a2                	ld	s1,8(sp)
    800035a0:	6105                	addi	sp,sp,32
    800035a2:	8082                	ret
    panic("bwrite");
    800035a4:	00005517          	auipc	a0,0x5
    800035a8:	1a450513          	addi	a0,a0,420 # 80008748 <systemCallsNames+0xf0>
    800035ac:	ffffd097          	auipc	ra,0xffffd
    800035b0:	f94080e7          	jalr	-108(ra) # 80000540 <panic>

00000000800035b4 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800035b4:	1101                	addi	sp,sp,-32
    800035b6:	ec06                	sd	ra,24(sp)
    800035b8:	e822                	sd	s0,16(sp)
    800035ba:	e426                	sd	s1,8(sp)
    800035bc:	e04a                	sd	s2,0(sp)
    800035be:	1000                	addi	s0,sp,32
    800035c0:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800035c2:	01050913          	addi	s2,a0,16
    800035c6:	854a                	mv	a0,s2
    800035c8:	00001097          	auipc	ra,0x1
    800035cc:	42e080e7          	jalr	1070(ra) # 800049f6 <holdingsleep>
    800035d0:	c92d                	beqz	a0,80003642 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800035d2:	854a                	mv	a0,s2
    800035d4:	00001097          	auipc	ra,0x1
    800035d8:	3de080e7          	jalr	990(ra) # 800049b2 <releasesleep>

  acquire(&bcache.lock);
    800035dc:	00014517          	auipc	a0,0x14
    800035e0:	63c50513          	addi	a0,a0,1596 # 80017c18 <bcache>
    800035e4:	ffffd097          	auipc	ra,0xffffd
    800035e8:	5f2080e7          	jalr	1522(ra) # 80000bd6 <acquire>
  b->refcnt--;
    800035ec:	40bc                	lw	a5,64(s1)
    800035ee:	37fd                	addiw	a5,a5,-1
    800035f0:	0007871b          	sext.w	a4,a5
    800035f4:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800035f6:	eb05                	bnez	a4,80003626 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800035f8:	68bc                	ld	a5,80(s1)
    800035fa:	64b8                	ld	a4,72(s1)
    800035fc:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800035fe:	64bc                	ld	a5,72(s1)
    80003600:	68b8                	ld	a4,80(s1)
    80003602:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003604:	0001c797          	auipc	a5,0x1c
    80003608:	61478793          	addi	a5,a5,1556 # 8001fc18 <bcache+0x8000>
    8000360c:	2b87b703          	ld	a4,696(a5)
    80003610:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003612:	0001d717          	auipc	a4,0x1d
    80003616:	86e70713          	addi	a4,a4,-1938 # 8001fe80 <bcache+0x8268>
    8000361a:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000361c:	2b87b703          	ld	a4,696(a5)
    80003620:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003622:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003626:	00014517          	auipc	a0,0x14
    8000362a:	5f250513          	addi	a0,a0,1522 # 80017c18 <bcache>
    8000362e:	ffffd097          	auipc	ra,0xffffd
    80003632:	65c080e7          	jalr	1628(ra) # 80000c8a <release>
}
    80003636:	60e2                	ld	ra,24(sp)
    80003638:	6442                	ld	s0,16(sp)
    8000363a:	64a2                	ld	s1,8(sp)
    8000363c:	6902                	ld	s2,0(sp)
    8000363e:	6105                	addi	sp,sp,32
    80003640:	8082                	ret
    panic("brelse");
    80003642:	00005517          	auipc	a0,0x5
    80003646:	10e50513          	addi	a0,a0,270 # 80008750 <systemCallsNames+0xf8>
    8000364a:	ffffd097          	auipc	ra,0xffffd
    8000364e:	ef6080e7          	jalr	-266(ra) # 80000540 <panic>

0000000080003652 <bpin>:

void
bpin(struct buf *b) {
    80003652:	1101                	addi	sp,sp,-32
    80003654:	ec06                	sd	ra,24(sp)
    80003656:	e822                	sd	s0,16(sp)
    80003658:	e426                	sd	s1,8(sp)
    8000365a:	1000                	addi	s0,sp,32
    8000365c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000365e:	00014517          	auipc	a0,0x14
    80003662:	5ba50513          	addi	a0,a0,1466 # 80017c18 <bcache>
    80003666:	ffffd097          	auipc	ra,0xffffd
    8000366a:	570080e7          	jalr	1392(ra) # 80000bd6 <acquire>
  b->refcnt++;
    8000366e:	40bc                	lw	a5,64(s1)
    80003670:	2785                	addiw	a5,a5,1
    80003672:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003674:	00014517          	auipc	a0,0x14
    80003678:	5a450513          	addi	a0,a0,1444 # 80017c18 <bcache>
    8000367c:	ffffd097          	auipc	ra,0xffffd
    80003680:	60e080e7          	jalr	1550(ra) # 80000c8a <release>
}
    80003684:	60e2                	ld	ra,24(sp)
    80003686:	6442                	ld	s0,16(sp)
    80003688:	64a2                	ld	s1,8(sp)
    8000368a:	6105                	addi	sp,sp,32
    8000368c:	8082                	ret

000000008000368e <bunpin>:

void
bunpin(struct buf *b) {
    8000368e:	1101                	addi	sp,sp,-32
    80003690:	ec06                	sd	ra,24(sp)
    80003692:	e822                	sd	s0,16(sp)
    80003694:	e426                	sd	s1,8(sp)
    80003696:	1000                	addi	s0,sp,32
    80003698:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000369a:	00014517          	auipc	a0,0x14
    8000369e:	57e50513          	addi	a0,a0,1406 # 80017c18 <bcache>
    800036a2:	ffffd097          	auipc	ra,0xffffd
    800036a6:	534080e7          	jalr	1332(ra) # 80000bd6 <acquire>
  b->refcnt--;
    800036aa:	40bc                	lw	a5,64(s1)
    800036ac:	37fd                	addiw	a5,a5,-1
    800036ae:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800036b0:	00014517          	auipc	a0,0x14
    800036b4:	56850513          	addi	a0,a0,1384 # 80017c18 <bcache>
    800036b8:	ffffd097          	auipc	ra,0xffffd
    800036bc:	5d2080e7          	jalr	1490(ra) # 80000c8a <release>
}
    800036c0:	60e2                	ld	ra,24(sp)
    800036c2:	6442                	ld	s0,16(sp)
    800036c4:	64a2                	ld	s1,8(sp)
    800036c6:	6105                	addi	sp,sp,32
    800036c8:	8082                	ret

00000000800036ca <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800036ca:	1101                	addi	sp,sp,-32
    800036cc:	ec06                	sd	ra,24(sp)
    800036ce:	e822                	sd	s0,16(sp)
    800036d0:	e426                	sd	s1,8(sp)
    800036d2:	e04a                	sd	s2,0(sp)
    800036d4:	1000                	addi	s0,sp,32
    800036d6:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800036d8:	00d5d59b          	srliw	a1,a1,0xd
    800036dc:	0001d797          	auipc	a5,0x1d
    800036e0:	c187a783          	lw	a5,-1000(a5) # 800202f4 <sb+0x1c>
    800036e4:	9dbd                	addw	a1,a1,a5
    800036e6:	00000097          	auipc	ra,0x0
    800036ea:	d9e080e7          	jalr	-610(ra) # 80003484 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800036ee:	0074f713          	andi	a4,s1,7
    800036f2:	4785                	li	a5,1
    800036f4:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800036f8:	14ce                	slli	s1,s1,0x33
    800036fa:	90d9                	srli	s1,s1,0x36
    800036fc:	00950733          	add	a4,a0,s1
    80003700:	05874703          	lbu	a4,88(a4)
    80003704:	00e7f6b3          	and	a3,a5,a4
    80003708:	c69d                	beqz	a3,80003736 <bfree+0x6c>
    8000370a:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000370c:	94aa                	add	s1,s1,a0
    8000370e:	fff7c793          	not	a5,a5
    80003712:	8f7d                	and	a4,a4,a5
    80003714:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    80003718:	00001097          	auipc	ra,0x1
    8000371c:	126080e7          	jalr	294(ra) # 8000483e <log_write>
  brelse(bp);
    80003720:	854a                	mv	a0,s2
    80003722:	00000097          	auipc	ra,0x0
    80003726:	e92080e7          	jalr	-366(ra) # 800035b4 <brelse>
}
    8000372a:	60e2                	ld	ra,24(sp)
    8000372c:	6442                	ld	s0,16(sp)
    8000372e:	64a2                	ld	s1,8(sp)
    80003730:	6902                	ld	s2,0(sp)
    80003732:	6105                	addi	sp,sp,32
    80003734:	8082                	ret
    panic("freeing free block");
    80003736:	00005517          	auipc	a0,0x5
    8000373a:	02250513          	addi	a0,a0,34 # 80008758 <systemCallsNames+0x100>
    8000373e:	ffffd097          	auipc	ra,0xffffd
    80003742:	e02080e7          	jalr	-510(ra) # 80000540 <panic>

0000000080003746 <balloc>:
{
    80003746:	711d                	addi	sp,sp,-96
    80003748:	ec86                	sd	ra,88(sp)
    8000374a:	e8a2                	sd	s0,80(sp)
    8000374c:	e4a6                	sd	s1,72(sp)
    8000374e:	e0ca                	sd	s2,64(sp)
    80003750:	fc4e                	sd	s3,56(sp)
    80003752:	f852                	sd	s4,48(sp)
    80003754:	f456                	sd	s5,40(sp)
    80003756:	f05a                	sd	s6,32(sp)
    80003758:	ec5e                	sd	s7,24(sp)
    8000375a:	e862                	sd	s8,16(sp)
    8000375c:	e466                	sd	s9,8(sp)
    8000375e:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003760:	0001d797          	auipc	a5,0x1d
    80003764:	b7c7a783          	lw	a5,-1156(a5) # 800202dc <sb+0x4>
    80003768:	cff5                	beqz	a5,80003864 <balloc+0x11e>
    8000376a:	8baa                	mv	s7,a0
    8000376c:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000376e:	0001db17          	auipc	s6,0x1d
    80003772:	b6ab0b13          	addi	s6,s6,-1174 # 800202d8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003776:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003778:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000377a:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000377c:	6c89                	lui	s9,0x2
    8000377e:	a061                	j	80003806 <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003780:	97ca                	add	a5,a5,s2
    80003782:	8e55                	or	a2,a2,a3
    80003784:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80003788:	854a                	mv	a0,s2
    8000378a:	00001097          	auipc	ra,0x1
    8000378e:	0b4080e7          	jalr	180(ra) # 8000483e <log_write>
        brelse(bp);
    80003792:	854a                	mv	a0,s2
    80003794:	00000097          	auipc	ra,0x0
    80003798:	e20080e7          	jalr	-480(ra) # 800035b4 <brelse>
  bp = bread(dev, bno);
    8000379c:	85a6                	mv	a1,s1
    8000379e:	855e                	mv	a0,s7
    800037a0:	00000097          	auipc	ra,0x0
    800037a4:	ce4080e7          	jalr	-796(ra) # 80003484 <bread>
    800037a8:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800037aa:	40000613          	li	a2,1024
    800037ae:	4581                	li	a1,0
    800037b0:	05850513          	addi	a0,a0,88
    800037b4:	ffffd097          	auipc	ra,0xffffd
    800037b8:	51e080e7          	jalr	1310(ra) # 80000cd2 <memset>
  log_write(bp);
    800037bc:	854a                	mv	a0,s2
    800037be:	00001097          	auipc	ra,0x1
    800037c2:	080080e7          	jalr	128(ra) # 8000483e <log_write>
  brelse(bp);
    800037c6:	854a                	mv	a0,s2
    800037c8:	00000097          	auipc	ra,0x0
    800037cc:	dec080e7          	jalr	-532(ra) # 800035b4 <brelse>
}
    800037d0:	8526                	mv	a0,s1
    800037d2:	60e6                	ld	ra,88(sp)
    800037d4:	6446                	ld	s0,80(sp)
    800037d6:	64a6                	ld	s1,72(sp)
    800037d8:	6906                	ld	s2,64(sp)
    800037da:	79e2                	ld	s3,56(sp)
    800037dc:	7a42                	ld	s4,48(sp)
    800037de:	7aa2                	ld	s5,40(sp)
    800037e0:	7b02                	ld	s6,32(sp)
    800037e2:	6be2                	ld	s7,24(sp)
    800037e4:	6c42                	ld	s8,16(sp)
    800037e6:	6ca2                	ld	s9,8(sp)
    800037e8:	6125                	addi	sp,sp,96
    800037ea:	8082                	ret
    brelse(bp);
    800037ec:	854a                	mv	a0,s2
    800037ee:	00000097          	auipc	ra,0x0
    800037f2:	dc6080e7          	jalr	-570(ra) # 800035b4 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800037f6:	015c87bb          	addw	a5,s9,s5
    800037fa:	00078a9b          	sext.w	s5,a5
    800037fe:	004b2703          	lw	a4,4(s6)
    80003802:	06eaf163          	bgeu	s5,a4,80003864 <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    80003806:	41fad79b          	sraiw	a5,s5,0x1f
    8000380a:	0137d79b          	srliw	a5,a5,0x13
    8000380e:	015787bb          	addw	a5,a5,s5
    80003812:	40d7d79b          	sraiw	a5,a5,0xd
    80003816:	01cb2583          	lw	a1,28(s6)
    8000381a:	9dbd                	addw	a1,a1,a5
    8000381c:	855e                	mv	a0,s7
    8000381e:	00000097          	auipc	ra,0x0
    80003822:	c66080e7          	jalr	-922(ra) # 80003484 <bread>
    80003826:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003828:	004b2503          	lw	a0,4(s6)
    8000382c:	000a849b          	sext.w	s1,s5
    80003830:	8762                	mv	a4,s8
    80003832:	faa4fde3          	bgeu	s1,a0,800037ec <balloc+0xa6>
      m = 1 << (bi % 8);
    80003836:	00777693          	andi	a3,a4,7
    8000383a:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000383e:	41f7579b          	sraiw	a5,a4,0x1f
    80003842:	01d7d79b          	srliw	a5,a5,0x1d
    80003846:	9fb9                	addw	a5,a5,a4
    80003848:	4037d79b          	sraiw	a5,a5,0x3
    8000384c:	00f90633          	add	a2,s2,a5
    80003850:	05864603          	lbu	a2,88(a2)
    80003854:	00c6f5b3          	and	a1,a3,a2
    80003858:	d585                	beqz	a1,80003780 <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000385a:	2705                	addiw	a4,a4,1
    8000385c:	2485                	addiw	s1,s1,1
    8000385e:	fd471ae3          	bne	a4,s4,80003832 <balloc+0xec>
    80003862:	b769                	j	800037ec <balloc+0xa6>
  printf("balloc: out of blocks\n");
    80003864:	00005517          	auipc	a0,0x5
    80003868:	f0c50513          	addi	a0,a0,-244 # 80008770 <systemCallsNames+0x118>
    8000386c:	ffffd097          	auipc	ra,0xffffd
    80003870:	d1e080e7          	jalr	-738(ra) # 8000058a <printf>
  return 0;
    80003874:	4481                	li	s1,0
    80003876:	bfa9                	j	800037d0 <balloc+0x8a>

0000000080003878 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003878:	7179                	addi	sp,sp,-48
    8000387a:	f406                	sd	ra,40(sp)
    8000387c:	f022                	sd	s0,32(sp)
    8000387e:	ec26                	sd	s1,24(sp)
    80003880:	e84a                	sd	s2,16(sp)
    80003882:	e44e                	sd	s3,8(sp)
    80003884:	e052                	sd	s4,0(sp)
    80003886:	1800                	addi	s0,sp,48
    80003888:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000388a:	47ad                	li	a5,11
    8000388c:	02b7e863          	bltu	a5,a1,800038bc <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    80003890:	02059793          	slli	a5,a1,0x20
    80003894:	01e7d593          	srli	a1,a5,0x1e
    80003898:	00b504b3          	add	s1,a0,a1
    8000389c:	0504a903          	lw	s2,80(s1)
    800038a0:	06091e63          	bnez	s2,8000391c <bmap+0xa4>
      addr = balloc(ip->dev);
    800038a4:	4108                	lw	a0,0(a0)
    800038a6:	00000097          	auipc	ra,0x0
    800038aa:	ea0080e7          	jalr	-352(ra) # 80003746 <balloc>
    800038ae:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800038b2:	06090563          	beqz	s2,8000391c <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    800038b6:	0524a823          	sw	s2,80(s1)
    800038ba:	a08d                	j	8000391c <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    800038bc:	ff45849b          	addiw	s1,a1,-12
    800038c0:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800038c4:	0ff00793          	li	a5,255
    800038c8:	08e7e563          	bltu	a5,a4,80003952 <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    800038cc:	08052903          	lw	s2,128(a0)
    800038d0:	00091d63          	bnez	s2,800038ea <bmap+0x72>
      addr = balloc(ip->dev);
    800038d4:	4108                	lw	a0,0(a0)
    800038d6:	00000097          	auipc	ra,0x0
    800038da:	e70080e7          	jalr	-400(ra) # 80003746 <balloc>
    800038de:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800038e2:	02090d63          	beqz	s2,8000391c <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    800038e6:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    800038ea:	85ca                	mv	a1,s2
    800038ec:	0009a503          	lw	a0,0(s3)
    800038f0:	00000097          	auipc	ra,0x0
    800038f4:	b94080e7          	jalr	-1132(ra) # 80003484 <bread>
    800038f8:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800038fa:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800038fe:	02049713          	slli	a4,s1,0x20
    80003902:	01e75593          	srli	a1,a4,0x1e
    80003906:	00b784b3          	add	s1,a5,a1
    8000390a:	0004a903          	lw	s2,0(s1)
    8000390e:	02090063          	beqz	s2,8000392e <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003912:	8552                	mv	a0,s4
    80003914:	00000097          	auipc	ra,0x0
    80003918:	ca0080e7          	jalr	-864(ra) # 800035b4 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000391c:	854a                	mv	a0,s2
    8000391e:	70a2                	ld	ra,40(sp)
    80003920:	7402                	ld	s0,32(sp)
    80003922:	64e2                	ld	s1,24(sp)
    80003924:	6942                	ld	s2,16(sp)
    80003926:	69a2                	ld	s3,8(sp)
    80003928:	6a02                	ld	s4,0(sp)
    8000392a:	6145                	addi	sp,sp,48
    8000392c:	8082                	ret
      addr = balloc(ip->dev);
    8000392e:	0009a503          	lw	a0,0(s3)
    80003932:	00000097          	auipc	ra,0x0
    80003936:	e14080e7          	jalr	-492(ra) # 80003746 <balloc>
    8000393a:	0005091b          	sext.w	s2,a0
      if(addr){
    8000393e:	fc090ae3          	beqz	s2,80003912 <bmap+0x9a>
        a[bn] = addr;
    80003942:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003946:	8552                	mv	a0,s4
    80003948:	00001097          	auipc	ra,0x1
    8000394c:	ef6080e7          	jalr	-266(ra) # 8000483e <log_write>
    80003950:	b7c9                	j	80003912 <bmap+0x9a>
  panic("bmap: out of range");
    80003952:	00005517          	auipc	a0,0x5
    80003956:	e3650513          	addi	a0,a0,-458 # 80008788 <systemCallsNames+0x130>
    8000395a:	ffffd097          	auipc	ra,0xffffd
    8000395e:	be6080e7          	jalr	-1050(ra) # 80000540 <panic>

0000000080003962 <iget>:
{
    80003962:	7179                	addi	sp,sp,-48
    80003964:	f406                	sd	ra,40(sp)
    80003966:	f022                	sd	s0,32(sp)
    80003968:	ec26                	sd	s1,24(sp)
    8000396a:	e84a                	sd	s2,16(sp)
    8000396c:	e44e                	sd	s3,8(sp)
    8000396e:	e052                	sd	s4,0(sp)
    80003970:	1800                	addi	s0,sp,48
    80003972:	89aa                	mv	s3,a0
    80003974:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003976:	0001d517          	auipc	a0,0x1d
    8000397a:	98250513          	addi	a0,a0,-1662 # 800202f8 <itable>
    8000397e:	ffffd097          	auipc	ra,0xffffd
    80003982:	258080e7          	jalr	600(ra) # 80000bd6 <acquire>
  empty = 0;
    80003986:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003988:	0001d497          	auipc	s1,0x1d
    8000398c:	98848493          	addi	s1,s1,-1656 # 80020310 <itable+0x18>
    80003990:	0001e697          	auipc	a3,0x1e
    80003994:	41068693          	addi	a3,a3,1040 # 80021da0 <log>
    80003998:	a039                	j	800039a6 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000399a:	02090b63          	beqz	s2,800039d0 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000399e:	08848493          	addi	s1,s1,136
    800039a2:	02d48a63          	beq	s1,a3,800039d6 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800039a6:	449c                	lw	a5,8(s1)
    800039a8:	fef059e3          	blez	a5,8000399a <iget+0x38>
    800039ac:	4098                	lw	a4,0(s1)
    800039ae:	ff3716e3          	bne	a4,s3,8000399a <iget+0x38>
    800039b2:	40d8                	lw	a4,4(s1)
    800039b4:	ff4713e3          	bne	a4,s4,8000399a <iget+0x38>
      ip->ref++;
    800039b8:	2785                	addiw	a5,a5,1
    800039ba:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800039bc:	0001d517          	auipc	a0,0x1d
    800039c0:	93c50513          	addi	a0,a0,-1732 # 800202f8 <itable>
    800039c4:	ffffd097          	auipc	ra,0xffffd
    800039c8:	2c6080e7          	jalr	710(ra) # 80000c8a <release>
      return ip;
    800039cc:	8926                	mv	s2,s1
    800039ce:	a03d                	j	800039fc <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800039d0:	f7f9                	bnez	a5,8000399e <iget+0x3c>
    800039d2:	8926                	mv	s2,s1
    800039d4:	b7e9                	j	8000399e <iget+0x3c>
  if(empty == 0)
    800039d6:	02090c63          	beqz	s2,80003a0e <iget+0xac>
  ip->dev = dev;
    800039da:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800039de:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800039e2:	4785                	li	a5,1
    800039e4:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800039e8:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800039ec:	0001d517          	auipc	a0,0x1d
    800039f0:	90c50513          	addi	a0,a0,-1780 # 800202f8 <itable>
    800039f4:	ffffd097          	auipc	ra,0xffffd
    800039f8:	296080e7          	jalr	662(ra) # 80000c8a <release>
}
    800039fc:	854a                	mv	a0,s2
    800039fe:	70a2                	ld	ra,40(sp)
    80003a00:	7402                	ld	s0,32(sp)
    80003a02:	64e2                	ld	s1,24(sp)
    80003a04:	6942                	ld	s2,16(sp)
    80003a06:	69a2                	ld	s3,8(sp)
    80003a08:	6a02                	ld	s4,0(sp)
    80003a0a:	6145                	addi	sp,sp,48
    80003a0c:	8082                	ret
    panic("iget: no inodes");
    80003a0e:	00005517          	auipc	a0,0x5
    80003a12:	d9250513          	addi	a0,a0,-622 # 800087a0 <systemCallsNames+0x148>
    80003a16:	ffffd097          	auipc	ra,0xffffd
    80003a1a:	b2a080e7          	jalr	-1238(ra) # 80000540 <panic>

0000000080003a1e <fsinit>:
fsinit(int dev) {
    80003a1e:	7179                	addi	sp,sp,-48
    80003a20:	f406                	sd	ra,40(sp)
    80003a22:	f022                	sd	s0,32(sp)
    80003a24:	ec26                	sd	s1,24(sp)
    80003a26:	e84a                	sd	s2,16(sp)
    80003a28:	e44e                	sd	s3,8(sp)
    80003a2a:	1800                	addi	s0,sp,48
    80003a2c:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003a2e:	4585                	li	a1,1
    80003a30:	00000097          	auipc	ra,0x0
    80003a34:	a54080e7          	jalr	-1452(ra) # 80003484 <bread>
    80003a38:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003a3a:	0001d997          	auipc	s3,0x1d
    80003a3e:	89e98993          	addi	s3,s3,-1890 # 800202d8 <sb>
    80003a42:	02000613          	li	a2,32
    80003a46:	05850593          	addi	a1,a0,88
    80003a4a:	854e                	mv	a0,s3
    80003a4c:	ffffd097          	auipc	ra,0xffffd
    80003a50:	2e2080e7          	jalr	738(ra) # 80000d2e <memmove>
  brelse(bp);
    80003a54:	8526                	mv	a0,s1
    80003a56:	00000097          	auipc	ra,0x0
    80003a5a:	b5e080e7          	jalr	-1186(ra) # 800035b4 <brelse>
  if(sb.magic != FSMAGIC)
    80003a5e:	0009a703          	lw	a4,0(s3)
    80003a62:	102037b7          	lui	a5,0x10203
    80003a66:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003a6a:	02f71263          	bne	a4,a5,80003a8e <fsinit+0x70>
  initlog(dev, &sb);
    80003a6e:	0001d597          	auipc	a1,0x1d
    80003a72:	86a58593          	addi	a1,a1,-1942 # 800202d8 <sb>
    80003a76:	854a                	mv	a0,s2
    80003a78:	00001097          	auipc	ra,0x1
    80003a7c:	b4a080e7          	jalr	-1206(ra) # 800045c2 <initlog>
}
    80003a80:	70a2                	ld	ra,40(sp)
    80003a82:	7402                	ld	s0,32(sp)
    80003a84:	64e2                	ld	s1,24(sp)
    80003a86:	6942                	ld	s2,16(sp)
    80003a88:	69a2                	ld	s3,8(sp)
    80003a8a:	6145                	addi	sp,sp,48
    80003a8c:	8082                	ret
    panic("invalid file system");
    80003a8e:	00005517          	auipc	a0,0x5
    80003a92:	d2250513          	addi	a0,a0,-734 # 800087b0 <systemCallsNames+0x158>
    80003a96:	ffffd097          	auipc	ra,0xffffd
    80003a9a:	aaa080e7          	jalr	-1366(ra) # 80000540 <panic>

0000000080003a9e <iinit>:
{
    80003a9e:	7179                	addi	sp,sp,-48
    80003aa0:	f406                	sd	ra,40(sp)
    80003aa2:	f022                	sd	s0,32(sp)
    80003aa4:	ec26                	sd	s1,24(sp)
    80003aa6:	e84a                	sd	s2,16(sp)
    80003aa8:	e44e                	sd	s3,8(sp)
    80003aaa:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003aac:	00005597          	auipc	a1,0x5
    80003ab0:	d1c58593          	addi	a1,a1,-740 # 800087c8 <systemCallsNames+0x170>
    80003ab4:	0001d517          	auipc	a0,0x1d
    80003ab8:	84450513          	addi	a0,a0,-1980 # 800202f8 <itable>
    80003abc:	ffffd097          	auipc	ra,0xffffd
    80003ac0:	08a080e7          	jalr	138(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003ac4:	0001d497          	auipc	s1,0x1d
    80003ac8:	85c48493          	addi	s1,s1,-1956 # 80020320 <itable+0x28>
    80003acc:	0001e997          	auipc	s3,0x1e
    80003ad0:	2e498993          	addi	s3,s3,740 # 80021db0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003ad4:	00005917          	auipc	s2,0x5
    80003ad8:	cfc90913          	addi	s2,s2,-772 # 800087d0 <systemCallsNames+0x178>
    80003adc:	85ca                	mv	a1,s2
    80003ade:	8526                	mv	a0,s1
    80003ae0:	00001097          	auipc	ra,0x1
    80003ae4:	e42080e7          	jalr	-446(ra) # 80004922 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003ae8:	08848493          	addi	s1,s1,136
    80003aec:	ff3498e3          	bne	s1,s3,80003adc <iinit+0x3e>
}
    80003af0:	70a2                	ld	ra,40(sp)
    80003af2:	7402                	ld	s0,32(sp)
    80003af4:	64e2                	ld	s1,24(sp)
    80003af6:	6942                	ld	s2,16(sp)
    80003af8:	69a2                	ld	s3,8(sp)
    80003afa:	6145                	addi	sp,sp,48
    80003afc:	8082                	ret

0000000080003afe <ialloc>:
{
    80003afe:	715d                	addi	sp,sp,-80
    80003b00:	e486                	sd	ra,72(sp)
    80003b02:	e0a2                	sd	s0,64(sp)
    80003b04:	fc26                	sd	s1,56(sp)
    80003b06:	f84a                	sd	s2,48(sp)
    80003b08:	f44e                	sd	s3,40(sp)
    80003b0a:	f052                	sd	s4,32(sp)
    80003b0c:	ec56                	sd	s5,24(sp)
    80003b0e:	e85a                	sd	s6,16(sp)
    80003b10:	e45e                	sd	s7,8(sp)
    80003b12:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003b14:	0001c717          	auipc	a4,0x1c
    80003b18:	7d072703          	lw	a4,2000(a4) # 800202e4 <sb+0xc>
    80003b1c:	4785                	li	a5,1
    80003b1e:	04e7fa63          	bgeu	a5,a4,80003b72 <ialloc+0x74>
    80003b22:	8aaa                	mv	s5,a0
    80003b24:	8bae                	mv	s7,a1
    80003b26:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003b28:	0001ca17          	auipc	s4,0x1c
    80003b2c:	7b0a0a13          	addi	s4,s4,1968 # 800202d8 <sb>
    80003b30:	00048b1b          	sext.w	s6,s1
    80003b34:	0044d593          	srli	a1,s1,0x4
    80003b38:	018a2783          	lw	a5,24(s4)
    80003b3c:	9dbd                	addw	a1,a1,a5
    80003b3e:	8556                	mv	a0,s5
    80003b40:	00000097          	auipc	ra,0x0
    80003b44:	944080e7          	jalr	-1724(ra) # 80003484 <bread>
    80003b48:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003b4a:	05850993          	addi	s3,a0,88
    80003b4e:	00f4f793          	andi	a5,s1,15
    80003b52:	079a                	slli	a5,a5,0x6
    80003b54:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003b56:	00099783          	lh	a5,0(s3)
    80003b5a:	c3a1                	beqz	a5,80003b9a <ialloc+0x9c>
    brelse(bp);
    80003b5c:	00000097          	auipc	ra,0x0
    80003b60:	a58080e7          	jalr	-1448(ra) # 800035b4 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003b64:	0485                	addi	s1,s1,1
    80003b66:	00ca2703          	lw	a4,12(s4)
    80003b6a:	0004879b          	sext.w	a5,s1
    80003b6e:	fce7e1e3          	bltu	a5,a4,80003b30 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003b72:	00005517          	auipc	a0,0x5
    80003b76:	c6650513          	addi	a0,a0,-922 # 800087d8 <systemCallsNames+0x180>
    80003b7a:	ffffd097          	auipc	ra,0xffffd
    80003b7e:	a10080e7          	jalr	-1520(ra) # 8000058a <printf>
  return 0;
    80003b82:	4501                	li	a0,0
}
    80003b84:	60a6                	ld	ra,72(sp)
    80003b86:	6406                	ld	s0,64(sp)
    80003b88:	74e2                	ld	s1,56(sp)
    80003b8a:	7942                	ld	s2,48(sp)
    80003b8c:	79a2                	ld	s3,40(sp)
    80003b8e:	7a02                	ld	s4,32(sp)
    80003b90:	6ae2                	ld	s5,24(sp)
    80003b92:	6b42                	ld	s6,16(sp)
    80003b94:	6ba2                	ld	s7,8(sp)
    80003b96:	6161                	addi	sp,sp,80
    80003b98:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003b9a:	04000613          	li	a2,64
    80003b9e:	4581                	li	a1,0
    80003ba0:	854e                	mv	a0,s3
    80003ba2:	ffffd097          	auipc	ra,0xffffd
    80003ba6:	130080e7          	jalr	304(ra) # 80000cd2 <memset>
      dip->type = type;
    80003baa:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003bae:	854a                	mv	a0,s2
    80003bb0:	00001097          	auipc	ra,0x1
    80003bb4:	c8e080e7          	jalr	-882(ra) # 8000483e <log_write>
      brelse(bp);
    80003bb8:	854a                	mv	a0,s2
    80003bba:	00000097          	auipc	ra,0x0
    80003bbe:	9fa080e7          	jalr	-1542(ra) # 800035b4 <brelse>
      return iget(dev, inum);
    80003bc2:	85da                	mv	a1,s6
    80003bc4:	8556                	mv	a0,s5
    80003bc6:	00000097          	auipc	ra,0x0
    80003bca:	d9c080e7          	jalr	-612(ra) # 80003962 <iget>
    80003bce:	bf5d                	j	80003b84 <ialloc+0x86>

0000000080003bd0 <iupdate>:
{
    80003bd0:	1101                	addi	sp,sp,-32
    80003bd2:	ec06                	sd	ra,24(sp)
    80003bd4:	e822                	sd	s0,16(sp)
    80003bd6:	e426                	sd	s1,8(sp)
    80003bd8:	e04a                	sd	s2,0(sp)
    80003bda:	1000                	addi	s0,sp,32
    80003bdc:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003bde:	415c                	lw	a5,4(a0)
    80003be0:	0047d79b          	srliw	a5,a5,0x4
    80003be4:	0001c597          	auipc	a1,0x1c
    80003be8:	70c5a583          	lw	a1,1804(a1) # 800202f0 <sb+0x18>
    80003bec:	9dbd                	addw	a1,a1,a5
    80003bee:	4108                	lw	a0,0(a0)
    80003bf0:	00000097          	auipc	ra,0x0
    80003bf4:	894080e7          	jalr	-1900(ra) # 80003484 <bread>
    80003bf8:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003bfa:	05850793          	addi	a5,a0,88
    80003bfe:	40d8                	lw	a4,4(s1)
    80003c00:	8b3d                	andi	a4,a4,15
    80003c02:	071a                	slli	a4,a4,0x6
    80003c04:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003c06:	04449703          	lh	a4,68(s1)
    80003c0a:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003c0e:	04649703          	lh	a4,70(s1)
    80003c12:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003c16:	04849703          	lh	a4,72(s1)
    80003c1a:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003c1e:	04a49703          	lh	a4,74(s1)
    80003c22:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003c26:	44f8                	lw	a4,76(s1)
    80003c28:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003c2a:	03400613          	li	a2,52
    80003c2e:	05048593          	addi	a1,s1,80
    80003c32:	00c78513          	addi	a0,a5,12
    80003c36:	ffffd097          	auipc	ra,0xffffd
    80003c3a:	0f8080e7          	jalr	248(ra) # 80000d2e <memmove>
  log_write(bp);
    80003c3e:	854a                	mv	a0,s2
    80003c40:	00001097          	auipc	ra,0x1
    80003c44:	bfe080e7          	jalr	-1026(ra) # 8000483e <log_write>
  brelse(bp);
    80003c48:	854a                	mv	a0,s2
    80003c4a:	00000097          	auipc	ra,0x0
    80003c4e:	96a080e7          	jalr	-1686(ra) # 800035b4 <brelse>
}
    80003c52:	60e2                	ld	ra,24(sp)
    80003c54:	6442                	ld	s0,16(sp)
    80003c56:	64a2                	ld	s1,8(sp)
    80003c58:	6902                	ld	s2,0(sp)
    80003c5a:	6105                	addi	sp,sp,32
    80003c5c:	8082                	ret

0000000080003c5e <idup>:
{
    80003c5e:	1101                	addi	sp,sp,-32
    80003c60:	ec06                	sd	ra,24(sp)
    80003c62:	e822                	sd	s0,16(sp)
    80003c64:	e426                	sd	s1,8(sp)
    80003c66:	1000                	addi	s0,sp,32
    80003c68:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003c6a:	0001c517          	auipc	a0,0x1c
    80003c6e:	68e50513          	addi	a0,a0,1678 # 800202f8 <itable>
    80003c72:	ffffd097          	auipc	ra,0xffffd
    80003c76:	f64080e7          	jalr	-156(ra) # 80000bd6 <acquire>
  ip->ref++;
    80003c7a:	449c                	lw	a5,8(s1)
    80003c7c:	2785                	addiw	a5,a5,1
    80003c7e:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003c80:	0001c517          	auipc	a0,0x1c
    80003c84:	67850513          	addi	a0,a0,1656 # 800202f8 <itable>
    80003c88:	ffffd097          	auipc	ra,0xffffd
    80003c8c:	002080e7          	jalr	2(ra) # 80000c8a <release>
}
    80003c90:	8526                	mv	a0,s1
    80003c92:	60e2                	ld	ra,24(sp)
    80003c94:	6442                	ld	s0,16(sp)
    80003c96:	64a2                	ld	s1,8(sp)
    80003c98:	6105                	addi	sp,sp,32
    80003c9a:	8082                	ret

0000000080003c9c <ilock>:
{
    80003c9c:	1101                	addi	sp,sp,-32
    80003c9e:	ec06                	sd	ra,24(sp)
    80003ca0:	e822                	sd	s0,16(sp)
    80003ca2:	e426                	sd	s1,8(sp)
    80003ca4:	e04a                	sd	s2,0(sp)
    80003ca6:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003ca8:	c115                	beqz	a0,80003ccc <ilock+0x30>
    80003caa:	84aa                	mv	s1,a0
    80003cac:	451c                	lw	a5,8(a0)
    80003cae:	00f05f63          	blez	a5,80003ccc <ilock+0x30>
  acquiresleep(&ip->lock);
    80003cb2:	0541                	addi	a0,a0,16
    80003cb4:	00001097          	auipc	ra,0x1
    80003cb8:	ca8080e7          	jalr	-856(ra) # 8000495c <acquiresleep>
  if(ip->valid == 0){
    80003cbc:	40bc                	lw	a5,64(s1)
    80003cbe:	cf99                	beqz	a5,80003cdc <ilock+0x40>
}
    80003cc0:	60e2                	ld	ra,24(sp)
    80003cc2:	6442                	ld	s0,16(sp)
    80003cc4:	64a2                	ld	s1,8(sp)
    80003cc6:	6902                	ld	s2,0(sp)
    80003cc8:	6105                	addi	sp,sp,32
    80003cca:	8082                	ret
    panic("ilock");
    80003ccc:	00005517          	auipc	a0,0x5
    80003cd0:	b2450513          	addi	a0,a0,-1244 # 800087f0 <systemCallsNames+0x198>
    80003cd4:	ffffd097          	auipc	ra,0xffffd
    80003cd8:	86c080e7          	jalr	-1940(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003cdc:	40dc                	lw	a5,4(s1)
    80003cde:	0047d79b          	srliw	a5,a5,0x4
    80003ce2:	0001c597          	auipc	a1,0x1c
    80003ce6:	60e5a583          	lw	a1,1550(a1) # 800202f0 <sb+0x18>
    80003cea:	9dbd                	addw	a1,a1,a5
    80003cec:	4088                	lw	a0,0(s1)
    80003cee:	fffff097          	auipc	ra,0xfffff
    80003cf2:	796080e7          	jalr	1942(ra) # 80003484 <bread>
    80003cf6:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003cf8:	05850593          	addi	a1,a0,88
    80003cfc:	40dc                	lw	a5,4(s1)
    80003cfe:	8bbd                	andi	a5,a5,15
    80003d00:	079a                	slli	a5,a5,0x6
    80003d02:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003d04:	00059783          	lh	a5,0(a1)
    80003d08:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003d0c:	00259783          	lh	a5,2(a1)
    80003d10:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003d14:	00459783          	lh	a5,4(a1)
    80003d18:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003d1c:	00659783          	lh	a5,6(a1)
    80003d20:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003d24:	459c                	lw	a5,8(a1)
    80003d26:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003d28:	03400613          	li	a2,52
    80003d2c:	05b1                	addi	a1,a1,12
    80003d2e:	05048513          	addi	a0,s1,80
    80003d32:	ffffd097          	auipc	ra,0xffffd
    80003d36:	ffc080e7          	jalr	-4(ra) # 80000d2e <memmove>
    brelse(bp);
    80003d3a:	854a                	mv	a0,s2
    80003d3c:	00000097          	auipc	ra,0x0
    80003d40:	878080e7          	jalr	-1928(ra) # 800035b4 <brelse>
    ip->valid = 1;
    80003d44:	4785                	li	a5,1
    80003d46:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003d48:	04449783          	lh	a5,68(s1)
    80003d4c:	fbb5                	bnez	a5,80003cc0 <ilock+0x24>
      panic("ilock: no type");
    80003d4e:	00005517          	auipc	a0,0x5
    80003d52:	aaa50513          	addi	a0,a0,-1366 # 800087f8 <systemCallsNames+0x1a0>
    80003d56:	ffffc097          	auipc	ra,0xffffc
    80003d5a:	7ea080e7          	jalr	2026(ra) # 80000540 <panic>

0000000080003d5e <iunlock>:
{
    80003d5e:	1101                	addi	sp,sp,-32
    80003d60:	ec06                	sd	ra,24(sp)
    80003d62:	e822                	sd	s0,16(sp)
    80003d64:	e426                	sd	s1,8(sp)
    80003d66:	e04a                	sd	s2,0(sp)
    80003d68:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003d6a:	c905                	beqz	a0,80003d9a <iunlock+0x3c>
    80003d6c:	84aa                	mv	s1,a0
    80003d6e:	01050913          	addi	s2,a0,16
    80003d72:	854a                	mv	a0,s2
    80003d74:	00001097          	auipc	ra,0x1
    80003d78:	c82080e7          	jalr	-894(ra) # 800049f6 <holdingsleep>
    80003d7c:	cd19                	beqz	a0,80003d9a <iunlock+0x3c>
    80003d7e:	449c                	lw	a5,8(s1)
    80003d80:	00f05d63          	blez	a5,80003d9a <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003d84:	854a                	mv	a0,s2
    80003d86:	00001097          	auipc	ra,0x1
    80003d8a:	c2c080e7          	jalr	-980(ra) # 800049b2 <releasesleep>
}
    80003d8e:	60e2                	ld	ra,24(sp)
    80003d90:	6442                	ld	s0,16(sp)
    80003d92:	64a2                	ld	s1,8(sp)
    80003d94:	6902                	ld	s2,0(sp)
    80003d96:	6105                	addi	sp,sp,32
    80003d98:	8082                	ret
    panic("iunlock");
    80003d9a:	00005517          	auipc	a0,0x5
    80003d9e:	a6e50513          	addi	a0,a0,-1426 # 80008808 <systemCallsNames+0x1b0>
    80003da2:	ffffc097          	auipc	ra,0xffffc
    80003da6:	79e080e7          	jalr	1950(ra) # 80000540 <panic>

0000000080003daa <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003daa:	7179                	addi	sp,sp,-48
    80003dac:	f406                	sd	ra,40(sp)
    80003dae:	f022                	sd	s0,32(sp)
    80003db0:	ec26                	sd	s1,24(sp)
    80003db2:	e84a                	sd	s2,16(sp)
    80003db4:	e44e                	sd	s3,8(sp)
    80003db6:	e052                	sd	s4,0(sp)
    80003db8:	1800                	addi	s0,sp,48
    80003dba:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003dbc:	05050493          	addi	s1,a0,80
    80003dc0:	08050913          	addi	s2,a0,128
    80003dc4:	a021                	j	80003dcc <itrunc+0x22>
    80003dc6:	0491                	addi	s1,s1,4
    80003dc8:	01248d63          	beq	s1,s2,80003de2 <itrunc+0x38>
    if(ip->addrs[i]){
    80003dcc:	408c                	lw	a1,0(s1)
    80003dce:	dde5                	beqz	a1,80003dc6 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003dd0:	0009a503          	lw	a0,0(s3)
    80003dd4:	00000097          	auipc	ra,0x0
    80003dd8:	8f6080e7          	jalr	-1802(ra) # 800036ca <bfree>
      ip->addrs[i] = 0;
    80003ddc:	0004a023          	sw	zero,0(s1)
    80003de0:	b7dd                	j	80003dc6 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003de2:	0809a583          	lw	a1,128(s3)
    80003de6:	e185                	bnez	a1,80003e06 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003de8:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003dec:	854e                	mv	a0,s3
    80003dee:	00000097          	auipc	ra,0x0
    80003df2:	de2080e7          	jalr	-542(ra) # 80003bd0 <iupdate>
}
    80003df6:	70a2                	ld	ra,40(sp)
    80003df8:	7402                	ld	s0,32(sp)
    80003dfa:	64e2                	ld	s1,24(sp)
    80003dfc:	6942                	ld	s2,16(sp)
    80003dfe:	69a2                	ld	s3,8(sp)
    80003e00:	6a02                	ld	s4,0(sp)
    80003e02:	6145                	addi	sp,sp,48
    80003e04:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003e06:	0009a503          	lw	a0,0(s3)
    80003e0a:	fffff097          	auipc	ra,0xfffff
    80003e0e:	67a080e7          	jalr	1658(ra) # 80003484 <bread>
    80003e12:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003e14:	05850493          	addi	s1,a0,88
    80003e18:	45850913          	addi	s2,a0,1112
    80003e1c:	a021                	j	80003e24 <itrunc+0x7a>
    80003e1e:	0491                	addi	s1,s1,4
    80003e20:	01248b63          	beq	s1,s2,80003e36 <itrunc+0x8c>
      if(a[j])
    80003e24:	408c                	lw	a1,0(s1)
    80003e26:	dde5                	beqz	a1,80003e1e <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003e28:	0009a503          	lw	a0,0(s3)
    80003e2c:	00000097          	auipc	ra,0x0
    80003e30:	89e080e7          	jalr	-1890(ra) # 800036ca <bfree>
    80003e34:	b7ed                	j	80003e1e <itrunc+0x74>
    brelse(bp);
    80003e36:	8552                	mv	a0,s4
    80003e38:	fffff097          	auipc	ra,0xfffff
    80003e3c:	77c080e7          	jalr	1916(ra) # 800035b4 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003e40:	0809a583          	lw	a1,128(s3)
    80003e44:	0009a503          	lw	a0,0(s3)
    80003e48:	00000097          	auipc	ra,0x0
    80003e4c:	882080e7          	jalr	-1918(ra) # 800036ca <bfree>
    ip->addrs[NDIRECT] = 0;
    80003e50:	0809a023          	sw	zero,128(s3)
    80003e54:	bf51                	j	80003de8 <itrunc+0x3e>

0000000080003e56 <iput>:
{
    80003e56:	1101                	addi	sp,sp,-32
    80003e58:	ec06                	sd	ra,24(sp)
    80003e5a:	e822                	sd	s0,16(sp)
    80003e5c:	e426                	sd	s1,8(sp)
    80003e5e:	e04a                	sd	s2,0(sp)
    80003e60:	1000                	addi	s0,sp,32
    80003e62:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003e64:	0001c517          	auipc	a0,0x1c
    80003e68:	49450513          	addi	a0,a0,1172 # 800202f8 <itable>
    80003e6c:	ffffd097          	auipc	ra,0xffffd
    80003e70:	d6a080e7          	jalr	-662(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003e74:	4498                	lw	a4,8(s1)
    80003e76:	4785                	li	a5,1
    80003e78:	02f70363          	beq	a4,a5,80003e9e <iput+0x48>
  ip->ref--;
    80003e7c:	449c                	lw	a5,8(s1)
    80003e7e:	37fd                	addiw	a5,a5,-1
    80003e80:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003e82:	0001c517          	auipc	a0,0x1c
    80003e86:	47650513          	addi	a0,a0,1142 # 800202f8 <itable>
    80003e8a:	ffffd097          	auipc	ra,0xffffd
    80003e8e:	e00080e7          	jalr	-512(ra) # 80000c8a <release>
}
    80003e92:	60e2                	ld	ra,24(sp)
    80003e94:	6442                	ld	s0,16(sp)
    80003e96:	64a2                	ld	s1,8(sp)
    80003e98:	6902                	ld	s2,0(sp)
    80003e9a:	6105                	addi	sp,sp,32
    80003e9c:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003e9e:	40bc                	lw	a5,64(s1)
    80003ea0:	dff1                	beqz	a5,80003e7c <iput+0x26>
    80003ea2:	04a49783          	lh	a5,74(s1)
    80003ea6:	fbf9                	bnez	a5,80003e7c <iput+0x26>
    acquiresleep(&ip->lock);
    80003ea8:	01048913          	addi	s2,s1,16
    80003eac:	854a                	mv	a0,s2
    80003eae:	00001097          	auipc	ra,0x1
    80003eb2:	aae080e7          	jalr	-1362(ra) # 8000495c <acquiresleep>
    release(&itable.lock);
    80003eb6:	0001c517          	auipc	a0,0x1c
    80003eba:	44250513          	addi	a0,a0,1090 # 800202f8 <itable>
    80003ebe:	ffffd097          	auipc	ra,0xffffd
    80003ec2:	dcc080e7          	jalr	-564(ra) # 80000c8a <release>
    itrunc(ip);
    80003ec6:	8526                	mv	a0,s1
    80003ec8:	00000097          	auipc	ra,0x0
    80003ecc:	ee2080e7          	jalr	-286(ra) # 80003daa <itrunc>
    ip->type = 0;
    80003ed0:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003ed4:	8526                	mv	a0,s1
    80003ed6:	00000097          	auipc	ra,0x0
    80003eda:	cfa080e7          	jalr	-774(ra) # 80003bd0 <iupdate>
    ip->valid = 0;
    80003ede:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003ee2:	854a                	mv	a0,s2
    80003ee4:	00001097          	auipc	ra,0x1
    80003ee8:	ace080e7          	jalr	-1330(ra) # 800049b2 <releasesleep>
    acquire(&itable.lock);
    80003eec:	0001c517          	auipc	a0,0x1c
    80003ef0:	40c50513          	addi	a0,a0,1036 # 800202f8 <itable>
    80003ef4:	ffffd097          	auipc	ra,0xffffd
    80003ef8:	ce2080e7          	jalr	-798(ra) # 80000bd6 <acquire>
    80003efc:	b741                	j	80003e7c <iput+0x26>

0000000080003efe <iunlockput>:
{
    80003efe:	1101                	addi	sp,sp,-32
    80003f00:	ec06                	sd	ra,24(sp)
    80003f02:	e822                	sd	s0,16(sp)
    80003f04:	e426                	sd	s1,8(sp)
    80003f06:	1000                	addi	s0,sp,32
    80003f08:	84aa                	mv	s1,a0
  iunlock(ip);
    80003f0a:	00000097          	auipc	ra,0x0
    80003f0e:	e54080e7          	jalr	-428(ra) # 80003d5e <iunlock>
  iput(ip);
    80003f12:	8526                	mv	a0,s1
    80003f14:	00000097          	auipc	ra,0x0
    80003f18:	f42080e7          	jalr	-190(ra) # 80003e56 <iput>
}
    80003f1c:	60e2                	ld	ra,24(sp)
    80003f1e:	6442                	ld	s0,16(sp)
    80003f20:	64a2                	ld	s1,8(sp)
    80003f22:	6105                	addi	sp,sp,32
    80003f24:	8082                	ret

0000000080003f26 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003f26:	1141                	addi	sp,sp,-16
    80003f28:	e422                	sd	s0,8(sp)
    80003f2a:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003f2c:	411c                	lw	a5,0(a0)
    80003f2e:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003f30:	415c                	lw	a5,4(a0)
    80003f32:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003f34:	04451783          	lh	a5,68(a0)
    80003f38:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003f3c:	04a51783          	lh	a5,74(a0)
    80003f40:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003f44:	04c56783          	lwu	a5,76(a0)
    80003f48:	e99c                	sd	a5,16(a1)
}
    80003f4a:	6422                	ld	s0,8(sp)
    80003f4c:	0141                	addi	sp,sp,16
    80003f4e:	8082                	ret

0000000080003f50 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003f50:	457c                	lw	a5,76(a0)
    80003f52:	0ed7e963          	bltu	a5,a3,80004044 <readi+0xf4>
{
    80003f56:	7159                	addi	sp,sp,-112
    80003f58:	f486                	sd	ra,104(sp)
    80003f5a:	f0a2                	sd	s0,96(sp)
    80003f5c:	eca6                	sd	s1,88(sp)
    80003f5e:	e8ca                	sd	s2,80(sp)
    80003f60:	e4ce                	sd	s3,72(sp)
    80003f62:	e0d2                	sd	s4,64(sp)
    80003f64:	fc56                	sd	s5,56(sp)
    80003f66:	f85a                	sd	s6,48(sp)
    80003f68:	f45e                	sd	s7,40(sp)
    80003f6a:	f062                	sd	s8,32(sp)
    80003f6c:	ec66                	sd	s9,24(sp)
    80003f6e:	e86a                	sd	s10,16(sp)
    80003f70:	e46e                	sd	s11,8(sp)
    80003f72:	1880                	addi	s0,sp,112
    80003f74:	8b2a                	mv	s6,a0
    80003f76:	8bae                	mv	s7,a1
    80003f78:	8a32                	mv	s4,a2
    80003f7a:	84b6                	mv	s1,a3
    80003f7c:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003f7e:	9f35                	addw	a4,a4,a3
    return 0;
    80003f80:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003f82:	0ad76063          	bltu	a4,a3,80004022 <readi+0xd2>
  if(off + n > ip->size)
    80003f86:	00e7f463          	bgeu	a5,a4,80003f8e <readi+0x3e>
    n = ip->size - off;
    80003f8a:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f8e:	0a0a8963          	beqz	s5,80004040 <readi+0xf0>
    80003f92:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f94:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003f98:	5c7d                	li	s8,-1
    80003f9a:	a82d                	j	80003fd4 <readi+0x84>
    80003f9c:	020d1d93          	slli	s11,s10,0x20
    80003fa0:	020ddd93          	srli	s11,s11,0x20
    80003fa4:	05890613          	addi	a2,s2,88
    80003fa8:	86ee                	mv	a3,s11
    80003faa:	963a                	add	a2,a2,a4
    80003fac:	85d2                	mv	a1,s4
    80003fae:	855e                	mv	a0,s7
    80003fb0:	ffffe097          	auipc	ra,0xffffe
    80003fb4:	7ea080e7          	jalr	2026(ra) # 8000279a <either_copyout>
    80003fb8:	05850d63          	beq	a0,s8,80004012 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003fbc:	854a                	mv	a0,s2
    80003fbe:	fffff097          	auipc	ra,0xfffff
    80003fc2:	5f6080e7          	jalr	1526(ra) # 800035b4 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003fc6:	013d09bb          	addw	s3,s10,s3
    80003fca:	009d04bb          	addw	s1,s10,s1
    80003fce:	9a6e                	add	s4,s4,s11
    80003fd0:	0559f763          	bgeu	s3,s5,8000401e <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003fd4:	00a4d59b          	srliw	a1,s1,0xa
    80003fd8:	855a                	mv	a0,s6
    80003fda:	00000097          	auipc	ra,0x0
    80003fde:	89e080e7          	jalr	-1890(ra) # 80003878 <bmap>
    80003fe2:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003fe6:	cd85                	beqz	a1,8000401e <readi+0xce>
    bp = bread(ip->dev, addr);
    80003fe8:	000b2503          	lw	a0,0(s6)
    80003fec:	fffff097          	auipc	ra,0xfffff
    80003ff0:	498080e7          	jalr	1176(ra) # 80003484 <bread>
    80003ff4:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ff6:	3ff4f713          	andi	a4,s1,1023
    80003ffa:	40ec87bb          	subw	a5,s9,a4
    80003ffe:	413a86bb          	subw	a3,s5,s3
    80004002:	8d3e                	mv	s10,a5
    80004004:	2781                	sext.w	a5,a5
    80004006:	0006861b          	sext.w	a2,a3
    8000400a:	f8f679e3          	bgeu	a2,a5,80003f9c <readi+0x4c>
    8000400e:	8d36                	mv	s10,a3
    80004010:	b771                	j	80003f9c <readi+0x4c>
      brelse(bp);
    80004012:	854a                	mv	a0,s2
    80004014:	fffff097          	auipc	ra,0xfffff
    80004018:	5a0080e7          	jalr	1440(ra) # 800035b4 <brelse>
      tot = -1;
    8000401c:	59fd                	li	s3,-1
  }
  return tot;
    8000401e:	0009851b          	sext.w	a0,s3
}
    80004022:	70a6                	ld	ra,104(sp)
    80004024:	7406                	ld	s0,96(sp)
    80004026:	64e6                	ld	s1,88(sp)
    80004028:	6946                	ld	s2,80(sp)
    8000402a:	69a6                	ld	s3,72(sp)
    8000402c:	6a06                	ld	s4,64(sp)
    8000402e:	7ae2                	ld	s5,56(sp)
    80004030:	7b42                	ld	s6,48(sp)
    80004032:	7ba2                	ld	s7,40(sp)
    80004034:	7c02                	ld	s8,32(sp)
    80004036:	6ce2                	ld	s9,24(sp)
    80004038:	6d42                	ld	s10,16(sp)
    8000403a:	6da2                	ld	s11,8(sp)
    8000403c:	6165                	addi	sp,sp,112
    8000403e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004040:	89d6                	mv	s3,s5
    80004042:	bff1                	j	8000401e <readi+0xce>
    return 0;
    80004044:	4501                	li	a0,0
}
    80004046:	8082                	ret

0000000080004048 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004048:	457c                	lw	a5,76(a0)
    8000404a:	10d7e863          	bltu	a5,a3,8000415a <writei+0x112>
{
    8000404e:	7159                	addi	sp,sp,-112
    80004050:	f486                	sd	ra,104(sp)
    80004052:	f0a2                	sd	s0,96(sp)
    80004054:	eca6                	sd	s1,88(sp)
    80004056:	e8ca                	sd	s2,80(sp)
    80004058:	e4ce                	sd	s3,72(sp)
    8000405a:	e0d2                	sd	s4,64(sp)
    8000405c:	fc56                	sd	s5,56(sp)
    8000405e:	f85a                	sd	s6,48(sp)
    80004060:	f45e                	sd	s7,40(sp)
    80004062:	f062                	sd	s8,32(sp)
    80004064:	ec66                	sd	s9,24(sp)
    80004066:	e86a                	sd	s10,16(sp)
    80004068:	e46e                	sd	s11,8(sp)
    8000406a:	1880                	addi	s0,sp,112
    8000406c:	8aaa                	mv	s5,a0
    8000406e:	8bae                	mv	s7,a1
    80004070:	8a32                	mv	s4,a2
    80004072:	8936                	mv	s2,a3
    80004074:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80004076:	00e687bb          	addw	a5,a3,a4
    8000407a:	0ed7e263          	bltu	a5,a3,8000415e <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    8000407e:	00043737          	lui	a4,0x43
    80004082:	0ef76063          	bltu	a4,a5,80004162 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004086:	0c0b0863          	beqz	s6,80004156 <writei+0x10e>
    8000408a:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    8000408c:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80004090:	5c7d                	li	s8,-1
    80004092:	a091                	j	800040d6 <writei+0x8e>
    80004094:	020d1d93          	slli	s11,s10,0x20
    80004098:	020ddd93          	srli	s11,s11,0x20
    8000409c:	05848513          	addi	a0,s1,88
    800040a0:	86ee                	mv	a3,s11
    800040a2:	8652                	mv	a2,s4
    800040a4:	85de                	mv	a1,s7
    800040a6:	953a                	add	a0,a0,a4
    800040a8:	ffffe097          	auipc	ra,0xffffe
    800040ac:	748080e7          	jalr	1864(ra) # 800027f0 <either_copyin>
    800040b0:	07850263          	beq	a0,s8,80004114 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    800040b4:	8526                	mv	a0,s1
    800040b6:	00000097          	auipc	ra,0x0
    800040ba:	788080e7          	jalr	1928(ra) # 8000483e <log_write>
    brelse(bp);
    800040be:	8526                	mv	a0,s1
    800040c0:	fffff097          	auipc	ra,0xfffff
    800040c4:	4f4080e7          	jalr	1268(ra) # 800035b4 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800040c8:	013d09bb          	addw	s3,s10,s3
    800040cc:	012d093b          	addw	s2,s10,s2
    800040d0:	9a6e                	add	s4,s4,s11
    800040d2:	0569f663          	bgeu	s3,s6,8000411e <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    800040d6:	00a9559b          	srliw	a1,s2,0xa
    800040da:	8556                	mv	a0,s5
    800040dc:	fffff097          	auipc	ra,0xfffff
    800040e0:	79c080e7          	jalr	1948(ra) # 80003878 <bmap>
    800040e4:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    800040e8:	c99d                	beqz	a1,8000411e <writei+0xd6>
    bp = bread(ip->dev, addr);
    800040ea:	000aa503          	lw	a0,0(s5)
    800040ee:	fffff097          	auipc	ra,0xfffff
    800040f2:	396080e7          	jalr	918(ra) # 80003484 <bread>
    800040f6:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800040f8:	3ff97713          	andi	a4,s2,1023
    800040fc:	40ec87bb          	subw	a5,s9,a4
    80004100:	413b06bb          	subw	a3,s6,s3
    80004104:	8d3e                	mv	s10,a5
    80004106:	2781                	sext.w	a5,a5
    80004108:	0006861b          	sext.w	a2,a3
    8000410c:	f8f674e3          	bgeu	a2,a5,80004094 <writei+0x4c>
    80004110:	8d36                	mv	s10,a3
    80004112:	b749                	j	80004094 <writei+0x4c>
      brelse(bp);
    80004114:	8526                	mv	a0,s1
    80004116:	fffff097          	auipc	ra,0xfffff
    8000411a:	49e080e7          	jalr	1182(ra) # 800035b4 <brelse>
  }

  if(off > ip->size)
    8000411e:	04caa783          	lw	a5,76(s5)
    80004122:	0127f463          	bgeu	a5,s2,8000412a <writei+0xe2>
    ip->size = off;
    80004126:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    8000412a:	8556                	mv	a0,s5
    8000412c:	00000097          	auipc	ra,0x0
    80004130:	aa4080e7          	jalr	-1372(ra) # 80003bd0 <iupdate>

  return tot;
    80004134:	0009851b          	sext.w	a0,s3
}
    80004138:	70a6                	ld	ra,104(sp)
    8000413a:	7406                	ld	s0,96(sp)
    8000413c:	64e6                	ld	s1,88(sp)
    8000413e:	6946                	ld	s2,80(sp)
    80004140:	69a6                	ld	s3,72(sp)
    80004142:	6a06                	ld	s4,64(sp)
    80004144:	7ae2                	ld	s5,56(sp)
    80004146:	7b42                	ld	s6,48(sp)
    80004148:	7ba2                	ld	s7,40(sp)
    8000414a:	7c02                	ld	s8,32(sp)
    8000414c:	6ce2                	ld	s9,24(sp)
    8000414e:	6d42                	ld	s10,16(sp)
    80004150:	6da2                	ld	s11,8(sp)
    80004152:	6165                	addi	sp,sp,112
    80004154:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004156:	89da                	mv	s3,s6
    80004158:	bfc9                	j	8000412a <writei+0xe2>
    return -1;
    8000415a:	557d                	li	a0,-1
}
    8000415c:	8082                	ret
    return -1;
    8000415e:	557d                	li	a0,-1
    80004160:	bfe1                	j	80004138 <writei+0xf0>
    return -1;
    80004162:	557d                	li	a0,-1
    80004164:	bfd1                	j	80004138 <writei+0xf0>

0000000080004166 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004166:	1141                	addi	sp,sp,-16
    80004168:	e406                	sd	ra,8(sp)
    8000416a:	e022                	sd	s0,0(sp)
    8000416c:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    8000416e:	4639                	li	a2,14
    80004170:	ffffd097          	auipc	ra,0xffffd
    80004174:	c32080e7          	jalr	-974(ra) # 80000da2 <strncmp>
}
    80004178:	60a2                	ld	ra,8(sp)
    8000417a:	6402                	ld	s0,0(sp)
    8000417c:	0141                	addi	sp,sp,16
    8000417e:	8082                	ret

0000000080004180 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004180:	7139                	addi	sp,sp,-64
    80004182:	fc06                	sd	ra,56(sp)
    80004184:	f822                	sd	s0,48(sp)
    80004186:	f426                	sd	s1,40(sp)
    80004188:	f04a                	sd	s2,32(sp)
    8000418a:	ec4e                	sd	s3,24(sp)
    8000418c:	e852                	sd	s4,16(sp)
    8000418e:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004190:	04451703          	lh	a4,68(a0)
    80004194:	4785                	li	a5,1
    80004196:	00f71a63          	bne	a4,a5,800041aa <dirlookup+0x2a>
    8000419a:	892a                	mv	s2,a0
    8000419c:	89ae                	mv	s3,a1
    8000419e:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800041a0:	457c                	lw	a5,76(a0)
    800041a2:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800041a4:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800041a6:	e79d                	bnez	a5,800041d4 <dirlookup+0x54>
    800041a8:	a8a5                	j	80004220 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800041aa:	00004517          	auipc	a0,0x4
    800041ae:	66650513          	addi	a0,a0,1638 # 80008810 <systemCallsNames+0x1b8>
    800041b2:	ffffc097          	auipc	ra,0xffffc
    800041b6:	38e080e7          	jalr	910(ra) # 80000540 <panic>
      panic("dirlookup read");
    800041ba:	00004517          	auipc	a0,0x4
    800041be:	66e50513          	addi	a0,a0,1646 # 80008828 <systemCallsNames+0x1d0>
    800041c2:	ffffc097          	auipc	ra,0xffffc
    800041c6:	37e080e7          	jalr	894(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800041ca:	24c1                	addiw	s1,s1,16
    800041cc:	04c92783          	lw	a5,76(s2)
    800041d0:	04f4f763          	bgeu	s1,a5,8000421e <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800041d4:	4741                	li	a4,16
    800041d6:	86a6                	mv	a3,s1
    800041d8:	fc040613          	addi	a2,s0,-64
    800041dc:	4581                	li	a1,0
    800041de:	854a                	mv	a0,s2
    800041e0:	00000097          	auipc	ra,0x0
    800041e4:	d70080e7          	jalr	-656(ra) # 80003f50 <readi>
    800041e8:	47c1                	li	a5,16
    800041ea:	fcf518e3          	bne	a0,a5,800041ba <dirlookup+0x3a>
    if(de.inum == 0)
    800041ee:	fc045783          	lhu	a5,-64(s0)
    800041f2:	dfe1                	beqz	a5,800041ca <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    800041f4:	fc240593          	addi	a1,s0,-62
    800041f8:	854e                	mv	a0,s3
    800041fa:	00000097          	auipc	ra,0x0
    800041fe:	f6c080e7          	jalr	-148(ra) # 80004166 <namecmp>
    80004202:	f561                	bnez	a0,800041ca <dirlookup+0x4a>
      if(poff)
    80004204:	000a0463          	beqz	s4,8000420c <dirlookup+0x8c>
        *poff = off;
    80004208:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    8000420c:	fc045583          	lhu	a1,-64(s0)
    80004210:	00092503          	lw	a0,0(s2)
    80004214:	fffff097          	auipc	ra,0xfffff
    80004218:	74e080e7          	jalr	1870(ra) # 80003962 <iget>
    8000421c:	a011                	j	80004220 <dirlookup+0xa0>
  return 0;
    8000421e:	4501                	li	a0,0
}
    80004220:	70e2                	ld	ra,56(sp)
    80004222:	7442                	ld	s0,48(sp)
    80004224:	74a2                	ld	s1,40(sp)
    80004226:	7902                	ld	s2,32(sp)
    80004228:	69e2                	ld	s3,24(sp)
    8000422a:	6a42                	ld	s4,16(sp)
    8000422c:	6121                	addi	sp,sp,64
    8000422e:	8082                	ret

0000000080004230 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004230:	711d                	addi	sp,sp,-96
    80004232:	ec86                	sd	ra,88(sp)
    80004234:	e8a2                	sd	s0,80(sp)
    80004236:	e4a6                	sd	s1,72(sp)
    80004238:	e0ca                	sd	s2,64(sp)
    8000423a:	fc4e                	sd	s3,56(sp)
    8000423c:	f852                	sd	s4,48(sp)
    8000423e:	f456                	sd	s5,40(sp)
    80004240:	f05a                	sd	s6,32(sp)
    80004242:	ec5e                	sd	s7,24(sp)
    80004244:	e862                	sd	s8,16(sp)
    80004246:	e466                	sd	s9,8(sp)
    80004248:	e06a                	sd	s10,0(sp)
    8000424a:	1080                	addi	s0,sp,96
    8000424c:	84aa                	mv	s1,a0
    8000424e:	8b2e                	mv	s6,a1
    80004250:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004252:	00054703          	lbu	a4,0(a0)
    80004256:	02f00793          	li	a5,47
    8000425a:	02f70363          	beq	a4,a5,80004280 <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    8000425e:	ffffd097          	auipc	ra,0xffffd
    80004262:	74e080e7          	jalr	1870(ra) # 800019ac <myproc>
    80004266:	15053503          	ld	a0,336(a0)
    8000426a:	00000097          	auipc	ra,0x0
    8000426e:	9f4080e7          	jalr	-1548(ra) # 80003c5e <idup>
    80004272:	8a2a                	mv	s4,a0
  while(*path == '/')
    80004274:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80004278:	4cb5                	li	s9,13
  len = path - s;
    8000427a:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    8000427c:	4c05                	li	s8,1
    8000427e:	a87d                	j	8000433c <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    80004280:	4585                	li	a1,1
    80004282:	4505                	li	a0,1
    80004284:	fffff097          	auipc	ra,0xfffff
    80004288:	6de080e7          	jalr	1758(ra) # 80003962 <iget>
    8000428c:	8a2a                	mv	s4,a0
    8000428e:	b7dd                	j	80004274 <namex+0x44>
      iunlockput(ip);
    80004290:	8552                	mv	a0,s4
    80004292:	00000097          	auipc	ra,0x0
    80004296:	c6c080e7          	jalr	-916(ra) # 80003efe <iunlockput>
      return 0;
    8000429a:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    8000429c:	8552                	mv	a0,s4
    8000429e:	60e6                	ld	ra,88(sp)
    800042a0:	6446                	ld	s0,80(sp)
    800042a2:	64a6                	ld	s1,72(sp)
    800042a4:	6906                	ld	s2,64(sp)
    800042a6:	79e2                	ld	s3,56(sp)
    800042a8:	7a42                	ld	s4,48(sp)
    800042aa:	7aa2                	ld	s5,40(sp)
    800042ac:	7b02                	ld	s6,32(sp)
    800042ae:	6be2                	ld	s7,24(sp)
    800042b0:	6c42                	ld	s8,16(sp)
    800042b2:	6ca2                	ld	s9,8(sp)
    800042b4:	6d02                	ld	s10,0(sp)
    800042b6:	6125                	addi	sp,sp,96
    800042b8:	8082                	ret
      iunlock(ip);
    800042ba:	8552                	mv	a0,s4
    800042bc:	00000097          	auipc	ra,0x0
    800042c0:	aa2080e7          	jalr	-1374(ra) # 80003d5e <iunlock>
      return ip;
    800042c4:	bfe1                	j	8000429c <namex+0x6c>
      iunlockput(ip);
    800042c6:	8552                	mv	a0,s4
    800042c8:	00000097          	auipc	ra,0x0
    800042cc:	c36080e7          	jalr	-970(ra) # 80003efe <iunlockput>
      return 0;
    800042d0:	8a4e                	mv	s4,s3
    800042d2:	b7e9                	j	8000429c <namex+0x6c>
  len = path - s;
    800042d4:	40998633          	sub	a2,s3,s1
    800042d8:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    800042dc:	09acd863          	bge	s9,s10,8000436c <namex+0x13c>
    memmove(name, s, DIRSIZ);
    800042e0:	4639                	li	a2,14
    800042e2:	85a6                	mv	a1,s1
    800042e4:	8556                	mv	a0,s5
    800042e6:	ffffd097          	auipc	ra,0xffffd
    800042ea:	a48080e7          	jalr	-1464(ra) # 80000d2e <memmove>
    800042ee:	84ce                	mv	s1,s3
  while(*path == '/')
    800042f0:	0004c783          	lbu	a5,0(s1)
    800042f4:	01279763          	bne	a5,s2,80004302 <namex+0xd2>
    path++;
    800042f8:	0485                	addi	s1,s1,1
  while(*path == '/')
    800042fa:	0004c783          	lbu	a5,0(s1)
    800042fe:	ff278de3          	beq	a5,s2,800042f8 <namex+0xc8>
    ilock(ip);
    80004302:	8552                	mv	a0,s4
    80004304:	00000097          	auipc	ra,0x0
    80004308:	998080e7          	jalr	-1640(ra) # 80003c9c <ilock>
    if(ip->type != T_DIR){
    8000430c:	044a1783          	lh	a5,68(s4)
    80004310:	f98790e3          	bne	a5,s8,80004290 <namex+0x60>
    if(nameiparent && *path == '\0'){
    80004314:	000b0563          	beqz	s6,8000431e <namex+0xee>
    80004318:	0004c783          	lbu	a5,0(s1)
    8000431c:	dfd9                	beqz	a5,800042ba <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    8000431e:	865e                	mv	a2,s7
    80004320:	85d6                	mv	a1,s5
    80004322:	8552                	mv	a0,s4
    80004324:	00000097          	auipc	ra,0x0
    80004328:	e5c080e7          	jalr	-420(ra) # 80004180 <dirlookup>
    8000432c:	89aa                	mv	s3,a0
    8000432e:	dd41                	beqz	a0,800042c6 <namex+0x96>
    iunlockput(ip);
    80004330:	8552                	mv	a0,s4
    80004332:	00000097          	auipc	ra,0x0
    80004336:	bcc080e7          	jalr	-1076(ra) # 80003efe <iunlockput>
    ip = next;
    8000433a:	8a4e                	mv	s4,s3
  while(*path == '/')
    8000433c:	0004c783          	lbu	a5,0(s1)
    80004340:	01279763          	bne	a5,s2,8000434e <namex+0x11e>
    path++;
    80004344:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004346:	0004c783          	lbu	a5,0(s1)
    8000434a:	ff278de3          	beq	a5,s2,80004344 <namex+0x114>
  if(*path == 0)
    8000434e:	cb9d                	beqz	a5,80004384 <namex+0x154>
  while(*path != '/' && *path != 0)
    80004350:	0004c783          	lbu	a5,0(s1)
    80004354:	89a6                	mv	s3,s1
  len = path - s;
    80004356:	8d5e                	mv	s10,s7
    80004358:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    8000435a:	01278963          	beq	a5,s2,8000436c <namex+0x13c>
    8000435e:	dbbd                	beqz	a5,800042d4 <namex+0xa4>
    path++;
    80004360:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80004362:	0009c783          	lbu	a5,0(s3)
    80004366:	ff279ce3          	bne	a5,s2,8000435e <namex+0x12e>
    8000436a:	b7ad                	j	800042d4 <namex+0xa4>
    memmove(name, s, len);
    8000436c:	2601                	sext.w	a2,a2
    8000436e:	85a6                	mv	a1,s1
    80004370:	8556                	mv	a0,s5
    80004372:	ffffd097          	auipc	ra,0xffffd
    80004376:	9bc080e7          	jalr	-1604(ra) # 80000d2e <memmove>
    name[len] = 0;
    8000437a:	9d56                	add	s10,s10,s5
    8000437c:	000d0023          	sb	zero,0(s10)
    80004380:	84ce                	mv	s1,s3
    80004382:	b7bd                	j	800042f0 <namex+0xc0>
  if(nameiparent){
    80004384:	f00b0ce3          	beqz	s6,8000429c <namex+0x6c>
    iput(ip);
    80004388:	8552                	mv	a0,s4
    8000438a:	00000097          	auipc	ra,0x0
    8000438e:	acc080e7          	jalr	-1332(ra) # 80003e56 <iput>
    return 0;
    80004392:	4a01                	li	s4,0
    80004394:	b721                	j	8000429c <namex+0x6c>

0000000080004396 <dirlink>:
{
    80004396:	7139                	addi	sp,sp,-64
    80004398:	fc06                	sd	ra,56(sp)
    8000439a:	f822                	sd	s0,48(sp)
    8000439c:	f426                	sd	s1,40(sp)
    8000439e:	f04a                	sd	s2,32(sp)
    800043a0:	ec4e                	sd	s3,24(sp)
    800043a2:	e852                	sd	s4,16(sp)
    800043a4:	0080                	addi	s0,sp,64
    800043a6:	892a                	mv	s2,a0
    800043a8:	8a2e                	mv	s4,a1
    800043aa:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800043ac:	4601                	li	a2,0
    800043ae:	00000097          	auipc	ra,0x0
    800043b2:	dd2080e7          	jalr	-558(ra) # 80004180 <dirlookup>
    800043b6:	e93d                	bnez	a0,8000442c <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800043b8:	04c92483          	lw	s1,76(s2)
    800043bc:	c49d                	beqz	s1,800043ea <dirlink+0x54>
    800043be:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800043c0:	4741                	li	a4,16
    800043c2:	86a6                	mv	a3,s1
    800043c4:	fc040613          	addi	a2,s0,-64
    800043c8:	4581                	li	a1,0
    800043ca:	854a                	mv	a0,s2
    800043cc:	00000097          	auipc	ra,0x0
    800043d0:	b84080e7          	jalr	-1148(ra) # 80003f50 <readi>
    800043d4:	47c1                	li	a5,16
    800043d6:	06f51163          	bne	a0,a5,80004438 <dirlink+0xa2>
    if(de.inum == 0)
    800043da:	fc045783          	lhu	a5,-64(s0)
    800043de:	c791                	beqz	a5,800043ea <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800043e0:	24c1                	addiw	s1,s1,16
    800043e2:	04c92783          	lw	a5,76(s2)
    800043e6:	fcf4ede3          	bltu	s1,a5,800043c0 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800043ea:	4639                	li	a2,14
    800043ec:	85d2                	mv	a1,s4
    800043ee:	fc240513          	addi	a0,s0,-62
    800043f2:	ffffd097          	auipc	ra,0xffffd
    800043f6:	9ec080e7          	jalr	-1556(ra) # 80000dde <strncpy>
  de.inum = inum;
    800043fa:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800043fe:	4741                	li	a4,16
    80004400:	86a6                	mv	a3,s1
    80004402:	fc040613          	addi	a2,s0,-64
    80004406:	4581                	li	a1,0
    80004408:	854a                	mv	a0,s2
    8000440a:	00000097          	auipc	ra,0x0
    8000440e:	c3e080e7          	jalr	-962(ra) # 80004048 <writei>
    80004412:	1541                	addi	a0,a0,-16
    80004414:	00a03533          	snez	a0,a0
    80004418:	40a00533          	neg	a0,a0
}
    8000441c:	70e2                	ld	ra,56(sp)
    8000441e:	7442                	ld	s0,48(sp)
    80004420:	74a2                	ld	s1,40(sp)
    80004422:	7902                	ld	s2,32(sp)
    80004424:	69e2                	ld	s3,24(sp)
    80004426:	6a42                	ld	s4,16(sp)
    80004428:	6121                	addi	sp,sp,64
    8000442a:	8082                	ret
    iput(ip);
    8000442c:	00000097          	auipc	ra,0x0
    80004430:	a2a080e7          	jalr	-1494(ra) # 80003e56 <iput>
    return -1;
    80004434:	557d                	li	a0,-1
    80004436:	b7dd                	j	8000441c <dirlink+0x86>
      panic("dirlink read");
    80004438:	00004517          	auipc	a0,0x4
    8000443c:	40050513          	addi	a0,a0,1024 # 80008838 <systemCallsNames+0x1e0>
    80004440:	ffffc097          	auipc	ra,0xffffc
    80004444:	100080e7          	jalr	256(ra) # 80000540 <panic>

0000000080004448 <namei>:

struct inode*
namei(char *path)
{
    80004448:	1101                	addi	sp,sp,-32
    8000444a:	ec06                	sd	ra,24(sp)
    8000444c:	e822                	sd	s0,16(sp)
    8000444e:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004450:	fe040613          	addi	a2,s0,-32
    80004454:	4581                	li	a1,0
    80004456:	00000097          	auipc	ra,0x0
    8000445a:	dda080e7          	jalr	-550(ra) # 80004230 <namex>
}
    8000445e:	60e2                	ld	ra,24(sp)
    80004460:	6442                	ld	s0,16(sp)
    80004462:	6105                	addi	sp,sp,32
    80004464:	8082                	ret

0000000080004466 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004466:	1141                	addi	sp,sp,-16
    80004468:	e406                	sd	ra,8(sp)
    8000446a:	e022                	sd	s0,0(sp)
    8000446c:	0800                	addi	s0,sp,16
    8000446e:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004470:	4585                	li	a1,1
    80004472:	00000097          	auipc	ra,0x0
    80004476:	dbe080e7          	jalr	-578(ra) # 80004230 <namex>
}
    8000447a:	60a2                	ld	ra,8(sp)
    8000447c:	6402                	ld	s0,0(sp)
    8000447e:	0141                	addi	sp,sp,16
    80004480:	8082                	ret

0000000080004482 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004482:	1101                	addi	sp,sp,-32
    80004484:	ec06                	sd	ra,24(sp)
    80004486:	e822                	sd	s0,16(sp)
    80004488:	e426                	sd	s1,8(sp)
    8000448a:	e04a                	sd	s2,0(sp)
    8000448c:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000448e:	0001e917          	auipc	s2,0x1e
    80004492:	91290913          	addi	s2,s2,-1774 # 80021da0 <log>
    80004496:	01892583          	lw	a1,24(s2)
    8000449a:	02892503          	lw	a0,40(s2)
    8000449e:	fffff097          	auipc	ra,0xfffff
    800044a2:	fe6080e7          	jalr	-26(ra) # 80003484 <bread>
    800044a6:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800044a8:	02c92683          	lw	a3,44(s2)
    800044ac:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800044ae:	02d05863          	blez	a3,800044de <write_head+0x5c>
    800044b2:	0001e797          	auipc	a5,0x1e
    800044b6:	91e78793          	addi	a5,a5,-1762 # 80021dd0 <log+0x30>
    800044ba:	05c50713          	addi	a4,a0,92
    800044be:	36fd                	addiw	a3,a3,-1
    800044c0:	02069613          	slli	a2,a3,0x20
    800044c4:	01e65693          	srli	a3,a2,0x1e
    800044c8:	0001e617          	auipc	a2,0x1e
    800044cc:	90c60613          	addi	a2,a2,-1780 # 80021dd4 <log+0x34>
    800044d0:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800044d2:	4390                	lw	a2,0(a5)
    800044d4:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800044d6:	0791                	addi	a5,a5,4
    800044d8:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    800044da:	fed79ce3          	bne	a5,a3,800044d2 <write_head+0x50>
  }
  bwrite(buf);
    800044de:	8526                	mv	a0,s1
    800044e0:	fffff097          	auipc	ra,0xfffff
    800044e4:	096080e7          	jalr	150(ra) # 80003576 <bwrite>
  brelse(buf);
    800044e8:	8526                	mv	a0,s1
    800044ea:	fffff097          	auipc	ra,0xfffff
    800044ee:	0ca080e7          	jalr	202(ra) # 800035b4 <brelse>
}
    800044f2:	60e2                	ld	ra,24(sp)
    800044f4:	6442                	ld	s0,16(sp)
    800044f6:	64a2                	ld	s1,8(sp)
    800044f8:	6902                	ld	s2,0(sp)
    800044fa:	6105                	addi	sp,sp,32
    800044fc:	8082                	ret

00000000800044fe <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800044fe:	0001e797          	auipc	a5,0x1e
    80004502:	8ce7a783          	lw	a5,-1842(a5) # 80021dcc <log+0x2c>
    80004506:	0af05d63          	blez	a5,800045c0 <install_trans+0xc2>
{
    8000450a:	7139                	addi	sp,sp,-64
    8000450c:	fc06                	sd	ra,56(sp)
    8000450e:	f822                	sd	s0,48(sp)
    80004510:	f426                	sd	s1,40(sp)
    80004512:	f04a                	sd	s2,32(sp)
    80004514:	ec4e                	sd	s3,24(sp)
    80004516:	e852                	sd	s4,16(sp)
    80004518:	e456                	sd	s5,8(sp)
    8000451a:	e05a                	sd	s6,0(sp)
    8000451c:	0080                	addi	s0,sp,64
    8000451e:	8b2a                	mv	s6,a0
    80004520:	0001ea97          	auipc	s5,0x1e
    80004524:	8b0a8a93          	addi	s5,s5,-1872 # 80021dd0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004528:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000452a:	0001e997          	auipc	s3,0x1e
    8000452e:	87698993          	addi	s3,s3,-1930 # 80021da0 <log>
    80004532:	a00d                	j	80004554 <install_trans+0x56>
    brelse(lbuf);
    80004534:	854a                	mv	a0,s2
    80004536:	fffff097          	auipc	ra,0xfffff
    8000453a:	07e080e7          	jalr	126(ra) # 800035b4 <brelse>
    brelse(dbuf);
    8000453e:	8526                	mv	a0,s1
    80004540:	fffff097          	auipc	ra,0xfffff
    80004544:	074080e7          	jalr	116(ra) # 800035b4 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004548:	2a05                	addiw	s4,s4,1
    8000454a:	0a91                	addi	s5,s5,4
    8000454c:	02c9a783          	lw	a5,44(s3)
    80004550:	04fa5e63          	bge	s4,a5,800045ac <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004554:	0189a583          	lw	a1,24(s3)
    80004558:	014585bb          	addw	a1,a1,s4
    8000455c:	2585                	addiw	a1,a1,1
    8000455e:	0289a503          	lw	a0,40(s3)
    80004562:	fffff097          	auipc	ra,0xfffff
    80004566:	f22080e7          	jalr	-222(ra) # 80003484 <bread>
    8000456a:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000456c:	000aa583          	lw	a1,0(s5)
    80004570:	0289a503          	lw	a0,40(s3)
    80004574:	fffff097          	auipc	ra,0xfffff
    80004578:	f10080e7          	jalr	-240(ra) # 80003484 <bread>
    8000457c:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000457e:	40000613          	li	a2,1024
    80004582:	05890593          	addi	a1,s2,88
    80004586:	05850513          	addi	a0,a0,88
    8000458a:	ffffc097          	auipc	ra,0xffffc
    8000458e:	7a4080e7          	jalr	1956(ra) # 80000d2e <memmove>
    bwrite(dbuf);  // write dst to disk
    80004592:	8526                	mv	a0,s1
    80004594:	fffff097          	auipc	ra,0xfffff
    80004598:	fe2080e7          	jalr	-30(ra) # 80003576 <bwrite>
    if(recovering == 0)
    8000459c:	f80b1ce3          	bnez	s6,80004534 <install_trans+0x36>
      bunpin(dbuf);
    800045a0:	8526                	mv	a0,s1
    800045a2:	fffff097          	auipc	ra,0xfffff
    800045a6:	0ec080e7          	jalr	236(ra) # 8000368e <bunpin>
    800045aa:	b769                	j	80004534 <install_trans+0x36>
}
    800045ac:	70e2                	ld	ra,56(sp)
    800045ae:	7442                	ld	s0,48(sp)
    800045b0:	74a2                	ld	s1,40(sp)
    800045b2:	7902                	ld	s2,32(sp)
    800045b4:	69e2                	ld	s3,24(sp)
    800045b6:	6a42                	ld	s4,16(sp)
    800045b8:	6aa2                	ld	s5,8(sp)
    800045ba:	6b02                	ld	s6,0(sp)
    800045bc:	6121                	addi	sp,sp,64
    800045be:	8082                	ret
    800045c0:	8082                	ret

00000000800045c2 <initlog>:
{
    800045c2:	7179                	addi	sp,sp,-48
    800045c4:	f406                	sd	ra,40(sp)
    800045c6:	f022                	sd	s0,32(sp)
    800045c8:	ec26                	sd	s1,24(sp)
    800045ca:	e84a                	sd	s2,16(sp)
    800045cc:	e44e                	sd	s3,8(sp)
    800045ce:	1800                	addi	s0,sp,48
    800045d0:	892a                	mv	s2,a0
    800045d2:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800045d4:	0001d497          	auipc	s1,0x1d
    800045d8:	7cc48493          	addi	s1,s1,1996 # 80021da0 <log>
    800045dc:	00004597          	auipc	a1,0x4
    800045e0:	26c58593          	addi	a1,a1,620 # 80008848 <systemCallsNames+0x1f0>
    800045e4:	8526                	mv	a0,s1
    800045e6:	ffffc097          	auipc	ra,0xffffc
    800045ea:	560080e7          	jalr	1376(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    800045ee:	0149a583          	lw	a1,20(s3)
    800045f2:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800045f4:	0109a783          	lw	a5,16(s3)
    800045f8:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800045fa:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800045fe:	854a                	mv	a0,s2
    80004600:	fffff097          	auipc	ra,0xfffff
    80004604:	e84080e7          	jalr	-380(ra) # 80003484 <bread>
  log.lh.n = lh->n;
    80004608:	4d34                	lw	a3,88(a0)
    8000460a:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000460c:	02d05663          	blez	a3,80004638 <initlog+0x76>
    80004610:	05c50793          	addi	a5,a0,92
    80004614:	0001d717          	auipc	a4,0x1d
    80004618:	7bc70713          	addi	a4,a4,1980 # 80021dd0 <log+0x30>
    8000461c:	36fd                	addiw	a3,a3,-1
    8000461e:	02069613          	slli	a2,a3,0x20
    80004622:	01e65693          	srli	a3,a2,0x1e
    80004626:	06050613          	addi	a2,a0,96
    8000462a:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    8000462c:	4390                	lw	a2,0(a5)
    8000462e:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004630:	0791                	addi	a5,a5,4
    80004632:	0711                	addi	a4,a4,4
    80004634:	fed79ce3          	bne	a5,a3,8000462c <initlog+0x6a>
  brelse(buf);
    80004638:	fffff097          	auipc	ra,0xfffff
    8000463c:	f7c080e7          	jalr	-132(ra) # 800035b4 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004640:	4505                	li	a0,1
    80004642:	00000097          	auipc	ra,0x0
    80004646:	ebc080e7          	jalr	-324(ra) # 800044fe <install_trans>
  log.lh.n = 0;
    8000464a:	0001d797          	auipc	a5,0x1d
    8000464e:	7807a123          	sw	zero,1922(a5) # 80021dcc <log+0x2c>
  write_head(); // clear the log
    80004652:	00000097          	auipc	ra,0x0
    80004656:	e30080e7          	jalr	-464(ra) # 80004482 <write_head>
}
    8000465a:	70a2                	ld	ra,40(sp)
    8000465c:	7402                	ld	s0,32(sp)
    8000465e:	64e2                	ld	s1,24(sp)
    80004660:	6942                	ld	s2,16(sp)
    80004662:	69a2                	ld	s3,8(sp)
    80004664:	6145                	addi	sp,sp,48
    80004666:	8082                	ret

0000000080004668 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004668:	1101                	addi	sp,sp,-32
    8000466a:	ec06                	sd	ra,24(sp)
    8000466c:	e822                	sd	s0,16(sp)
    8000466e:	e426                	sd	s1,8(sp)
    80004670:	e04a                	sd	s2,0(sp)
    80004672:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004674:	0001d517          	auipc	a0,0x1d
    80004678:	72c50513          	addi	a0,a0,1836 # 80021da0 <log>
    8000467c:	ffffc097          	auipc	ra,0xffffc
    80004680:	55a080e7          	jalr	1370(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    80004684:	0001d497          	auipc	s1,0x1d
    80004688:	71c48493          	addi	s1,s1,1820 # 80021da0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000468c:	4979                	li	s2,30
    8000468e:	a039                	j	8000469c <begin_op+0x34>
      sleep(&log, &log.lock);
    80004690:	85a6                	mv	a1,s1
    80004692:	8526                	mv	a0,s1
    80004694:	ffffe097          	auipc	ra,0xffffe
    80004698:	ba6080e7          	jalr	-1114(ra) # 8000223a <sleep>
    if(log.committing){
    8000469c:	50dc                	lw	a5,36(s1)
    8000469e:	fbed                	bnez	a5,80004690 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800046a0:	5098                	lw	a4,32(s1)
    800046a2:	2705                	addiw	a4,a4,1
    800046a4:	0007069b          	sext.w	a3,a4
    800046a8:	0027179b          	slliw	a5,a4,0x2
    800046ac:	9fb9                	addw	a5,a5,a4
    800046ae:	0017979b          	slliw	a5,a5,0x1
    800046b2:	54d8                	lw	a4,44(s1)
    800046b4:	9fb9                	addw	a5,a5,a4
    800046b6:	00f95963          	bge	s2,a5,800046c8 <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800046ba:	85a6                	mv	a1,s1
    800046bc:	8526                	mv	a0,s1
    800046be:	ffffe097          	auipc	ra,0xffffe
    800046c2:	b7c080e7          	jalr	-1156(ra) # 8000223a <sleep>
    800046c6:	bfd9                	j	8000469c <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800046c8:	0001d517          	auipc	a0,0x1d
    800046cc:	6d850513          	addi	a0,a0,1752 # 80021da0 <log>
    800046d0:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800046d2:	ffffc097          	auipc	ra,0xffffc
    800046d6:	5b8080e7          	jalr	1464(ra) # 80000c8a <release>
      break;
    }
  }
}
    800046da:	60e2                	ld	ra,24(sp)
    800046dc:	6442                	ld	s0,16(sp)
    800046de:	64a2                	ld	s1,8(sp)
    800046e0:	6902                	ld	s2,0(sp)
    800046e2:	6105                	addi	sp,sp,32
    800046e4:	8082                	ret

00000000800046e6 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800046e6:	7139                	addi	sp,sp,-64
    800046e8:	fc06                	sd	ra,56(sp)
    800046ea:	f822                	sd	s0,48(sp)
    800046ec:	f426                	sd	s1,40(sp)
    800046ee:	f04a                	sd	s2,32(sp)
    800046f0:	ec4e                	sd	s3,24(sp)
    800046f2:	e852                	sd	s4,16(sp)
    800046f4:	e456                	sd	s5,8(sp)
    800046f6:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800046f8:	0001d497          	auipc	s1,0x1d
    800046fc:	6a848493          	addi	s1,s1,1704 # 80021da0 <log>
    80004700:	8526                	mv	a0,s1
    80004702:	ffffc097          	auipc	ra,0xffffc
    80004706:	4d4080e7          	jalr	1236(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    8000470a:	509c                	lw	a5,32(s1)
    8000470c:	37fd                	addiw	a5,a5,-1
    8000470e:	0007891b          	sext.w	s2,a5
    80004712:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004714:	50dc                	lw	a5,36(s1)
    80004716:	e7b9                	bnez	a5,80004764 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004718:	04091e63          	bnez	s2,80004774 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    8000471c:	0001d497          	auipc	s1,0x1d
    80004720:	68448493          	addi	s1,s1,1668 # 80021da0 <log>
    80004724:	4785                	li	a5,1
    80004726:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004728:	8526                	mv	a0,s1
    8000472a:	ffffc097          	auipc	ra,0xffffc
    8000472e:	560080e7          	jalr	1376(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004732:	54dc                	lw	a5,44(s1)
    80004734:	06f04763          	bgtz	a5,800047a2 <end_op+0xbc>
    acquire(&log.lock);
    80004738:	0001d497          	auipc	s1,0x1d
    8000473c:	66848493          	addi	s1,s1,1640 # 80021da0 <log>
    80004740:	8526                	mv	a0,s1
    80004742:	ffffc097          	auipc	ra,0xffffc
    80004746:	494080e7          	jalr	1172(ra) # 80000bd6 <acquire>
    log.committing = 0;
    8000474a:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000474e:	8526                	mv	a0,s1
    80004750:	ffffe097          	auipc	ra,0xffffe
    80004754:	c9a080e7          	jalr	-870(ra) # 800023ea <wakeup>
    release(&log.lock);
    80004758:	8526                	mv	a0,s1
    8000475a:	ffffc097          	auipc	ra,0xffffc
    8000475e:	530080e7          	jalr	1328(ra) # 80000c8a <release>
}
    80004762:	a03d                	j	80004790 <end_op+0xaa>
    panic("log.committing");
    80004764:	00004517          	auipc	a0,0x4
    80004768:	0ec50513          	addi	a0,a0,236 # 80008850 <systemCallsNames+0x1f8>
    8000476c:	ffffc097          	auipc	ra,0xffffc
    80004770:	dd4080e7          	jalr	-556(ra) # 80000540 <panic>
    wakeup(&log);
    80004774:	0001d497          	auipc	s1,0x1d
    80004778:	62c48493          	addi	s1,s1,1580 # 80021da0 <log>
    8000477c:	8526                	mv	a0,s1
    8000477e:	ffffe097          	auipc	ra,0xffffe
    80004782:	c6c080e7          	jalr	-916(ra) # 800023ea <wakeup>
  release(&log.lock);
    80004786:	8526                	mv	a0,s1
    80004788:	ffffc097          	auipc	ra,0xffffc
    8000478c:	502080e7          	jalr	1282(ra) # 80000c8a <release>
}
    80004790:	70e2                	ld	ra,56(sp)
    80004792:	7442                	ld	s0,48(sp)
    80004794:	74a2                	ld	s1,40(sp)
    80004796:	7902                	ld	s2,32(sp)
    80004798:	69e2                	ld	s3,24(sp)
    8000479a:	6a42                	ld	s4,16(sp)
    8000479c:	6aa2                	ld	s5,8(sp)
    8000479e:	6121                	addi	sp,sp,64
    800047a0:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800047a2:	0001da97          	auipc	s5,0x1d
    800047a6:	62ea8a93          	addi	s5,s5,1582 # 80021dd0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800047aa:	0001da17          	auipc	s4,0x1d
    800047ae:	5f6a0a13          	addi	s4,s4,1526 # 80021da0 <log>
    800047b2:	018a2583          	lw	a1,24(s4)
    800047b6:	012585bb          	addw	a1,a1,s2
    800047ba:	2585                	addiw	a1,a1,1
    800047bc:	028a2503          	lw	a0,40(s4)
    800047c0:	fffff097          	auipc	ra,0xfffff
    800047c4:	cc4080e7          	jalr	-828(ra) # 80003484 <bread>
    800047c8:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800047ca:	000aa583          	lw	a1,0(s5)
    800047ce:	028a2503          	lw	a0,40(s4)
    800047d2:	fffff097          	auipc	ra,0xfffff
    800047d6:	cb2080e7          	jalr	-846(ra) # 80003484 <bread>
    800047da:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800047dc:	40000613          	li	a2,1024
    800047e0:	05850593          	addi	a1,a0,88
    800047e4:	05848513          	addi	a0,s1,88
    800047e8:	ffffc097          	auipc	ra,0xffffc
    800047ec:	546080e7          	jalr	1350(ra) # 80000d2e <memmove>
    bwrite(to);  // write the log
    800047f0:	8526                	mv	a0,s1
    800047f2:	fffff097          	auipc	ra,0xfffff
    800047f6:	d84080e7          	jalr	-636(ra) # 80003576 <bwrite>
    brelse(from);
    800047fa:	854e                	mv	a0,s3
    800047fc:	fffff097          	auipc	ra,0xfffff
    80004800:	db8080e7          	jalr	-584(ra) # 800035b4 <brelse>
    brelse(to);
    80004804:	8526                	mv	a0,s1
    80004806:	fffff097          	auipc	ra,0xfffff
    8000480a:	dae080e7          	jalr	-594(ra) # 800035b4 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000480e:	2905                	addiw	s2,s2,1
    80004810:	0a91                	addi	s5,s5,4
    80004812:	02ca2783          	lw	a5,44(s4)
    80004816:	f8f94ee3          	blt	s2,a5,800047b2 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000481a:	00000097          	auipc	ra,0x0
    8000481e:	c68080e7          	jalr	-920(ra) # 80004482 <write_head>
    install_trans(0); // Now install writes to home locations
    80004822:	4501                	li	a0,0
    80004824:	00000097          	auipc	ra,0x0
    80004828:	cda080e7          	jalr	-806(ra) # 800044fe <install_trans>
    log.lh.n = 0;
    8000482c:	0001d797          	auipc	a5,0x1d
    80004830:	5a07a023          	sw	zero,1440(a5) # 80021dcc <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004834:	00000097          	auipc	ra,0x0
    80004838:	c4e080e7          	jalr	-946(ra) # 80004482 <write_head>
    8000483c:	bdf5                	j	80004738 <end_op+0x52>

000000008000483e <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000483e:	1101                	addi	sp,sp,-32
    80004840:	ec06                	sd	ra,24(sp)
    80004842:	e822                	sd	s0,16(sp)
    80004844:	e426                	sd	s1,8(sp)
    80004846:	e04a                	sd	s2,0(sp)
    80004848:	1000                	addi	s0,sp,32
    8000484a:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    8000484c:	0001d917          	auipc	s2,0x1d
    80004850:	55490913          	addi	s2,s2,1364 # 80021da0 <log>
    80004854:	854a                	mv	a0,s2
    80004856:	ffffc097          	auipc	ra,0xffffc
    8000485a:	380080e7          	jalr	896(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000485e:	02c92603          	lw	a2,44(s2)
    80004862:	47f5                	li	a5,29
    80004864:	06c7c563          	blt	a5,a2,800048ce <log_write+0x90>
    80004868:	0001d797          	auipc	a5,0x1d
    8000486c:	5547a783          	lw	a5,1364(a5) # 80021dbc <log+0x1c>
    80004870:	37fd                	addiw	a5,a5,-1
    80004872:	04f65e63          	bge	a2,a5,800048ce <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004876:	0001d797          	auipc	a5,0x1d
    8000487a:	54a7a783          	lw	a5,1354(a5) # 80021dc0 <log+0x20>
    8000487e:	06f05063          	blez	a5,800048de <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004882:	4781                	li	a5,0
    80004884:	06c05563          	blez	a2,800048ee <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004888:	44cc                	lw	a1,12(s1)
    8000488a:	0001d717          	auipc	a4,0x1d
    8000488e:	54670713          	addi	a4,a4,1350 # 80021dd0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004892:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004894:	4314                	lw	a3,0(a4)
    80004896:	04b68c63          	beq	a3,a1,800048ee <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000489a:	2785                	addiw	a5,a5,1
    8000489c:	0711                	addi	a4,a4,4
    8000489e:	fef61be3          	bne	a2,a5,80004894 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800048a2:	0621                	addi	a2,a2,8
    800048a4:	060a                	slli	a2,a2,0x2
    800048a6:	0001d797          	auipc	a5,0x1d
    800048aa:	4fa78793          	addi	a5,a5,1274 # 80021da0 <log>
    800048ae:	97b2                	add	a5,a5,a2
    800048b0:	44d8                	lw	a4,12(s1)
    800048b2:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800048b4:	8526                	mv	a0,s1
    800048b6:	fffff097          	auipc	ra,0xfffff
    800048ba:	d9c080e7          	jalr	-612(ra) # 80003652 <bpin>
    log.lh.n++;
    800048be:	0001d717          	auipc	a4,0x1d
    800048c2:	4e270713          	addi	a4,a4,1250 # 80021da0 <log>
    800048c6:	575c                	lw	a5,44(a4)
    800048c8:	2785                	addiw	a5,a5,1
    800048ca:	d75c                	sw	a5,44(a4)
    800048cc:	a82d                	j	80004906 <log_write+0xc8>
    panic("too big a transaction");
    800048ce:	00004517          	auipc	a0,0x4
    800048d2:	f9250513          	addi	a0,a0,-110 # 80008860 <systemCallsNames+0x208>
    800048d6:	ffffc097          	auipc	ra,0xffffc
    800048da:	c6a080e7          	jalr	-918(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    800048de:	00004517          	auipc	a0,0x4
    800048e2:	f9a50513          	addi	a0,a0,-102 # 80008878 <systemCallsNames+0x220>
    800048e6:	ffffc097          	auipc	ra,0xffffc
    800048ea:	c5a080e7          	jalr	-934(ra) # 80000540 <panic>
  log.lh.block[i] = b->blockno;
    800048ee:	00878693          	addi	a3,a5,8
    800048f2:	068a                	slli	a3,a3,0x2
    800048f4:	0001d717          	auipc	a4,0x1d
    800048f8:	4ac70713          	addi	a4,a4,1196 # 80021da0 <log>
    800048fc:	9736                	add	a4,a4,a3
    800048fe:	44d4                	lw	a3,12(s1)
    80004900:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004902:	faf609e3          	beq	a2,a5,800048b4 <log_write+0x76>
  }
  release(&log.lock);
    80004906:	0001d517          	auipc	a0,0x1d
    8000490a:	49a50513          	addi	a0,a0,1178 # 80021da0 <log>
    8000490e:	ffffc097          	auipc	ra,0xffffc
    80004912:	37c080e7          	jalr	892(ra) # 80000c8a <release>
}
    80004916:	60e2                	ld	ra,24(sp)
    80004918:	6442                	ld	s0,16(sp)
    8000491a:	64a2                	ld	s1,8(sp)
    8000491c:	6902                	ld	s2,0(sp)
    8000491e:	6105                	addi	sp,sp,32
    80004920:	8082                	ret

0000000080004922 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004922:	1101                	addi	sp,sp,-32
    80004924:	ec06                	sd	ra,24(sp)
    80004926:	e822                	sd	s0,16(sp)
    80004928:	e426                	sd	s1,8(sp)
    8000492a:	e04a                	sd	s2,0(sp)
    8000492c:	1000                	addi	s0,sp,32
    8000492e:	84aa                	mv	s1,a0
    80004930:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004932:	00004597          	auipc	a1,0x4
    80004936:	f6658593          	addi	a1,a1,-154 # 80008898 <systemCallsNames+0x240>
    8000493a:	0521                	addi	a0,a0,8
    8000493c:	ffffc097          	auipc	ra,0xffffc
    80004940:	20a080e7          	jalr	522(ra) # 80000b46 <initlock>
  lk->name = name;
    80004944:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004948:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000494c:	0204a423          	sw	zero,40(s1)
}
    80004950:	60e2                	ld	ra,24(sp)
    80004952:	6442                	ld	s0,16(sp)
    80004954:	64a2                	ld	s1,8(sp)
    80004956:	6902                	ld	s2,0(sp)
    80004958:	6105                	addi	sp,sp,32
    8000495a:	8082                	ret

000000008000495c <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000495c:	1101                	addi	sp,sp,-32
    8000495e:	ec06                	sd	ra,24(sp)
    80004960:	e822                	sd	s0,16(sp)
    80004962:	e426                	sd	s1,8(sp)
    80004964:	e04a                	sd	s2,0(sp)
    80004966:	1000                	addi	s0,sp,32
    80004968:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000496a:	00850913          	addi	s2,a0,8
    8000496e:	854a                	mv	a0,s2
    80004970:	ffffc097          	auipc	ra,0xffffc
    80004974:	266080e7          	jalr	614(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    80004978:	409c                	lw	a5,0(s1)
    8000497a:	cb89                	beqz	a5,8000498c <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000497c:	85ca                	mv	a1,s2
    8000497e:	8526                	mv	a0,s1
    80004980:	ffffe097          	auipc	ra,0xffffe
    80004984:	8ba080e7          	jalr	-1862(ra) # 8000223a <sleep>
  while (lk->locked) {
    80004988:	409c                	lw	a5,0(s1)
    8000498a:	fbed                	bnez	a5,8000497c <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000498c:	4785                	li	a5,1
    8000498e:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004990:	ffffd097          	auipc	ra,0xffffd
    80004994:	01c080e7          	jalr	28(ra) # 800019ac <myproc>
    80004998:	591c                	lw	a5,48(a0)
    8000499a:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000499c:	854a                	mv	a0,s2
    8000499e:	ffffc097          	auipc	ra,0xffffc
    800049a2:	2ec080e7          	jalr	748(ra) # 80000c8a <release>
}
    800049a6:	60e2                	ld	ra,24(sp)
    800049a8:	6442                	ld	s0,16(sp)
    800049aa:	64a2                	ld	s1,8(sp)
    800049ac:	6902                	ld	s2,0(sp)
    800049ae:	6105                	addi	sp,sp,32
    800049b0:	8082                	ret

00000000800049b2 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800049b2:	1101                	addi	sp,sp,-32
    800049b4:	ec06                	sd	ra,24(sp)
    800049b6:	e822                	sd	s0,16(sp)
    800049b8:	e426                	sd	s1,8(sp)
    800049ba:	e04a                	sd	s2,0(sp)
    800049bc:	1000                	addi	s0,sp,32
    800049be:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800049c0:	00850913          	addi	s2,a0,8
    800049c4:	854a                	mv	a0,s2
    800049c6:	ffffc097          	auipc	ra,0xffffc
    800049ca:	210080e7          	jalr	528(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    800049ce:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800049d2:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800049d6:	8526                	mv	a0,s1
    800049d8:	ffffe097          	auipc	ra,0xffffe
    800049dc:	a12080e7          	jalr	-1518(ra) # 800023ea <wakeup>
  release(&lk->lk);
    800049e0:	854a                	mv	a0,s2
    800049e2:	ffffc097          	auipc	ra,0xffffc
    800049e6:	2a8080e7          	jalr	680(ra) # 80000c8a <release>
}
    800049ea:	60e2                	ld	ra,24(sp)
    800049ec:	6442                	ld	s0,16(sp)
    800049ee:	64a2                	ld	s1,8(sp)
    800049f0:	6902                	ld	s2,0(sp)
    800049f2:	6105                	addi	sp,sp,32
    800049f4:	8082                	ret

00000000800049f6 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800049f6:	7179                	addi	sp,sp,-48
    800049f8:	f406                	sd	ra,40(sp)
    800049fa:	f022                	sd	s0,32(sp)
    800049fc:	ec26                	sd	s1,24(sp)
    800049fe:	e84a                	sd	s2,16(sp)
    80004a00:	e44e                	sd	s3,8(sp)
    80004a02:	1800                	addi	s0,sp,48
    80004a04:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004a06:	00850913          	addi	s2,a0,8
    80004a0a:	854a                	mv	a0,s2
    80004a0c:	ffffc097          	auipc	ra,0xffffc
    80004a10:	1ca080e7          	jalr	458(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004a14:	409c                	lw	a5,0(s1)
    80004a16:	ef99                	bnez	a5,80004a34 <holdingsleep+0x3e>
    80004a18:	4481                	li	s1,0
  release(&lk->lk);
    80004a1a:	854a                	mv	a0,s2
    80004a1c:	ffffc097          	auipc	ra,0xffffc
    80004a20:	26e080e7          	jalr	622(ra) # 80000c8a <release>
  return r;
}
    80004a24:	8526                	mv	a0,s1
    80004a26:	70a2                	ld	ra,40(sp)
    80004a28:	7402                	ld	s0,32(sp)
    80004a2a:	64e2                	ld	s1,24(sp)
    80004a2c:	6942                	ld	s2,16(sp)
    80004a2e:	69a2                	ld	s3,8(sp)
    80004a30:	6145                	addi	sp,sp,48
    80004a32:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004a34:	0284a983          	lw	s3,40(s1)
    80004a38:	ffffd097          	auipc	ra,0xffffd
    80004a3c:	f74080e7          	jalr	-140(ra) # 800019ac <myproc>
    80004a40:	5904                	lw	s1,48(a0)
    80004a42:	413484b3          	sub	s1,s1,s3
    80004a46:	0014b493          	seqz	s1,s1
    80004a4a:	bfc1                	j	80004a1a <holdingsleep+0x24>

0000000080004a4c <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004a4c:	1141                	addi	sp,sp,-16
    80004a4e:	e406                	sd	ra,8(sp)
    80004a50:	e022                	sd	s0,0(sp)
    80004a52:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004a54:	00004597          	auipc	a1,0x4
    80004a58:	e5458593          	addi	a1,a1,-428 # 800088a8 <systemCallsNames+0x250>
    80004a5c:	0001d517          	auipc	a0,0x1d
    80004a60:	48c50513          	addi	a0,a0,1164 # 80021ee8 <ftable>
    80004a64:	ffffc097          	auipc	ra,0xffffc
    80004a68:	0e2080e7          	jalr	226(ra) # 80000b46 <initlock>
}
    80004a6c:	60a2                	ld	ra,8(sp)
    80004a6e:	6402                	ld	s0,0(sp)
    80004a70:	0141                	addi	sp,sp,16
    80004a72:	8082                	ret

0000000080004a74 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004a74:	1101                	addi	sp,sp,-32
    80004a76:	ec06                	sd	ra,24(sp)
    80004a78:	e822                	sd	s0,16(sp)
    80004a7a:	e426                	sd	s1,8(sp)
    80004a7c:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004a7e:	0001d517          	auipc	a0,0x1d
    80004a82:	46a50513          	addi	a0,a0,1130 # 80021ee8 <ftable>
    80004a86:	ffffc097          	auipc	ra,0xffffc
    80004a8a:	150080e7          	jalr	336(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004a8e:	0001d497          	auipc	s1,0x1d
    80004a92:	47248493          	addi	s1,s1,1138 # 80021f00 <ftable+0x18>
    80004a96:	0001e717          	auipc	a4,0x1e
    80004a9a:	40a70713          	addi	a4,a4,1034 # 80022ea0 <disk>
    if(f->ref == 0){
    80004a9e:	40dc                	lw	a5,4(s1)
    80004aa0:	cf99                	beqz	a5,80004abe <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004aa2:	02848493          	addi	s1,s1,40
    80004aa6:	fee49ce3          	bne	s1,a4,80004a9e <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004aaa:	0001d517          	auipc	a0,0x1d
    80004aae:	43e50513          	addi	a0,a0,1086 # 80021ee8 <ftable>
    80004ab2:	ffffc097          	auipc	ra,0xffffc
    80004ab6:	1d8080e7          	jalr	472(ra) # 80000c8a <release>
  return 0;
    80004aba:	4481                	li	s1,0
    80004abc:	a819                	j	80004ad2 <filealloc+0x5e>
      f->ref = 1;
    80004abe:	4785                	li	a5,1
    80004ac0:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004ac2:	0001d517          	auipc	a0,0x1d
    80004ac6:	42650513          	addi	a0,a0,1062 # 80021ee8 <ftable>
    80004aca:	ffffc097          	auipc	ra,0xffffc
    80004ace:	1c0080e7          	jalr	448(ra) # 80000c8a <release>
}
    80004ad2:	8526                	mv	a0,s1
    80004ad4:	60e2                	ld	ra,24(sp)
    80004ad6:	6442                	ld	s0,16(sp)
    80004ad8:	64a2                	ld	s1,8(sp)
    80004ada:	6105                	addi	sp,sp,32
    80004adc:	8082                	ret

0000000080004ade <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004ade:	1101                	addi	sp,sp,-32
    80004ae0:	ec06                	sd	ra,24(sp)
    80004ae2:	e822                	sd	s0,16(sp)
    80004ae4:	e426                	sd	s1,8(sp)
    80004ae6:	1000                	addi	s0,sp,32
    80004ae8:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004aea:	0001d517          	auipc	a0,0x1d
    80004aee:	3fe50513          	addi	a0,a0,1022 # 80021ee8 <ftable>
    80004af2:	ffffc097          	auipc	ra,0xffffc
    80004af6:	0e4080e7          	jalr	228(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004afa:	40dc                	lw	a5,4(s1)
    80004afc:	02f05263          	blez	a5,80004b20 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004b00:	2785                	addiw	a5,a5,1
    80004b02:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004b04:	0001d517          	auipc	a0,0x1d
    80004b08:	3e450513          	addi	a0,a0,996 # 80021ee8 <ftable>
    80004b0c:	ffffc097          	auipc	ra,0xffffc
    80004b10:	17e080e7          	jalr	382(ra) # 80000c8a <release>
  return f;
}
    80004b14:	8526                	mv	a0,s1
    80004b16:	60e2                	ld	ra,24(sp)
    80004b18:	6442                	ld	s0,16(sp)
    80004b1a:	64a2                	ld	s1,8(sp)
    80004b1c:	6105                	addi	sp,sp,32
    80004b1e:	8082                	ret
    panic("filedup");
    80004b20:	00004517          	auipc	a0,0x4
    80004b24:	d9050513          	addi	a0,a0,-624 # 800088b0 <systemCallsNames+0x258>
    80004b28:	ffffc097          	auipc	ra,0xffffc
    80004b2c:	a18080e7          	jalr	-1512(ra) # 80000540 <panic>

0000000080004b30 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004b30:	7139                	addi	sp,sp,-64
    80004b32:	fc06                	sd	ra,56(sp)
    80004b34:	f822                	sd	s0,48(sp)
    80004b36:	f426                	sd	s1,40(sp)
    80004b38:	f04a                	sd	s2,32(sp)
    80004b3a:	ec4e                	sd	s3,24(sp)
    80004b3c:	e852                	sd	s4,16(sp)
    80004b3e:	e456                	sd	s5,8(sp)
    80004b40:	0080                	addi	s0,sp,64
    80004b42:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004b44:	0001d517          	auipc	a0,0x1d
    80004b48:	3a450513          	addi	a0,a0,932 # 80021ee8 <ftable>
    80004b4c:	ffffc097          	auipc	ra,0xffffc
    80004b50:	08a080e7          	jalr	138(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004b54:	40dc                	lw	a5,4(s1)
    80004b56:	06f05163          	blez	a5,80004bb8 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004b5a:	37fd                	addiw	a5,a5,-1
    80004b5c:	0007871b          	sext.w	a4,a5
    80004b60:	c0dc                	sw	a5,4(s1)
    80004b62:	06e04363          	bgtz	a4,80004bc8 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004b66:	0004a903          	lw	s2,0(s1)
    80004b6a:	0094ca83          	lbu	s5,9(s1)
    80004b6e:	0104ba03          	ld	s4,16(s1)
    80004b72:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004b76:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004b7a:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004b7e:	0001d517          	auipc	a0,0x1d
    80004b82:	36a50513          	addi	a0,a0,874 # 80021ee8 <ftable>
    80004b86:	ffffc097          	auipc	ra,0xffffc
    80004b8a:	104080e7          	jalr	260(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    80004b8e:	4785                	li	a5,1
    80004b90:	04f90d63          	beq	s2,a5,80004bea <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004b94:	3979                	addiw	s2,s2,-2
    80004b96:	4785                	li	a5,1
    80004b98:	0527e063          	bltu	a5,s2,80004bd8 <fileclose+0xa8>
    begin_op();
    80004b9c:	00000097          	auipc	ra,0x0
    80004ba0:	acc080e7          	jalr	-1332(ra) # 80004668 <begin_op>
    iput(ff.ip);
    80004ba4:	854e                	mv	a0,s3
    80004ba6:	fffff097          	auipc	ra,0xfffff
    80004baa:	2b0080e7          	jalr	688(ra) # 80003e56 <iput>
    end_op();
    80004bae:	00000097          	auipc	ra,0x0
    80004bb2:	b38080e7          	jalr	-1224(ra) # 800046e6 <end_op>
    80004bb6:	a00d                	j	80004bd8 <fileclose+0xa8>
    panic("fileclose");
    80004bb8:	00004517          	auipc	a0,0x4
    80004bbc:	d0050513          	addi	a0,a0,-768 # 800088b8 <systemCallsNames+0x260>
    80004bc0:	ffffc097          	auipc	ra,0xffffc
    80004bc4:	980080e7          	jalr	-1664(ra) # 80000540 <panic>
    release(&ftable.lock);
    80004bc8:	0001d517          	auipc	a0,0x1d
    80004bcc:	32050513          	addi	a0,a0,800 # 80021ee8 <ftable>
    80004bd0:	ffffc097          	auipc	ra,0xffffc
    80004bd4:	0ba080e7          	jalr	186(ra) # 80000c8a <release>
  }
}
    80004bd8:	70e2                	ld	ra,56(sp)
    80004bda:	7442                	ld	s0,48(sp)
    80004bdc:	74a2                	ld	s1,40(sp)
    80004bde:	7902                	ld	s2,32(sp)
    80004be0:	69e2                	ld	s3,24(sp)
    80004be2:	6a42                	ld	s4,16(sp)
    80004be4:	6aa2                	ld	s5,8(sp)
    80004be6:	6121                	addi	sp,sp,64
    80004be8:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004bea:	85d6                	mv	a1,s5
    80004bec:	8552                	mv	a0,s4
    80004bee:	00000097          	auipc	ra,0x0
    80004bf2:	34c080e7          	jalr	844(ra) # 80004f3a <pipeclose>
    80004bf6:	b7cd                	j	80004bd8 <fileclose+0xa8>

0000000080004bf8 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004bf8:	715d                	addi	sp,sp,-80
    80004bfa:	e486                	sd	ra,72(sp)
    80004bfc:	e0a2                	sd	s0,64(sp)
    80004bfe:	fc26                	sd	s1,56(sp)
    80004c00:	f84a                	sd	s2,48(sp)
    80004c02:	f44e                	sd	s3,40(sp)
    80004c04:	0880                	addi	s0,sp,80
    80004c06:	84aa                	mv	s1,a0
    80004c08:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004c0a:	ffffd097          	auipc	ra,0xffffd
    80004c0e:	da2080e7          	jalr	-606(ra) # 800019ac <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004c12:	409c                	lw	a5,0(s1)
    80004c14:	37f9                	addiw	a5,a5,-2
    80004c16:	4705                	li	a4,1
    80004c18:	04f76763          	bltu	a4,a5,80004c66 <filestat+0x6e>
    80004c1c:	892a                	mv	s2,a0
    ilock(f->ip);
    80004c1e:	6c88                	ld	a0,24(s1)
    80004c20:	fffff097          	auipc	ra,0xfffff
    80004c24:	07c080e7          	jalr	124(ra) # 80003c9c <ilock>
    stati(f->ip, &st);
    80004c28:	fb840593          	addi	a1,s0,-72
    80004c2c:	6c88                	ld	a0,24(s1)
    80004c2e:	fffff097          	auipc	ra,0xfffff
    80004c32:	2f8080e7          	jalr	760(ra) # 80003f26 <stati>
    iunlock(f->ip);
    80004c36:	6c88                	ld	a0,24(s1)
    80004c38:	fffff097          	auipc	ra,0xfffff
    80004c3c:	126080e7          	jalr	294(ra) # 80003d5e <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004c40:	46e1                	li	a3,24
    80004c42:	fb840613          	addi	a2,s0,-72
    80004c46:	85ce                	mv	a1,s3
    80004c48:	05093503          	ld	a0,80(s2)
    80004c4c:	ffffd097          	auipc	ra,0xffffd
    80004c50:	a20080e7          	jalr	-1504(ra) # 8000166c <copyout>
    80004c54:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004c58:	60a6                	ld	ra,72(sp)
    80004c5a:	6406                	ld	s0,64(sp)
    80004c5c:	74e2                	ld	s1,56(sp)
    80004c5e:	7942                	ld	s2,48(sp)
    80004c60:	79a2                	ld	s3,40(sp)
    80004c62:	6161                	addi	sp,sp,80
    80004c64:	8082                	ret
  return -1;
    80004c66:	557d                	li	a0,-1
    80004c68:	bfc5                	j	80004c58 <filestat+0x60>

0000000080004c6a <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004c6a:	7179                	addi	sp,sp,-48
    80004c6c:	f406                	sd	ra,40(sp)
    80004c6e:	f022                	sd	s0,32(sp)
    80004c70:	ec26                	sd	s1,24(sp)
    80004c72:	e84a                	sd	s2,16(sp)
    80004c74:	e44e                	sd	s3,8(sp)
    80004c76:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004c78:	00854783          	lbu	a5,8(a0)
    80004c7c:	c3d5                	beqz	a5,80004d20 <fileread+0xb6>
    80004c7e:	84aa                	mv	s1,a0
    80004c80:	89ae                	mv	s3,a1
    80004c82:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004c84:	411c                	lw	a5,0(a0)
    80004c86:	4705                	li	a4,1
    80004c88:	04e78963          	beq	a5,a4,80004cda <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004c8c:	470d                	li	a4,3
    80004c8e:	04e78d63          	beq	a5,a4,80004ce8 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004c92:	4709                	li	a4,2
    80004c94:	06e79e63          	bne	a5,a4,80004d10 <fileread+0xa6>
    ilock(f->ip);
    80004c98:	6d08                	ld	a0,24(a0)
    80004c9a:	fffff097          	auipc	ra,0xfffff
    80004c9e:	002080e7          	jalr	2(ra) # 80003c9c <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004ca2:	874a                	mv	a4,s2
    80004ca4:	5094                	lw	a3,32(s1)
    80004ca6:	864e                	mv	a2,s3
    80004ca8:	4585                	li	a1,1
    80004caa:	6c88                	ld	a0,24(s1)
    80004cac:	fffff097          	auipc	ra,0xfffff
    80004cb0:	2a4080e7          	jalr	676(ra) # 80003f50 <readi>
    80004cb4:	892a                	mv	s2,a0
    80004cb6:	00a05563          	blez	a0,80004cc0 <fileread+0x56>
      f->off += r;
    80004cba:	509c                	lw	a5,32(s1)
    80004cbc:	9fa9                	addw	a5,a5,a0
    80004cbe:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004cc0:	6c88                	ld	a0,24(s1)
    80004cc2:	fffff097          	auipc	ra,0xfffff
    80004cc6:	09c080e7          	jalr	156(ra) # 80003d5e <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004cca:	854a                	mv	a0,s2
    80004ccc:	70a2                	ld	ra,40(sp)
    80004cce:	7402                	ld	s0,32(sp)
    80004cd0:	64e2                	ld	s1,24(sp)
    80004cd2:	6942                	ld	s2,16(sp)
    80004cd4:	69a2                	ld	s3,8(sp)
    80004cd6:	6145                	addi	sp,sp,48
    80004cd8:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004cda:	6908                	ld	a0,16(a0)
    80004cdc:	00000097          	auipc	ra,0x0
    80004ce0:	3c6080e7          	jalr	966(ra) # 800050a2 <piperead>
    80004ce4:	892a                	mv	s2,a0
    80004ce6:	b7d5                	j	80004cca <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004ce8:	02451783          	lh	a5,36(a0)
    80004cec:	03079693          	slli	a3,a5,0x30
    80004cf0:	92c1                	srli	a3,a3,0x30
    80004cf2:	4725                	li	a4,9
    80004cf4:	02d76863          	bltu	a4,a3,80004d24 <fileread+0xba>
    80004cf8:	0792                	slli	a5,a5,0x4
    80004cfa:	0001d717          	auipc	a4,0x1d
    80004cfe:	14e70713          	addi	a4,a4,334 # 80021e48 <devsw>
    80004d02:	97ba                	add	a5,a5,a4
    80004d04:	639c                	ld	a5,0(a5)
    80004d06:	c38d                	beqz	a5,80004d28 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004d08:	4505                	li	a0,1
    80004d0a:	9782                	jalr	a5
    80004d0c:	892a                	mv	s2,a0
    80004d0e:	bf75                	j	80004cca <fileread+0x60>
    panic("fileread");
    80004d10:	00004517          	auipc	a0,0x4
    80004d14:	bb850513          	addi	a0,a0,-1096 # 800088c8 <systemCallsNames+0x270>
    80004d18:	ffffc097          	auipc	ra,0xffffc
    80004d1c:	828080e7          	jalr	-2008(ra) # 80000540 <panic>
    return -1;
    80004d20:	597d                	li	s2,-1
    80004d22:	b765                	j	80004cca <fileread+0x60>
      return -1;
    80004d24:	597d                	li	s2,-1
    80004d26:	b755                	j	80004cca <fileread+0x60>
    80004d28:	597d                	li	s2,-1
    80004d2a:	b745                	j	80004cca <fileread+0x60>

0000000080004d2c <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004d2c:	715d                	addi	sp,sp,-80
    80004d2e:	e486                	sd	ra,72(sp)
    80004d30:	e0a2                	sd	s0,64(sp)
    80004d32:	fc26                	sd	s1,56(sp)
    80004d34:	f84a                	sd	s2,48(sp)
    80004d36:	f44e                	sd	s3,40(sp)
    80004d38:	f052                	sd	s4,32(sp)
    80004d3a:	ec56                	sd	s5,24(sp)
    80004d3c:	e85a                	sd	s6,16(sp)
    80004d3e:	e45e                	sd	s7,8(sp)
    80004d40:	e062                	sd	s8,0(sp)
    80004d42:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004d44:	00954783          	lbu	a5,9(a0)
    80004d48:	10078663          	beqz	a5,80004e54 <filewrite+0x128>
    80004d4c:	892a                	mv	s2,a0
    80004d4e:	8b2e                	mv	s6,a1
    80004d50:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004d52:	411c                	lw	a5,0(a0)
    80004d54:	4705                	li	a4,1
    80004d56:	02e78263          	beq	a5,a4,80004d7a <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004d5a:	470d                	li	a4,3
    80004d5c:	02e78663          	beq	a5,a4,80004d88 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004d60:	4709                	li	a4,2
    80004d62:	0ee79163          	bne	a5,a4,80004e44 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004d66:	0ac05d63          	blez	a2,80004e20 <filewrite+0xf4>
    int i = 0;
    80004d6a:	4981                	li	s3,0
    80004d6c:	6b85                	lui	s7,0x1
    80004d6e:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004d72:	6c05                	lui	s8,0x1
    80004d74:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004d78:	a861                	j	80004e10 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004d7a:	6908                	ld	a0,16(a0)
    80004d7c:	00000097          	auipc	ra,0x0
    80004d80:	22e080e7          	jalr	558(ra) # 80004faa <pipewrite>
    80004d84:	8a2a                	mv	s4,a0
    80004d86:	a045                	j	80004e26 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004d88:	02451783          	lh	a5,36(a0)
    80004d8c:	03079693          	slli	a3,a5,0x30
    80004d90:	92c1                	srli	a3,a3,0x30
    80004d92:	4725                	li	a4,9
    80004d94:	0cd76263          	bltu	a4,a3,80004e58 <filewrite+0x12c>
    80004d98:	0792                	slli	a5,a5,0x4
    80004d9a:	0001d717          	auipc	a4,0x1d
    80004d9e:	0ae70713          	addi	a4,a4,174 # 80021e48 <devsw>
    80004da2:	97ba                	add	a5,a5,a4
    80004da4:	679c                	ld	a5,8(a5)
    80004da6:	cbdd                	beqz	a5,80004e5c <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004da8:	4505                	li	a0,1
    80004daa:	9782                	jalr	a5
    80004dac:	8a2a                	mv	s4,a0
    80004dae:	a8a5                	j	80004e26 <filewrite+0xfa>
    80004db0:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004db4:	00000097          	auipc	ra,0x0
    80004db8:	8b4080e7          	jalr	-1868(ra) # 80004668 <begin_op>
      ilock(f->ip);
    80004dbc:	01893503          	ld	a0,24(s2)
    80004dc0:	fffff097          	auipc	ra,0xfffff
    80004dc4:	edc080e7          	jalr	-292(ra) # 80003c9c <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004dc8:	8756                	mv	a4,s5
    80004dca:	02092683          	lw	a3,32(s2)
    80004dce:	01698633          	add	a2,s3,s6
    80004dd2:	4585                	li	a1,1
    80004dd4:	01893503          	ld	a0,24(s2)
    80004dd8:	fffff097          	auipc	ra,0xfffff
    80004ddc:	270080e7          	jalr	624(ra) # 80004048 <writei>
    80004de0:	84aa                	mv	s1,a0
    80004de2:	00a05763          	blez	a0,80004df0 <filewrite+0xc4>
        f->off += r;
    80004de6:	02092783          	lw	a5,32(s2)
    80004dea:	9fa9                	addw	a5,a5,a0
    80004dec:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004df0:	01893503          	ld	a0,24(s2)
    80004df4:	fffff097          	auipc	ra,0xfffff
    80004df8:	f6a080e7          	jalr	-150(ra) # 80003d5e <iunlock>
      end_op();
    80004dfc:	00000097          	auipc	ra,0x0
    80004e00:	8ea080e7          	jalr	-1814(ra) # 800046e6 <end_op>

      if(r != n1){
    80004e04:	009a9f63          	bne	s5,s1,80004e22 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004e08:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004e0c:	0149db63          	bge	s3,s4,80004e22 <filewrite+0xf6>
      int n1 = n - i;
    80004e10:	413a04bb          	subw	s1,s4,s3
    80004e14:	0004879b          	sext.w	a5,s1
    80004e18:	f8fbdce3          	bge	s7,a5,80004db0 <filewrite+0x84>
    80004e1c:	84e2                	mv	s1,s8
    80004e1e:	bf49                	j	80004db0 <filewrite+0x84>
    int i = 0;
    80004e20:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004e22:	013a1f63          	bne	s4,s3,80004e40 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004e26:	8552                	mv	a0,s4
    80004e28:	60a6                	ld	ra,72(sp)
    80004e2a:	6406                	ld	s0,64(sp)
    80004e2c:	74e2                	ld	s1,56(sp)
    80004e2e:	7942                	ld	s2,48(sp)
    80004e30:	79a2                	ld	s3,40(sp)
    80004e32:	7a02                	ld	s4,32(sp)
    80004e34:	6ae2                	ld	s5,24(sp)
    80004e36:	6b42                	ld	s6,16(sp)
    80004e38:	6ba2                	ld	s7,8(sp)
    80004e3a:	6c02                	ld	s8,0(sp)
    80004e3c:	6161                	addi	sp,sp,80
    80004e3e:	8082                	ret
    ret = (i == n ? n : -1);
    80004e40:	5a7d                	li	s4,-1
    80004e42:	b7d5                	j	80004e26 <filewrite+0xfa>
    panic("filewrite");
    80004e44:	00004517          	auipc	a0,0x4
    80004e48:	a9450513          	addi	a0,a0,-1388 # 800088d8 <systemCallsNames+0x280>
    80004e4c:	ffffb097          	auipc	ra,0xffffb
    80004e50:	6f4080e7          	jalr	1780(ra) # 80000540 <panic>
    return -1;
    80004e54:	5a7d                	li	s4,-1
    80004e56:	bfc1                	j	80004e26 <filewrite+0xfa>
      return -1;
    80004e58:	5a7d                	li	s4,-1
    80004e5a:	b7f1                	j	80004e26 <filewrite+0xfa>
    80004e5c:	5a7d                	li	s4,-1
    80004e5e:	b7e1                	j	80004e26 <filewrite+0xfa>

0000000080004e60 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004e60:	7179                	addi	sp,sp,-48
    80004e62:	f406                	sd	ra,40(sp)
    80004e64:	f022                	sd	s0,32(sp)
    80004e66:	ec26                	sd	s1,24(sp)
    80004e68:	e84a                	sd	s2,16(sp)
    80004e6a:	e44e                	sd	s3,8(sp)
    80004e6c:	e052                	sd	s4,0(sp)
    80004e6e:	1800                	addi	s0,sp,48
    80004e70:	84aa                	mv	s1,a0
    80004e72:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004e74:	0005b023          	sd	zero,0(a1)
    80004e78:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004e7c:	00000097          	auipc	ra,0x0
    80004e80:	bf8080e7          	jalr	-1032(ra) # 80004a74 <filealloc>
    80004e84:	e088                	sd	a0,0(s1)
    80004e86:	c551                	beqz	a0,80004f12 <pipealloc+0xb2>
    80004e88:	00000097          	auipc	ra,0x0
    80004e8c:	bec080e7          	jalr	-1044(ra) # 80004a74 <filealloc>
    80004e90:	00aa3023          	sd	a0,0(s4)
    80004e94:	c92d                	beqz	a0,80004f06 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004e96:	ffffc097          	auipc	ra,0xffffc
    80004e9a:	c50080e7          	jalr	-944(ra) # 80000ae6 <kalloc>
    80004e9e:	892a                	mv	s2,a0
    80004ea0:	c125                	beqz	a0,80004f00 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004ea2:	4985                	li	s3,1
    80004ea4:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004ea8:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004eac:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004eb0:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004eb4:	00003597          	auipc	a1,0x3
    80004eb8:	61c58593          	addi	a1,a1,1564 # 800084d0 <states.0+0x1c0>
    80004ebc:	ffffc097          	auipc	ra,0xffffc
    80004ec0:	c8a080e7          	jalr	-886(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    80004ec4:	609c                	ld	a5,0(s1)
    80004ec6:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004eca:	609c                	ld	a5,0(s1)
    80004ecc:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004ed0:	609c                	ld	a5,0(s1)
    80004ed2:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004ed6:	609c                	ld	a5,0(s1)
    80004ed8:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004edc:	000a3783          	ld	a5,0(s4)
    80004ee0:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004ee4:	000a3783          	ld	a5,0(s4)
    80004ee8:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004eec:	000a3783          	ld	a5,0(s4)
    80004ef0:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004ef4:	000a3783          	ld	a5,0(s4)
    80004ef8:	0127b823          	sd	s2,16(a5)
  return 0;
    80004efc:	4501                	li	a0,0
    80004efe:	a025                	j	80004f26 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004f00:	6088                	ld	a0,0(s1)
    80004f02:	e501                	bnez	a0,80004f0a <pipealloc+0xaa>
    80004f04:	a039                	j	80004f12 <pipealloc+0xb2>
    80004f06:	6088                	ld	a0,0(s1)
    80004f08:	c51d                	beqz	a0,80004f36 <pipealloc+0xd6>
    fileclose(*f0);
    80004f0a:	00000097          	auipc	ra,0x0
    80004f0e:	c26080e7          	jalr	-986(ra) # 80004b30 <fileclose>
  if(*f1)
    80004f12:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004f16:	557d                	li	a0,-1
  if(*f1)
    80004f18:	c799                	beqz	a5,80004f26 <pipealloc+0xc6>
    fileclose(*f1);
    80004f1a:	853e                	mv	a0,a5
    80004f1c:	00000097          	auipc	ra,0x0
    80004f20:	c14080e7          	jalr	-1004(ra) # 80004b30 <fileclose>
  return -1;
    80004f24:	557d                	li	a0,-1
}
    80004f26:	70a2                	ld	ra,40(sp)
    80004f28:	7402                	ld	s0,32(sp)
    80004f2a:	64e2                	ld	s1,24(sp)
    80004f2c:	6942                	ld	s2,16(sp)
    80004f2e:	69a2                	ld	s3,8(sp)
    80004f30:	6a02                	ld	s4,0(sp)
    80004f32:	6145                	addi	sp,sp,48
    80004f34:	8082                	ret
  return -1;
    80004f36:	557d                	li	a0,-1
    80004f38:	b7fd                	j	80004f26 <pipealloc+0xc6>

0000000080004f3a <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004f3a:	1101                	addi	sp,sp,-32
    80004f3c:	ec06                	sd	ra,24(sp)
    80004f3e:	e822                	sd	s0,16(sp)
    80004f40:	e426                	sd	s1,8(sp)
    80004f42:	e04a                	sd	s2,0(sp)
    80004f44:	1000                	addi	s0,sp,32
    80004f46:	84aa                	mv	s1,a0
    80004f48:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004f4a:	ffffc097          	auipc	ra,0xffffc
    80004f4e:	c8c080e7          	jalr	-884(ra) # 80000bd6 <acquire>
  if(writable){
    80004f52:	02090d63          	beqz	s2,80004f8c <pipeclose+0x52>
    pi->writeopen = 0;
    80004f56:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004f5a:	21848513          	addi	a0,s1,536
    80004f5e:	ffffd097          	auipc	ra,0xffffd
    80004f62:	48c080e7          	jalr	1164(ra) # 800023ea <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004f66:	2204b783          	ld	a5,544(s1)
    80004f6a:	eb95                	bnez	a5,80004f9e <pipeclose+0x64>
    release(&pi->lock);
    80004f6c:	8526                	mv	a0,s1
    80004f6e:	ffffc097          	auipc	ra,0xffffc
    80004f72:	d1c080e7          	jalr	-740(ra) # 80000c8a <release>
    kfree((char*)pi);
    80004f76:	8526                	mv	a0,s1
    80004f78:	ffffc097          	auipc	ra,0xffffc
    80004f7c:	a70080e7          	jalr	-1424(ra) # 800009e8 <kfree>
  } else
    release(&pi->lock);
}
    80004f80:	60e2                	ld	ra,24(sp)
    80004f82:	6442                	ld	s0,16(sp)
    80004f84:	64a2                	ld	s1,8(sp)
    80004f86:	6902                	ld	s2,0(sp)
    80004f88:	6105                	addi	sp,sp,32
    80004f8a:	8082                	ret
    pi->readopen = 0;
    80004f8c:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004f90:	21c48513          	addi	a0,s1,540
    80004f94:	ffffd097          	auipc	ra,0xffffd
    80004f98:	456080e7          	jalr	1110(ra) # 800023ea <wakeup>
    80004f9c:	b7e9                	j	80004f66 <pipeclose+0x2c>
    release(&pi->lock);
    80004f9e:	8526                	mv	a0,s1
    80004fa0:	ffffc097          	auipc	ra,0xffffc
    80004fa4:	cea080e7          	jalr	-790(ra) # 80000c8a <release>
}
    80004fa8:	bfe1                	j	80004f80 <pipeclose+0x46>

0000000080004faa <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004faa:	711d                	addi	sp,sp,-96
    80004fac:	ec86                	sd	ra,88(sp)
    80004fae:	e8a2                	sd	s0,80(sp)
    80004fb0:	e4a6                	sd	s1,72(sp)
    80004fb2:	e0ca                	sd	s2,64(sp)
    80004fb4:	fc4e                	sd	s3,56(sp)
    80004fb6:	f852                	sd	s4,48(sp)
    80004fb8:	f456                	sd	s5,40(sp)
    80004fba:	f05a                	sd	s6,32(sp)
    80004fbc:	ec5e                	sd	s7,24(sp)
    80004fbe:	e862                	sd	s8,16(sp)
    80004fc0:	1080                	addi	s0,sp,96
    80004fc2:	84aa                	mv	s1,a0
    80004fc4:	8aae                	mv	s5,a1
    80004fc6:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004fc8:	ffffd097          	auipc	ra,0xffffd
    80004fcc:	9e4080e7          	jalr	-1564(ra) # 800019ac <myproc>
    80004fd0:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004fd2:	8526                	mv	a0,s1
    80004fd4:	ffffc097          	auipc	ra,0xffffc
    80004fd8:	c02080e7          	jalr	-1022(ra) # 80000bd6 <acquire>
  while(i < n){
    80004fdc:	0b405663          	blez	s4,80005088 <pipewrite+0xde>
  int i = 0;
    80004fe0:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004fe2:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004fe4:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004fe8:	21c48b93          	addi	s7,s1,540
    80004fec:	a089                	j	8000502e <pipewrite+0x84>
      release(&pi->lock);
    80004fee:	8526                	mv	a0,s1
    80004ff0:	ffffc097          	auipc	ra,0xffffc
    80004ff4:	c9a080e7          	jalr	-870(ra) # 80000c8a <release>
      return -1;
    80004ff8:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004ffa:	854a                	mv	a0,s2
    80004ffc:	60e6                	ld	ra,88(sp)
    80004ffe:	6446                	ld	s0,80(sp)
    80005000:	64a6                	ld	s1,72(sp)
    80005002:	6906                	ld	s2,64(sp)
    80005004:	79e2                	ld	s3,56(sp)
    80005006:	7a42                	ld	s4,48(sp)
    80005008:	7aa2                	ld	s5,40(sp)
    8000500a:	7b02                	ld	s6,32(sp)
    8000500c:	6be2                	ld	s7,24(sp)
    8000500e:	6c42                	ld	s8,16(sp)
    80005010:	6125                	addi	sp,sp,96
    80005012:	8082                	ret
      wakeup(&pi->nread);
    80005014:	8562                	mv	a0,s8
    80005016:	ffffd097          	auipc	ra,0xffffd
    8000501a:	3d4080e7          	jalr	980(ra) # 800023ea <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    8000501e:	85a6                	mv	a1,s1
    80005020:	855e                	mv	a0,s7
    80005022:	ffffd097          	auipc	ra,0xffffd
    80005026:	218080e7          	jalr	536(ra) # 8000223a <sleep>
  while(i < n){
    8000502a:	07495063          	bge	s2,s4,8000508a <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    8000502e:	2204a783          	lw	a5,544(s1)
    80005032:	dfd5                	beqz	a5,80004fee <pipewrite+0x44>
    80005034:	854e                	mv	a0,s3
    80005036:	ffffd097          	auipc	ra,0xffffd
    8000503a:	604080e7          	jalr	1540(ra) # 8000263a <killed>
    8000503e:	f945                	bnez	a0,80004fee <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80005040:	2184a783          	lw	a5,536(s1)
    80005044:	21c4a703          	lw	a4,540(s1)
    80005048:	2007879b          	addiw	a5,a5,512
    8000504c:	fcf704e3          	beq	a4,a5,80005014 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005050:	4685                	li	a3,1
    80005052:	01590633          	add	a2,s2,s5
    80005056:	faf40593          	addi	a1,s0,-81
    8000505a:	0509b503          	ld	a0,80(s3)
    8000505e:	ffffc097          	auipc	ra,0xffffc
    80005062:	69a080e7          	jalr	1690(ra) # 800016f8 <copyin>
    80005066:	03650263          	beq	a0,s6,8000508a <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    8000506a:	21c4a783          	lw	a5,540(s1)
    8000506e:	0017871b          	addiw	a4,a5,1
    80005072:	20e4ae23          	sw	a4,540(s1)
    80005076:	1ff7f793          	andi	a5,a5,511
    8000507a:	97a6                	add	a5,a5,s1
    8000507c:	faf44703          	lbu	a4,-81(s0)
    80005080:	00e78c23          	sb	a4,24(a5)
      i++;
    80005084:	2905                	addiw	s2,s2,1
    80005086:	b755                	j	8000502a <pipewrite+0x80>
  int i = 0;
    80005088:	4901                	li	s2,0
  wakeup(&pi->nread);
    8000508a:	21848513          	addi	a0,s1,536
    8000508e:	ffffd097          	auipc	ra,0xffffd
    80005092:	35c080e7          	jalr	860(ra) # 800023ea <wakeup>
  release(&pi->lock);
    80005096:	8526                	mv	a0,s1
    80005098:	ffffc097          	auipc	ra,0xffffc
    8000509c:	bf2080e7          	jalr	-1038(ra) # 80000c8a <release>
  return i;
    800050a0:	bfa9                	j	80004ffa <pipewrite+0x50>

00000000800050a2 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800050a2:	715d                	addi	sp,sp,-80
    800050a4:	e486                	sd	ra,72(sp)
    800050a6:	e0a2                	sd	s0,64(sp)
    800050a8:	fc26                	sd	s1,56(sp)
    800050aa:	f84a                	sd	s2,48(sp)
    800050ac:	f44e                	sd	s3,40(sp)
    800050ae:	f052                	sd	s4,32(sp)
    800050b0:	ec56                	sd	s5,24(sp)
    800050b2:	e85a                	sd	s6,16(sp)
    800050b4:	0880                	addi	s0,sp,80
    800050b6:	84aa                	mv	s1,a0
    800050b8:	892e                	mv	s2,a1
    800050ba:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    800050bc:	ffffd097          	auipc	ra,0xffffd
    800050c0:	8f0080e7          	jalr	-1808(ra) # 800019ac <myproc>
    800050c4:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    800050c6:	8526                	mv	a0,s1
    800050c8:	ffffc097          	auipc	ra,0xffffc
    800050cc:	b0e080e7          	jalr	-1266(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800050d0:	2184a703          	lw	a4,536(s1)
    800050d4:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800050d8:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800050dc:	02f71763          	bne	a4,a5,8000510a <piperead+0x68>
    800050e0:	2244a783          	lw	a5,548(s1)
    800050e4:	c39d                	beqz	a5,8000510a <piperead+0x68>
    if(killed(pr)){
    800050e6:	8552                	mv	a0,s4
    800050e8:	ffffd097          	auipc	ra,0xffffd
    800050ec:	552080e7          	jalr	1362(ra) # 8000263a <killed>
    800050f0:	e949                	bnez	a0,80005182 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800050f2:	85a6                	mv	a1,s1
    800050f4:	854e                	mv	a0,s3
    800050f6:	ffffd097          	auipc	ra,0xffffd
    800050fa:	144080e7          	jalr	324(ra) # 8000223a <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800050fe:	2184a703          	lw	a4,536(s1)
    80005102:	21c4a783          	lw	a5,540(s1)
    80005106:	fcf70de3          	beq	a4,a5,800050e0 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000510a:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000510c:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000510e:	05505463          	blez	s5,80005156 <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80005112:	2184a783          	lw	a5,536(s1)
    80005116:	21c4a703          	lw	a4,540(s1)
    8000511a:	02f70e63          	beq	a4,a5,80005156 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    8000511e:	0017871b          	addiw	a4,a5,1
    80005122:	20e4ac23          	sw	a4,536(s1)
    80005126:	1ff7f793          	andi	a5,a5,511
    8000512a:	97a6                	add	a5,a5,s1
    8000512c:	0187c783          	lbu	a5,24(a5)
    80005130:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005134:	4685                	li	a3,1
    80005136:	fbf40613          	addi	a2,s0,-65
    8000513a:	85ca                	mv	a1,s2
    8000513c:	050a3503          	ld	a0,80(s4)
    80005140:	ffffc097          	auipc	ra,0xffffc
    80005144:	52c080e7          	jalr	1324(ra) # 8000166c <copyout>
    80005148:	01650763          	beq	a0,s6,80005156 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000514c:	2985                	addiw	s3,s3,1
    8000514e:	0905                	addi	s2,s2,1
    80005150:	fd3a91e3          	bne	s5,s3,80005112 <piperead+0x70>
    80005154:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005156:	21c48513          	addi	a0,s1,540
    8000515a:	ffffd097          	auipc	ra,0xffffd
    8000515e:	290080e7          	jalr	656(ra) # 800023ea <wakeup>
  release(&pi->lock);
    80005162:	8526                	mv	a0,s1
    80005164:	ffffc097          	auipc	ra,0xffffc
    80005168:	b26080e7          	jalr	-1242(ra) # 80000c8a <release>
  return i;
}
    8000516c:	854e                	mv	a0,s3
    8000516e:	60a6                	ld	ra,72(sp)
    80005170:	6406                	ld	s0,64(sp)
    80005172:	74e2                	ld	s1,56(sp)
    80005174:	7942                	ld	s2,48(sp)
    80005176:	79a2                	ld	s3,40(sp)
    80005178:	7a02                	ld	s4,32(sp)
    8000517a:	6ae2                	ld	s5,24(sp)
    8000517c:	6b42                	ld	s6,16(sp)
    8000517e:	6161                	addi	sp,sp,80
    80005180:	8082                	ret
      release(&pi->lock);
    80005182:	8526                	mv	a0,s1
    80005184:	ffffc097          	auipc	ra,0xffffc
    80005188:	b06080e7          	jalr	-1274(ra) # 80000c8a <release>
      return -1;
    8000518c:	59fd                	li	s3,-1
    8000518e:	bff9                	j	8000516c <piperead+0xca>

0000000080005190 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80005190:	1141                	addi	sp,sp,-16
    80005192:	e422                	sd	s0,8(sp)
    80005194:	0800                	addi	s0,sp,16
    80005196:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80005198:	8905                	andi	a0,a0,1
    8000519a:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    8000519c:	8b89                	andi	a5,a5,2
    8000519e:	c399                	beqz	a5,800051a4 <flags2perm+0x14>
      perm |= PTE_W;
    800051a0:	00456513          	ori	a0,a0,4
    return perm;
}
    800051a4:	6422                	ld	s0,8(sp)
    800051a6:	0141                	addi	sp,sp,16
    800051a8:	8082                	ret

00000000800051aa <exec>:

int
exec(char *path, char **argv)
{
    800051aa:	de010113          	addi	sp,sp,-544
    800051ae:	20113c23          	sd	ra,536(sp)
    800051b2:	20813823          	sd	s0,528(sp)
    800051b6:	20913423          	sd	s1,520(sp)
    800051ba:	21213023          	sd	s2,512(sp)
    800051be:	ffce                	sd	s3,504(sp)
    800051c0:	fbd2                	sd	s4,496(sp)
    800051c2:	f7d6                	sd	s5,488(sp)
    800051c4:	f3da                	sd	s6,480(sp)
    800051c6:	efde                	sd	s7,472(sp)
    800051c8:	ebe2                	sd	s8,464(sp)
    800051ca:	e7e6                	sd	s9,456(sp)
    800051cc:	e3ea                	sd	s10,448(sp)
    800051ce:	ff6e                	sd	s11,440(sp)
    800051d0:	1400                	addi	s0,sp,544
    800051d2:	892a                	mv	s2,a0
    800051d4:	dea43423          	sd	a0,-536(s0)
    800051d8:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800051dc:	ffffc097          	auipc	ra,0xffffc
    800051e0:	7d0080e7          	jalr	2000(ra) # 800019ac <myproc>
    800051e4:	84aa                	mv	s1,a0

  begin_op();
    800051e6:	fffff097          	auipc	ra,0xfffff
    800051ea:	482080e7          	jalr	1154(ra) # 80004668 <begin_op>

  if((ip = namei(path)) == 0){
    800051ee:	854a                	mv	a0,s2
    800051f0:	fffff097          	auipc	ra,0xfffff
    800051f4:	258080e7          	jalr	600(ra) # 80004448 <namei>
    800051f8:	c93d                	beqz	a0,8000526e <exec+0xc4>
    800051fa:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800051fc:	fffff097          	auipc	ra,0xfffff
    80005200:	aa0080e7          	jalr	-1376(ra) # 80003c9c <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005204:	04000713          	li	a4,64
    80005208:	4681                	li	a3,0
    8000520a:	e5040613          	addi	a2,s0,-432
    8000520e:	4581                	li	a1,0
    80005210:	8556                	mv	a0,s5
    80005212:	fffff097          	auipc	ra,0xfffff
    80005216:	d3e080e7          	jalr	-706(ra) # 80003f50 <readi>
    8000521a:	04000793          	li	a5,64
    8000521e:	00f51a63          	bne	a0,a5,80005232 <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80005222:	e5042703          	lw	a4,-432(s0)
    80005226:	464c47b7          	lui	a5,0x464c4
    8000522a:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    8000522e:	04f70663          	beq	a4,a5,8000527a <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005232:	8556                	mv	a0,s5
    80005234:	fffff097          	auipc	ra,0xfffff
    80005238:	cca080e7          	jalr	-822(ra) # 80003efe <iunlockput>
    end_op();
    8000523c:	fffff097          	auipc	ra,0xfffff
    80005240:	4aa080e7          	jalr	1194(ra) # 800046e6 <end_op>
  }
  return -1;
    80005244:	557d                	li	a0,-1
}
    80005246:	21813083          	ld	ra,536(sp)
    8000524a:	21013403          	ld	s0,528(sp)
    8000524e:	20813483          	ld	s1,520(sp)
    80005252:	20013903          	ld	s2,512(sp)
    80005256:	79fe                	ld	s3,504(sp)
    80005258:	7a5e                	ld	s4,496(sp)
    8000525a:	7abe                	ld	s5,488(sp)
    8000525c:	7b1e                	ld	s6,480(sp)
    8000525e:	6bfe                	ld	s7,472(sp)
    80005260:	6c5e                	ld	s8,464(sp)
    80005262:	6cbe                	ld	s9,456(sp)
    80005264:	6d1e                	ld	s10,448(sp)
    80005266:	7dfa                	ld	s11,440(sp)
    80005268:	22010113          	addi	sp,sp,544
    8000526c:	8082                	ret
    end_op();
    8000526e:	fffff097          	auipc	ra,0xfffff
    80005272:	478080e7          	jalr	1144(ra) # 800046e6 <end_op>
    return -1;
    80005276:	557d                	li	a0,-1
    80005278:	b7f9                	j	80005246 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    8000527a:	8526                	mv	a0,s1
    8000527c:	ffffc097          	auipc	ra,0xffffc
    80005280:	7f4080e7          	jalr	2036(ra) # 80001a70 <proc_pagetable>
    80005284:	8b2a                	mv	s6,a0
    80005286:	d555                	beqz	a0,80005232 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005288:	e7042783          	lw	a5,-400(s0)
    8000528c:	e8845703          	lhu	a4,-376(s0)
    80005290:	c735                	beqz	a4,800052fc <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005292:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005294:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80005298:	6a05                	lui	s4,0x1
    8000529a:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    8000529e:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    800052a2:	6d85                	lui	s11,0x1
    800052a4:	7d7d                	lui	s10,0xfffff
    800052a6:	ac3d                	j	800054e4 <exec+0x33a>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800052a8:	00003517          	auipc	a0,0x3
    800052ac:	64050513          	addi	a0,a0,1600 # 800088e8 <systemCallsNames+0x290>
    800052b0:	ffffb097          	auipc	ra,0xffffb
    800052b4:	290080e7          	jalr	656(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800052b8:	874a                	mv	a4,s2
    800052ba:	009c86bb          	addw	a3,s9,s1
    800052be:	4581                	li	a1,0
    800052c0:	8556                	mv	a0,s5
    800052c2:	fffff097          	auipc	ra,0xfffff
    800052c6:	c8e080e7          	jalr	-882(ra) # 80003f50 <readi>
    800052ca:	2501                	sext.w	a0,a0
    800052cc:	1aa91963          	bne	s2,a0,8000547e <exec+0x2d4>
  for(i = 0; i < sz; i += PGSIZE){
    800052d0:	009d84bb          	addw	s1,s11,s1
    800052d4:	013d09bb          	addw	s3,s10,s3
    800052d8:	1f74f663          	bgeu	s1,s7,800054c4 <exec+0x31a>
    pa = walkaddr(pagetable, va + i);
    800052dc:	02049593          	slli	a1,s1,0x20
    800052e0:	9181                	srli	a1,a1,0x20
    800052e2:	95e2                	add	a1,a1,s8
    800052e4:	855a                	mv	a0,s6
    800052e6:	ffffc097          	auipc	ra,0xffffc
    800052ea:	d76080e7          	jalr	-650(ra) # 8000105c <walkaddr>
    800052ee:	862a                	mv	a2,a0
    if(pa == 0)
    800052f0:	dd45                	beqz	a0,800052a8 <exec+0xfe>
      n = PGSIZE;
    800052f2:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    800052f4:	fd49f2e3          	bgeu	s3,s4,800052b8 <exec+0x10e>
      n = sz - i;
    800052f8:	894e                	mv	s2,s3
    800052fa:	bf7d                	j	800052b8 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800052fc:	4901                	li	s2,0
  iunlockput(ip);
    800052fe:	8556                	mv	a0,s5
    80005300:	fffff097          	auipc	ra,0xfffff
    80005304:	bfe080e7          	jalr	-1026(ra) # 80003efe <iunlockput>
  end_op();
    80005308:	fffff097          	auipc	ra,0xfffff
    8000530c:	3de080e7          	jalr	990(ra) # 800046e6 <end_op>
  p = myproc();
    80005310:	ffffc097          	auipc	ra,0xffffc
    80005314:	69c080e7          	jalr	1692(ra) # 800019ac <myproc>
    80005318:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    8000531a:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    8000531e:	6785                	lui	a5,0x1
    80005320:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80005322:	97ca                	add	a5,a5,s2
    80005324:	777d                	lui	a4,0xfffff
    80005326:	8ff9                	and	a5,a5,a4
    80005328:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    8000532c:	4691                	li	a3,4
    8000532e:	6609                	lui	a2,0x2
    80005330:	963e                	add	a2,a2,a5
    80005332:	85be                	mv	a1,a5
    80005334:	855a                	mv	a0,s6
    80005336:	ffffc097          	auipc	ra,0xffffc
    8000533a:	0da080e7          	jalr	218(ra) # 80001410 <uvmalloc>
    8000533e:	8c2a                	mv	s8,a0
  ip = 0;
    80005340:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005342:	12050e63          	beqz	a0,8000547e <exec+0x2d4>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005346:	75f9                	lui	a1,0xffffe
    80005348:	95aa                	add	a1,a1,a0
    8000534a:	855a                	mv	a0,s6
    8000534c:	ffffc097          	auipc	ra,0xffffc
    80005350:	2ee080e7          	jalr	750(ra) # 8000163a <uvmclear>
  stackbase = sp - PGSIZE;
    80005354:	7afd                	lui	s5,0xfffff
    80005356:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80005358:	df043783          	ld	a5,-528(s0)
    8000535c:	6388                	ld	a0,0(a5)
    8000535e:	c925                	beqz	a0,800053ce <exec+0x224>
    80005360:	e9040993          	addi	s3,s0,-368
    80005364:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005368:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    8000536a:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    8000536c:	ffffc097          	auipc	ra,0xffffc
    80005370:	ae2080e7          	jalr	-1310(ra) # 80000e4e <strlen>
    80005374:	0015079b          	addiw	a5,a0,1
    80005378:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    8000537c:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80005380:	13596663          	bltu	s2,s5,800054ac <exec+0x302>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005384:	df043d83          	ld	s11,-528(s0)
    80005388:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    8000538c:	8552                	mv	a0,s4
    8000538e:	ffffc097          	auipc	ra,0xffffc
    80005392:	ac0080e7          	jalr	-1344(ra) # 80000e4e <strlen>
    80005396:	0015069b          	addiw	a3,a0,1
    8000539a:	8652                	mv	a2,s4
    8000539c:	85ca                	mv	a1,s2
    8000539e:	855a                	mv	a0,s6
    800053a0:	ffffc097          	auipc	ra,0xffffc
    800053a4:	2cc080e7          	jalr	716(ra) # 8000166c <copyout>
    800053a8:	10054663          	bltz	a0,800054b4 <exec+0x30a>
    ustack[argc] = sp;
    800053ac:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800053b0:	0485                	addi	s1,s1,1
    800053b2:	008d8793          	addi	a5,s11,8
    800053b6:	def43823          	sd	a5,-528(s0)
    800053ba:	008db503          	ld	a0,8(s11)
    800053be:	c911                	beqz	a0,800053d2 <exec+0x228>
    if(argc >= MAXARG)
    800053c0:	09a1                	addi	s3,s3,8
    800053c2:	fb3c95e3          	bne	s9,s3,8000536c <exec+0x1c2>
  sz = sz1;
    800053c6:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800053ca:	4a81                	li	s5,0
    800053cc:	a84d                	j	8000547e <exec+0x2d4>
  sp = sz;
    800053ce:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800053d0:	4481                	li	s1,0
  ustack[argc] = 0;
    800053d2:	00349793          	slli	a5,s1,0x3
    800053d6:	f9078793          	addi	a5,a5,-112
    800053da:	97a2                	add	a5,a5,s0
    800053dc:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    800053e0:	00148693          	addi	a3,s1,1
    800053e4:	068e                	slli	a3,a3,0x3
    800053e6:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800053ea:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800053ee:	01597663          	bgeu	s2,s5,800053fa <exec+0x250>
  sz = sz1;
    800053f2:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800053f6:	4a81                	li	s5,0
    800053f8:	a059                	j	8000547e <exec+0x2d4>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800053fa:	e9040613          	addi	a2,s0,-368
    800053fe:	85ca                	mv	a1,s2
    80005400:	855a                	mv	a0,s6
    80005402:	ffffc097          	auipc	ra,0xffffc
    80005406:	26a080e7          	jalr	618(ra) # 8000166c <copyout>
    8000540a:	0a054963          	bltz	a0,800054bc <exec+0x312>
  p->trapframe->a1 = sp;
    8000540e:	058bb783          	ld	a5,88(s7)
    80005412:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005416:	de843783          	ld	a5,-536(s0)
    8000541a:	0007c703          	lbu	a4,0(a5)
    8000541e:	cf11                	beqz	a4,8000543a <exec+0x290>
    80005420:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005422:	02f00693          	li	a3,47
    80005426:	a039                	j	80005434 <exec+0x28a>
      last = s+1;
    80005428:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    8000542c:	0785                	addi	a5,a5,1
    8000542e:	fff7c703          	lbu	a4,-1(a5)
    80005432:	c701                	beqz	a4,8000543a <exec+0x290>
    if(*s == '/')
    80005434:	fed71ce3          	bne	a4,a3,8000542c <exec+0x282>
    80005438:	bfc5                	j	80005428 <exec+0x27e>
  safestrcpy(p->name, last, sizeof(p->name));
    8000543a:	4641                	li	a2,16
    8000543c:	de843583          	ld	a1,-536(s0)
    80005440:	158b8513          	addi	a0,s7,344
    80005444:	ffffc097          	auipc	ra,0xffffc
    80005448:	9d8080e7          	jalr	-1576(ra) # 80000e1c <safestrcpy>
  oldpagetable = p->pagetable;
    8000544c:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80005450:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80005454:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005458:	058bb783          	ld	a5,88(s7)
    8000545c:	e6843703          	ld	a4,-408(s0)
    80005460:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005462:	058bb783          	ld	a5,88(s7)
    80005466:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000546a:	85ea                	mv	a1,s10
    8000546c:	ffffc097          	auipc	ra,0xffffc
    80005470:	6a0080e7          	jalr	1696(ra) # 80001b0c <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005474:	0004851b          	sext.w	a0,s1
    80005478:	b3f9                	j	80005246 <exec+0x9c>
    8000547a:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    8000547e:	df843583          	ld	a1,-520(s0)
    80005482:	855a                	mv	a0,s6
    80005484:	ffffc097          	auipc	ra,0xffffc
    80005488:	688080e7          	jalr	1672(ra) # 80001b0c <proc_freepagetable>
  if(ip){
    8000548c:	da0a93e3          	bnez	s5,80005232 <exec+0x88>
  return -1;
    80005490:	557d                	li	a0,-1
    80005492:	bb55                	j	80005246 <exec+0x9c>
    80005494:	df243c23          	sd	s2,-520(s0)
    80005498:	b7dd                	j	8000547e <exec+0x2d4>
    8000549a:	df243c23          	sd	s2,-520(s0)
    8000549e:	b7c5                	j	8000547e <exec+0x2d4>
    800054a0:	df243c23          	sd	s2,-520(s0)
    800054a4:	bfe9                	j	8000547e <exec+0x2d4>
    800054a6:	df243c23          	sd	s2,-520(s0)
    800054aa:	bfd1                	j	8000547e <exec+0x2d4>
  sz = sz1;
    800054ac:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800054b0:	4a81                	li	s5,0
    800054b2:	b7f1                	j	8000547e <exec+0x2d4>
  sz = sz1;
    800054b4:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800054b8:	4a81                	li	s5,0
    800054ba:	b7d1                	j	8000547e <exec+0x2d4>
  sz = sz1;
    800054bc:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800054c0:	4a81                	li	s5,0
    800054c2:	bf75                	j	8000547e <exec+0x2d4>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800054c4:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800054c8:	e0843783          	ld	a5,-504(s0)
    800054cc:	0017869b          	addiw	a3,a5,1
    800054d0:	e0d43423          	sd	a3,-504(s0)
    800054d4:	e0043783          	ld	a5,-512(s0)
    800054d8:	0387879b          	addiw	a5,a5,56
    800054dc:	e8845703          	lhu	a4,-376(s0)
    800054e0:	e0e6dfe3          	bge	a3,a4,800052fe <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800054e4:	2781                	sext.w	a5,a5
    800054e6:	e0f43023          	sd	a5,-512(s0)
    800054ea:	03800713          	li	a4,56
    800054ee:	86be                	mv	a3,a5
    800054f0:	e1840613          	addi	a2,s0,-488
    800054f4:	4581                	li	a1,0
    800054f6:	8556                	mv	a0,s5
    800054f8:	fffff097          	auipc	ra,0xfffff
    800054fc:	a58080e7          	jalr	-1448(ra) # 80003f50 <readi>
    80005500:	03800793          	li	a5,56
    80005504:	f6f51be3          	bne	a0,a5,8000547a <exec+0x2d0>
    if(ph.type != ELF_PROG_LOAD)
    80005508:	e1842783          	lw	a5,-488(s0)
    8000550c:	4705                	li	a4,1
    8000550e:	fae79de3          	bne	a5,a4,800054c8 <exec+0x31e>
    if(ph.memsz < ph.filesz)
    80005512:	e4043483          	ld	s1,-448(s0)
    80005516:	e3843783          	ld	a5,-456(s0)
    8000551a:	f6f4ede3          	bltu	s1,a5,80005494 <exec+0x2ea>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000551e:	e2843783          	ld	a5,-472(s0)
    80005522:	94be                	add	s1,s1,a5
    80005524:	f6f4ebe3          	bltu	s1,a5,8000549a <exec+0x2f0>
    if(ph.vaddr % PGSIZE != 0)
    80005528:	de043703          	ld	a4,-544(s0)
    8000552c:	8ff9                	and	a5,a5,a4
    8000552e:	fbad                	bnez	a5,800054a0 <exec+0x2f6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005530:	e1c42503          	lw	a0,-484(s0)
    80005534:	00000097          	auipc	ra,0x0
    80005538:	c5c080e7          	jalr	-932(ra) # 80005190 <flags2perm>
    8000553c:	86aa                	mv	a3,a0
    8000553e:	8626                	mv	a2,s1
    80005540:	85ca                	mv	a1,s2
    80005542:	855a                	mv	a0,s6
    80005544:	ffffc097          	auipc	ra,0xffffc
    80005548:	ecc080e7          	jalr	-308(ra) # 80001410 <uvmalloc>
    8000554c:	dea43c23          	sd	a0,-520(s0)
    80005550:	d939                	beqz	a0,800054a6 <exec+0x2fc>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005552:	e2843c03          	ld	s8,-472(s0)
    80005556:	e2042c83          	lw	s9,-480(s0)
    8000555a:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000555e:	f60b83e3          	beqz	s7,800054c4 <exec+0x31a>
    80005562:	89de                	mv	s3,s7
    80005564:	4481                	li	s1,0
    80005566:	bb9d                	j	800052dc <exec+0x132>

0000000080005568 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005568:	7179                	addi	sp,sp,-48
    8000556a:	f406                	sd	ra,40(sp)
    8000556c:	f022                	sd	s0,32(sp)
    8000556e:	ec26                	sd	s1,24(sp)
    80005570:	e84a                	sd	s2,16(sp)
    80005572:	1800                	addi	s0,sp,48
    80005574:	892e                	mv	s2,a1
    80005576:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005578:	fdc40593          	addi	a1,s0,-36
    8000557c:	ffffe097          	auipc	ra,0xffffe
    80005580:	99c080e7          	jalr	-1636(ra) # 80002f18 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005584:	fdc42703          	lw	a4,-36(s0)
    80005588:	47bd                	li	a5,15
    8000558a:	02e7eb63          	bltu	a5,a4,800055c0 <argfd+0x58>
    8000558e:	ffffc097          	auipc	ra,0xffffc
    80005592:	41e080e7          	jalr	1054(ra) # 800019ac <myproc>
    80005596:	fdc42703          	lw	a4,-36(s0)
    8000559a:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7ffdc03a>
    8000559e:	078e                	slli	a5,a5,0x3
    800055a0:	953e                	add	a0,a0,a5
    800055a2:	611c                	ld	a5,0(a0)
    800055a4:	c385                	beqz	a5,800055c4 <argfd+0x5c>
    return -1;
  if(pfd)
    800055a6:	00090463          	beqz	s2,800055ae <argfd+0x46>
    *pfd = fd;
    800055aa:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800055ae:	4501                	li	a0,0
  if(pf)
    800055b0:	c091                	beqz	s1,800055b4 <argfd+0x4c>
    *pf = f;
    800055b2:	e09c                	sd	a5,0(s1)
}
    800055b4:	70a2                	ld	ra,40(sp)
    800055b6:	7402                	ld	s0,32(sp)
    800055b8:	64e2                	ld	s1,24(sp)
    800055ba:	6942                	ld	s2,16(sp)
    800055bc:	6145                	addi	sp,sp,48
    800055be:	8082                	ret
    return -1;
    800055c0:	557d                	li	a0,-1
    800055c2:	bfcd                	j	800055b4 <argfd+0x4c>
    800055c4:	557d                	li	a0,-1
    800055c6:	b7fd                	j	800055b4 <argfd+0x4c>

00000000800055c8 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800055c8:	1101                	addi	sp,sp,-32
    800055ca:	ec06                	sd	ra,24(sp)
    800055cc:	e822                	sd	s0,16(sp)
    800055ce:	e426                	sd	s1,8(sp)
    800055d0:	1000                	addi	s0,sp,32
    800055d2:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800055d4:	ffffc097          	auipc	ra,0xffffc
    800055d8:	3d8080e7          	jalr	984(ra) # 800019ac <myproc>
    800055dc:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800055de:	0d050793          	addi	a5,a0,208
    800055e2:	4501                	li	a0,0
    800055e4:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800055e6:	6398                	ld	a4,0(a5)
    800055e8:	cb19                	beqz	a4,800055fe <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800055ea:	2505                	addiw	a0,a0,1
    800055ec:	07a1                	addi	a5,a5,8
    800055ee:	fed51ce3          	bne	a0,a3,800055e6 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800055f2:	557d                	li	a0,-1
}
    800055f4:	60e2                	ld	ra,24(sp)
    800055f6:	6442                	ld	s0,16(sp)
    800055f8:	64a2                	ld	s1,8(sp)
    800055fa:	6105                	addi	sp,sp,32
    800055fc:	8082                	ret
      p->ofile[fd] = f;
    800055fe:	01a50793          	addi	a5,a0,26
    80005602:	078e                	slli	a5,a5,0x3
    80005604:	963e                	add	a2,a2,a5
    80005606:	e204                	sd	s1,0(a2)
      return fd;
    80005608:	b7f5                	j	800055f4 <fdalloc+0x2c>

000000008000560a <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000560a:	715d                	addi	sp,sp,-80
    8000560c:	e486                	sd	ra,72(sp)
    8000560e:	e0a2                	sd	s0,64(sp)
    80005610:	fc26                	sd	s1,56(sp)
    80005612:	f84a                	sd	s2,48(sp)
    80005614:	f44e                	sd	s3,40(sp)
    80005616:	f052                	sd	s4,32(sp)
    80005618:	ec56                	sd	s5,24(sp)
    8000561a:	e85a                	sd	s6,16(sp)
    8000561c:	0880                	addi	s0,sp,80
    8000561e:	8b2e                	mv	s6,a1
    80005620:	89b2                	mv	s3,a2
    80005622:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005624:	fb040593          	addi	a1,s0,-80
    80005628:	fffff097          	auipc	ra,0xfffff
    8000562c:	e3e080e7          	jalr	-450(ra) # 80004466 <nameiparent>
    80005630:	84aa                	mv	s1,a0
    80005632:	14050f63          	beqz	a0,80005790 <create+0x186>
    return 0;

  ilock(dp);
    80005636:	ffffe097          	auipc	ra,0xffffe
    8000563a:	666080e7          	jalr	1638(ra) # 80003c9c <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000563e:	4601                	li	a2,0
    80005640:	fb040593          	addi	a1,s0,-80
    80005644:	8526                	mv	a0,s1
    80005646:	fffff097          	auipc	ra,0xfffff
    8000564a:	b3a080e7          	jalr	-1222(ra) # 80004180 <dirlookup>
    8000564e:	8aaa                	mv	s5,a0
    80005650:	c931                	beqz	a0,800056a4 <create+0x9a>
    iunlockput(dp);
    80005652:	8526                	mv	a0,s1
    80005654:	fffff097          	auipc	ra,0xfffff
    80005658:	8aa080e7          	jalr	-1878(ra) # 80003efe <iunlockput>
    ilock(ip);
    8000565c:	8556                	mv	a0,s5
    8000565e:	ffffe097          	auipc	ra,0xffffe
    80005662:	63e080e7          	jalr	1598(ra) # 80003c9c <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005666:	000b059b          	sext.w	a1,s6
    8000566a:	4789                	li	a5,2
    8000566c:	02f59563          	bne	a1,a5,80005696 <create+0x8c>
    80005670:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffdc064>
    80005674:	37f9                	addiw	a5,a5,-2
    80005676:	17c2                	slli	a5,a5,0x30
    80005678:	93c1                	srli	a5,a5,0x30
    8000567a:	4705                	li	a4,1
    8000567c:	00f76d63          	bltu	a4,a5,80005696 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005680:	8556                	mv	a0,s5
    80005682:	60a6                	ld	ra,72(sp)
    80005684:	6406                	ld	s0,64(sp)
    80005686:	74e2                	ld	s1,56(sp)
    80005688:	7942                	ld	s2,48(sp)
    8000568a:	79a2                	ld	s3,40(sp)
    8000568c:	7a02                	ld	s4,32(sp)
    8000568e:	6ae2                	ld	s5,24(sp)
    80005690:	6b42                	ld	s6,16(sp)
    80005692:	6161                	addi	sp,sp,80
    80005694:	8082                	ret
    iunlockput(ip);
    80005696:	8556                	mv	a0,s5
    80005698:	fffff097          	auipc	ra,0xfffff
    8000569c:	866080e7          	jalr	-1946(ra) # 80003efe <iunlockput>
    return 0;
    800056a0:	4a81                	li	s5,0
    800056a2:	bff9                	j	80005680 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    800056a4:	85da                	mv	a1,s6
    800056a6:	4088                	lw	a0,0(s1)
    800056a8:	ffffe097          	auipc	ra,0xffffe
    800056ac:	456080e7          	jalr	1110(ra) # 80003afe <ialloc>
    800056b0:	8a2a                	mv	s4,a0
    800056b2:	c539                	beqz	a0,80005700 <create+0xf6>
  ilock(ip);
    800056b4:	ffffe097          	auipc	ra,0xffffe
    800056b8:	5e8080e7          	jalr	1512(ra) # 80003c9c <ilock>
  ip->major = major;
    800056bc:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    800056c0:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    800056c4:	4905                	li	s2,1
    800056c6:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    800056ca:	8552                	mv	a0,s4
    800056cc:	ffffe097          	auipc	ra,0xffffe
    800056d0:	504080e7          	jalr	1284(ra) # 80003bd0 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800056d4:	000b059b          	sext.w	a1,s6
    800056d8:	03258b63          	beq	a1,s2,8000570e <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    800056dc:	004a2603          	lw	a2,4(s4)
    800056e0:	fb040593          	addi	a1,s0,-80
    800056e4:	8526                	mv	a0,s1
    800056e6:	fffff097          	auipc	ra,0xfffff
    800056ea:	cb0080e7          	jalr	-848(ra) # 80004396 <dirlink>
    800056ee:	06054f63          	bltz	a0,8000576c <create+0x162>
  iunlockput(dp);
    800056f2:	8526                	mv	a0,s1
    800056f4:	fffff097          	auipc	ra,0xfffff
    800056f8:	80a080e7          	jalr	-2038(ra) # 80003efe <iunlockput>
  return ip;
    800056fc:	8ad2                	mv	s5,s4
    800056fe:	b749                	j	80005680 <create+0x76>
    iunlockput(dp);
    80005700:	8526                	mv	a0,s1
    80005702:	ffffe097          	auipc	ra,0xffffe
    80005706:	7fc080e7          	jalr	2044(ra) # 80003efe <iunlockput>
    return 0;
    8000570a:	8ad2                	mv	s5,s4
    8000570c:	bf95                	j	80005680 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000570e:	004a2603          	lw	a2,4(s4)
    80005712:	00003597          	auipc	a1,0x3
    80005716:	1f658593          	addi	a1,a1,502 # 80008908 <systemCallsNames+0x2b0>
    8000571a:	8552                	mv	a0,s4
    8000571c:	fffff097          	auipc	ra,0xfffff
    80005720:	c7a080e7          	jalr	-902(ra) # 80004396 <dirlink>
    80005724:	04054463          	bltz	a0,8000576c <create+0x162>
    80005728:	40d0                	lw	a2,4(s1)
    8000572a:	00003597          	auipc	a1,0x3
    8000572e:	1e658593          	addi	a1,a1,486 # 80008910 <systemCallsNames+0x2b8>
    80005732:	8552                	mv	a0,s4
    80005734:	fffff097          	auipc	ra,0xfffff
    80005738:	c62080e7          	jalr	-926(ra) # 80004396 <dirlink>
    8000573c:	02054863          	bltz	a0,8000576c <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    80005740:	004a2603          	lw	a2,4(s4)
    80005744:	fb040593          	addi	a1,s0,-80
    80005748:	8526                	mv	a0,s1
    8000574a:	fffff097          	auipc	ra,0xfffff
    8000574e:	c4c080e7          	jalr	-948(ra) # 80004396 <dirlink>
    80005752:	00054d63          	bltz	a0,8000576c <create+0x162>
    dp->nlink++;  // for ".."
    80005756:	04a4d783          	lhu	a5,74(s1)
    8000575a:	2785                	addiw	a5,a5,1
    8000575c:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005760:	8526                	mv	a0,s1
    80005762:	ffffe097          	auipc	ra,0xffffe
    80005766:	46e080e7          	jalr	1134(ra) # 80003bd0 <iupdate>
    8000576a:	b761                	j	800056f2 <create+0xe8>
  ip->nlink = 0;
    8000576c:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005770:	8552                	mv	a0,s4
    80005772:	ffffe097          	auipc	ra,0xffffe
    80005776:	45e080e7          	jalr	1118(ra) # 80003bd0 <iupdate>
  iunlockput(ip);
    8000577a:	8552                	mv	a0,s4
    8000577c:	ffffe097          	auipc	ra,0xffffe
    80005780:	782080e7          	jalr	1922(ra) # 80003efe <iunlockput>
  iunlockput(dp);
    80005784:	8526                	mv	a0,s1
    80005786:	ffffe097          	auipc	ra,0xffffe
    8000578a:	778080e7          	jalr	1912(ra) # 80003efe <iunlockput>
  return 0;
    8000578e:	bdcd                	j	80005680 <create+0x76>
    return 0;
    80005790:	8aaa                	mv	s5,a0
    80005792:	b5fd                	j	80005680 <create+0x76>

0000000080005794 <sys_dup>:
{
    80005794:	7179                	addi	sp,sp,-48
    80005796:	f406                	sd	ra,40(sp)
    80005798:	f022                	sd	s0,32(sp)
    8000579a:	ec26                	sd	s1,24(sp)
    8000579c:	e84a                	sd	s2,16(sp)
    8000579e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800057a0:	fd840613          	addi	a2,s0,-40
    800057a4:	4581                	li	a1,0
    800057a6:	4501                	li	a0,0
    800057a8:	00000097          	auipc	ra,0x0
    800057ac:	dc0080e7          	jalr	-576(ra) # 80005568 <argfd>
    return -1;
    800057b0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800057b2:	02054363          	bltz	a0,800057d8 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    800057b6:	fd843903          	ld	s2,-40(s0)
    800057ba:	854a                	mv	a0,s2
    800057bc:	00000097          	auipc	ra,0x0
    800057c0:	e0c080e7          	jalr	-500(ra) # 800055c8 <fdalloc>
    800057c4:	84aa                	mv	s1,a0
    return -1;
    800057c6:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800057c8:	00054863          	bltz	a0,800057d8 <sys_dup+0x44>
  filedup(f);
    800057cc:	854a                	mv	a0,s2
    800057ce:	fffff097          	auipc	ra,0xfffff
    800057d2:	310080e7          	jalr	784(ra) # 80004ade <filedup>
  return fd;
    800057d6:	87a6                	mv	a5,s1
}
    800057d8:	853e                	mv	a0,a5
    800057da:	70a2                	ld	ra,40(sp)
    800057dc:	7402                	ld	s0,32(sp)
    800057de:	64e2                	ld	s1,24(sp)
    800057e0:	6942                	ld	s2,16(sp)
    800057e2:	6145                	addi	sp,sp,48
    800057e4:	8082                	ret

00000000800057e6 <sys_read>:
{
    800057e6:	7179                	addi	sp,sp,-48
    800057e8:	f406                	sd	ra,40(sp)
    800057ea:	f022                	sd	s0,32(sp)
    800057ec:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800057ee:	fd840593          	addi	a1,s0,-40
    800057f2:	4505                	li	a0,1
    800057f4:	ffffd097          	auipc	ra,0xffffd
    800057f8:	746080e7          	jalr	1862(ra) # 80002f3a <argaddr>
  argint(2, &n);
    800057fc:	fe440593          	addi	a1,s0,-28
    80005800:	4509                	li	a0,2
    80005802:	ffffd097          	auipc	ra,0xffffd
    80005806:	716080e7          	jalr	1814(ra) # 80002f18 <argint>
  if(argfd(0, 0, &f) < 0)
    8000580a:	fe840613          	addi	a2,s0,-24
    8000580e:	4581                	li	a1,0
    80005810:	4501                	li	a0,0
    80005812:	00000097          	auipc	ra,0x0
    80005816:	d56080e7          	jalr	-682(ra) # 80005568 <argfd>
    8000581a:	87aa                	mv	a5,a0
    return -1;
    8000581c:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000581e:	0007cc63          	bltz	a5,80005836 <sys_read+0x50>
  return fileread(f, p, n);
    80005822:	fe442603          	lw	a2,-28(s0)
    80005826:	fd843583          	ld	a1,-40(s0)
    8000582a:	fe843503          	ld	a0,-24(s0)
    8000582e:	fffff097          	auipc	ra,0xfffff
    80005832:	43c080e7          	jalr	1084(ra) # 80004c6a <fileread>
}
    80005836:	70a2                	ld	ra,40(sp)
    80005838:	7402                	ld	s0,32(sp)
    8000583a:	6145                	addi	sp,sp,48
    8000583c:	8082                	ret

000000008000583e <sys_write>:
{
    8000583e:	7179                	addi	sp,sp,-48
    80005840:	f406                	sd	ra,40(sp)
    80005842:	f022                	sd	s0,32(sp)
    80005844:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005846:	fd840593          	addi	a1,s0,-40
    8000584a:	4505                	li	a0,1
    8000584c:	ffffd097          	auipc	ra,0xffffd
    80005850:	6ee080e7          	jalr	1774(ra) # 80002f3a <argaddr>
  argint(2, &n);
    80005854:	fe440593          	addi	a1,s0,-28
    80005858:	4509                	li	a0,2
    8000585a:	ffffd097          	auipc	ra,0xffffd
    8000585e:	6be080e7          	jalr	1726(ra) # 80002f18 <argint>
  if(argfd(0, 0, &f) < 0)
    80005862:	fe840613          	addi	a2,s0,-24
    80005866:	4581                	li	a1,0
    80005868:	4501                	li	a0,0
    8000586a:	00000097          	auipc	ra,0x0
    8000586e:	cfe080e7          	jalr	-770(ra) # 80005568 <argfd>
    80005872:	87aa                	mv	a5,a0
    return -1;
    80005874:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005876:	0007cc63          	bltz	a5,8000588e <sys_write+0x50>
  return filewrite(f, p, n);
    8000587a:	fe442603          	lw	a2,-28(s0)
    8000587e:	fd843583          	ld	a1,-40(s0)
    80005882:	fe843503          	ld	a0,-24(s0)
    80005886:	fffff097          	auipc	ra,0xfffff
    8000588a:	4a6080e7          	jalr	1190(ra) # 80004d2c <filewrite>
}
    8000588e:	70a2                	ld	ra,40(sp)
    80005890:	7402                	ld	s0,32(sp)
    80005892:	6145                	addi	sp,sp,48
    80005894:	8082                	ret

0000000080005896 <sys_close>:
{
    80005896:	1101                	addi	sp,sp,-32
    80005898:	ec06                	sd	ra,24(sp)
    8000589a:	e822                	sd	s0,16(sp)
    8000589c:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000589e:	fe040613          	addi	a2,s0,-32
    800058a2:	fec40593          	addi	a1,s0,-20
    800058a6:	4501                	li	a0,0
    800058a8:	00000097          	auipc	ra,0x0
    800058ac:	cc0080e7          	jalr	-832(ra) # 80005568 <argfd>
    return -1;
    800058b0:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800058b2:	02054463          	bltz	a0,800058da <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800058b6:	ffffc097          	auipc	ra,0xffffc
    800058ba:	0f6080e7          	jalr	246(ra) # 800019ac <myproc>
    800058be:	fec42783          	lw	a5,-20(s0)
    800058c2:	07e9                	addi	a5,a5,26
    800058c4:	078e                	slli	a5,a5,0x3
    800058c6:	953e                	add	a0,a0,a5
    800058c8:	00053023          	sd	zero,0(a0)
  fileclose(f);
    800058cc:	fe043503          	ld	a0,-32(s0)
    800058d0:	fffff097          	auipc	ra,0xfffff
    800058d4:	260080e7          	jalr	608(ra) # 80004b30 <fileclose>
  return 0;
    800058d8:	4781                	li	a5,0
}
    800058da:	853e                	mv	a0,a5
    800058dc:	60e2                	ld	ra,24(sp)
    800058de:	6442                	ld	s0,16(sp)
    800058e0:	6105                	addi	sp,sp,32
    800058e2:	8082                	ret

00000000800058e4 <sys_fstat>:
{
    800058e4:	1101                	addi	sp,sp,-32
    800058e6:	ec06                	sd	ra,24(sp)
    800058e8:	e822                	sd	s0,16(sp)
    800058ea:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    800058ec:	fe040593          	addi	a1,s0,-32
    800058f0:	4505                	li	a0,1
    800058f2:	ffffd097          	auipc	ra,0xffffd
    800058f6:	648080e7          	jalr	1608(ra) # 80002f3a <argaddr>
  if(argfd(0, 0, &f) < 0)
    800058fa:	fe840613          	addi	a2,s0,-24
    800058fe:	4581                	li	a1,0
    80005900:	4501                	li	a0,0
    80005902:	00000097          	auipc	ra,0x0
    80005906:	c66080e7          	jalr	-922(ra) # 80005568 <argfd>
    8000590a:	87aa                	mv	a5,a0
    return -1;
    8000590c:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000590e:	0007ca63          	bltz	a5,80005922 <sys_fstat+0x3e>
  return filestat(f, st);
    80005912:	fe043583          	ld	a1,-32(s0)
    80005916:	fe843503          	ld	a0,-24(s0)
    8000591a:	fffff097          	auipc	ra,0xfffff
    8000591e:	2de080e7          	jalr	734(ra) # 80004bf8 <filestat>
}
    80005922:	60e2                	ld	ra,24(sp)
    80005924:	6442                	ld	s0,16(sp)
    80005926:	6105                	addi	sp,sp,32
    80005928:	8082                	ret

000000008000592a <sys_link>:
{
    8000592a:	7169                	addi	sp,sp,-304
    8000592c:	f606                	sd	ra,296(sp)
    8000592e:	f222                	sd	s0,288(sp)
    80005930:	ee26                	sd	s1,280(sp)
    80005932:	ea4a                	sd	s2,272(sp)
    80005934:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005936:	08000613          	li	a2,128
    8000593a:	ed040593          	addi	a1,s0,-304
    8000593e:	4501                	li	a0,0
    80005940:	ffffd097          	auipc	ra,0xffffd
    80005944:	61c080e7          	jalr	1564(ra) # 80002f5c <argstr>
    return -1;
    80005948:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000594a:	10054e63          	bltz	a0,80005a66 <sys_link+0x13c>
    8000594e:	08000613          	li	a2,128
    80005952:	f5040593          	addi	a1,s0,-176
    80005956:	4505                	li	a0,1
    80005958:	ffffd097          	auipc	ra,0xffffd
    8000595c:	604080e7          	jalr	1540(ra) # 80002f5c <argstr>
    return -1;
    80005960:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005962:	10054263          	bltz	a0,80005a66 <sys_link+0x13c>
  begin_op();
    80005966:	fffff097          	auipc	ra,0xfffff
    8000596a:	d02080e7          	jalr	-766(ra) # 80004668 <begin_op>
  if((ip = namei(old)) == 0){
    8000596e:	ed040513          	addi	a0,s0,-304
    80005972:	fffff097          	auipc	ra,0xfffff
    80005976:	ad6080e7          	jalr	-1322(ra) # 80004448 <namei>
    8000597a:	84aa                	mv	s1,a0
    8000597c:	c551                	beqz	a0,80005a08 <sys_link+0xde>
  ilock(ip);
    8000597e:	ffffe097          	auipc	ra,0xffffe
    80005982:	31e080e7          	jalr	798(ra) # 80003c9c <ilock>
  if(ip->type == T_DIR){
    80005986:	04449703          	lh	a4,68(s1)
    8000598a:	4785                	li	a5,1
    8000598c:	08f70463          	beq	a4,a5,80005a14 <sys_link+0xea>
  ip->nlink++;
    80005990:	04a4d783          	lhu	a5,74(s1)
    80005994:	2785                	addiw	a5,a5,1
    80005996:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000599a:	8526                	mv	a0,s1
    8000599c:	ffffe097          	auipc	ra,0xffffe
    800059a0:	234080e7          	jalr	564(ra) # 80003bd0 <iupdate>
  iunlock(ip);
    800059a4:	8526                	mv	a0,s1
    800059a6:	ffffe097          	auipc	ra,0xffffe
    800059aa:	3b8080e7          	jalr	952(ra) # 80003d5e <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800059ae:	fd040593          	addi	a1,s0,-48
    800059b2:	f5040513          	addi	a0,s0,-176
    800059b6:	fffff097          	auipc	ra,0xfffff
    800059ba:	ab0080e7          	jalr	-1360(ra) # 80004466 <nameiparent>
    800059be:	892a                	mv	s2,a0
    800059c0:	c935                	beqz	a0,80005a34 <sys_link+0x10a>
  ilock(dp);
    800059c2:	ffffe097          	auipc	ra,0xffffe
    800059c6:	2da080e7          	jalr	730(ra) # 80003c9c <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800059ca:	00092703          	lw	a4,0(s2)
    800059ce:	409c                	lw	a5,0(s1)
    800059d0:	04f71d63          	bne	a4,a5,80005a2a <sys_link+0x100>
    800059d4:	40d0                	lw	a2,4(s1)
    800059d6:	fd040593          	addi	a1,s0,-48
    800059da:	854a                	mv	a0,s2
    800059dc:	fffff097          	auipc	ra,0xfffff
    800059e0:	9ba080e7          	jalr	-1606(ra) # 80004396 <dirlink>
    800059e4:	04054363          	bltz	a0,80005a2a <sys_link+0x100>
  iunlockput(dp);
    800059e8:	854a                	mv	a0,s2
    800059ea:	ffffe097          	auipc	ra,0xffffe
    800059ee:	514080e7          	jalr	1300(ra) # 80003efe <iunlockput>
  iput(ip);
    800059f2:	8526                	mv	a0,s1
    800059f4:	ffffe097          	auipc	ra,0xffffe
    800059f8:	462080e7          	jalr	1122(ra) # 80003e56 <iput>
  end_op();
    800059fc:	fffff097          	auipc	ra,0xfffff
    80005a00:	cea080e7          	jalr	-790(ra) # 800046e6 <end_op>
  return 0;
    80005a04:	4781                	li	a5,0
    80005a06:	a085                	j	80005a66 <sys_link+0x13c>
    end_op();
    80005a08:	fffff097          	auipc	ra,0xfffff
    80005a0c:	cde080e7          	jalr	-802(ra) # 800046e6 <end_op>
    return -1;
    80005a10:	57fd                	li	a5,-1
    80005a12:	a891                	j	80005a66 <sys_link+0x13c>
    iunlockput(ip);
    80005a14:	8526                	mv	a0,s1
    80005a16:	ffffe097          	auipc	ra,0xffffe
    80005a1a:	4e8080e7          	jalr	1256(ra) # 80003efe <iunlockput>
    end_op();
    80005a1e:	fffff097          	auipc	ra,0xfffff
    80005a22:	cc8080e7          	jalr	-824(ra) # 800046e6 <end_op>
    return -1;
    80005a26:	57fd                	li	a5,-1
    80005a28:	a83d                	j	80005a66 <sys_link+0x13c>
    iunlockput(dp);
    80005a2a:	854a                	mv	a0,s2
    80005a2c:	ffffe097          	auipc	ra,0xffffe
    80005a30:	4d2080e7          	jalr	1234(ra) # 80003efe <iunlockput>
  ilock(ip);
    80005a34:	8526                	mv	a0,s1
    80005a36:	ffffe097          	auipc	ra,0xffffe
    80005a3a:	266080e7          	jalr	614(ra) # 80003c9c <ilock>
  ip->nlink--;
    80005a3e:	04a4d783          	lhu	a5,74(s1)
    80005a42:	37fd                	addiw	a5,a5,-1
    80005a44:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005a48:	8526                	mv	a0,s1
    80005a4a:	ffffe097          	auipc	ra,0xffffe
    80005a4e:	186080e7          	jalr	390(ra) # 80003bd0 <iupdate>
  iunlockput(ip);
    80005a52:	8526                	mv	a0,s1
    80005a54:	ffffe097          	auipc	ra,0xffffe
    80005a58:	4aa080e7          	jalr	1194(ra) # 80003efe <iunlockput>
  end_op();
    80005a5c:	fffff097          	auipc	ra,0xfffff
    80005a60:	c8a080e7          	jalr	-886(ra) # 800046e6 <end_op>
  return -1;
    80005a64:	57fd                	li	a5,-1
}
    80005a66:	853e                	mv	a0,a5
    80005a68:	70b2                	ld	ra,296(sp)
    80005a6a:	7412                	ld	s0,288(sp)
    80005a6c:	64f2                	ld	s1,280(sp)
    80005a6e:	6952                	ld	s2,272(sp)
    80005a70:	6155                	addi	sp,sp,304
    80005a72:	8082                	ret

0000000080005a74 <sys_unlink>:
{
    80005a74:	7151                	addi	sp,sp,-240
    80005a76:	f586                	sd	ra,232(sp)
    80005a78:	f1a2                	sd	s0,224(sp)
    80005a7a:	eda6                	sd	s1,216(sp)
    80005a7c:	e9ca                	sd	s2,208(sp)
    80005a7e:	e5ce                	sd	s3,200(sp)
    80005a80:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005a82:	08000613          	li	a2,128
    80005a86:	f3040593          	addi	a1,s0,-208
    80005a8a:	4501                	li	a0,0
    80005a8c:	ffffd097          	auipc	ra,0xffffd
    80005a90:	4d0080e7          	jalr	1232(ra) # 80002f5c <argstr>
    80005a94:	18054163          	bltz	a0,80005c16 <sys_unlink+0x1a2>
  begin_op();
    80005a98:	fffff097          	auipc	ra,0xfffff
    80005a9c:	bd0080e7          	jalr	-1072(ra) # 80004668 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005aa0:	fb040593          	addi	a1,s0,-80
    80005aa4:	f3040513          	addi	a0,s0,-208
    80005aa8:	fffff097          	auipc	ra,0xfffff
    80005aac:	9be080e7          	jalr	-1602(ra) # 80004466 <nameiparent>
    80005ab0:	84aa                	mv	s1,a0
    80005ab2:	c979                	beqz	a0,80005b88 <sys_unlink+0x114>
  ilock(dp);
    80005ab4:	ffffe097          	auipc	ra,0xffffe
    80005ab8:	1e8080e7          	jalr	488(ra) # 80003c9c <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005abc:	00003597          	auipc	a1,0x3
    80005ac0:	e4c58593          	addi	a1,a1,-436 # 80008908 <systemCallsNames+0x2b0>
    80005ac4:	fb040513          	addi	a0,s0,-80
    80005ac8:	ffffe097          	auipc	ra,0xffffe
    80005acc:	69e080e7          	jalr	1694(ra) # 80004166 <namecmp>
    80005ad0:	14050a63          	beqz	a0,80005c24 <sys_unlink+0x1b0>
    80005ad4:	00003597          	auipc	a1,0x3
    80005ad8:	e3c58593          	addi	a1,a1,-452 # 80008910 <systemCallsNames+0x2b8>
    80005adc:	fb040513          	addi	a0,s0,-80
    80005ae0:	ffffe097          	auipc	ra,0xffffe
    80005ae4:	686080e7          	jalr	1670(ra) # 80004166 <namecmp>
    80005ae8:	12050e63          	beqz	a0,80005c24 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005aec:	f2c40613          	addi	a2,s0,-212
    80005af0:	fb040593          	addi	a1,s0,-80
    80005af4:	8526                	mv	a0,s1
    80005af6:	ffffe097          	auipc	ra,0xffffe
    80005afa:	68a080e7          	jalr	1674(ra) # 80004180 <dirlookup>
    80005afe:	892a                	mv	s2,a0
    80005b00:	12050263          	beqz	a0,80005c24 <sys_unlink+0x1b0>
  ilock(ip);
    80005b04:	ffffe097          	auipc	ra,0xffffe
    80005b08:	198080e7          	jalr	408(ra) # 80003c9c <ilock>
  if(ip->nlink < 1)
    80005b0c:	04a91783          	lh	a5,74(s2)
    80005b10:	08f05263          	blez	a5,80005b94 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005b14:	04491703          	lh	a4,68(s2)
    80005b18:	4785                	li	a5,1
    80005b1a:	08f70563          	beq	a4,a5,80005ba4 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005b1e:	4641                	li	a2,16
    80005b20:	4581                	li	a1,0
    80005b22:	fc040513          	addi	a0,s0,-64
    80005b26:	ffffb097          	auipc	ra,0xffffb
    80005b2a:	1ac080e7          	jalr	428(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005b2e:	4741                	li	a4,16
    80005b30:	f2c42683          	lw	a3,-212(s0)
    80005b34:	fc040613          	addi	a2,s0,-64
    80005b38:	4581                	li	a1,0
    80005b3a:	8526                	mv	a0,s1
    80005b3c:	ffffe097          	auipc	ra,0xffffe
    80005b40:	50c080e7          	jalr	1292(ra) # 80004048 <writei>
    80005b44:	47c1                	li	a5,16
    80005b46:	0af51563          	bne	a0,a5,80005bf0 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005b4a:	04491703          	lh	a4,68(s2)
    80005b4e:	4785                	li	a5,1
    80005b50:	0af70863          	beq	a4,a5,80005c00 <sys_unlink+0x18c>
  iunlockput(dp);
    80005b54:	8526                	mv	a0,s1
    80005b56:	ffffe097          	auipc	ra,0xffffe
    80005b5a:	3a8080e7          	jalr	936(ra) # 80003efe <iunlockput>
  ip->nlink--;
    80005b5e:	04a95783          	lhu	a5,74(s2)
    80005b62:	37fd                	addiw	a5,a5,-1
    80005b64:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005b68:	854a                	mv	a0,s2
    80005b6a:	ffffe097          	auipc	ra,0xffffe
    80005b6e:	066080e7          	jalr	102(ra) # 80003bd0 <iupdate>
  iunlockput(ip);
    80005b72:	854a                	mv	a0,s2
    80005b74:	ffffe097          	auipc	ra,0xffffe
    80005b78:	38a080e7          	jalr	906(ra) # 80003efe <iunlockput>
  end_op();
    80005b7c:	fffff097          	auipc	ra,0xfffff
    80005b80:	b6a080e7          	jalr	-1174(ra) # 800046e6 <end_op>
  return 0;
    80005b84:	4501                	li	a0,0
    80005b86:	a84d                	j	80005c38 <sys_unlink+0x1c4>
    end_op();
    80005b88:	fffff097          	auipc	ra,0xfffff
    80005b8c:	b5e080e7          	jalr	-1186(ra) # 800046e6 <end_op>
    return -1;
    80005b90:	557d                	li	a0,-1
    80005b92:	a05d                	j	80005c38 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005b94:	00003517          	auipc	a0,0x3
    80005b98:	d8450513          	addi	a0,a0,-636 # 80008918 <systemCallsNames+0x2c0>
    80005b9c:	ffffb097          	auipc	ra,0xffffb
    80005ba0:	9a4080e7          	jalr	-1628(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005ba4:	04c92703          	lw	a4,76(s2)
    80005ba8:	02000793          	li	a5,32
    80005bac:	f6e7f9e3          	bgeu	a5,a4,80005b1e <sys_unlink+0xaa>
    80005bb0:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005bb4:	4741                	li	a4,16
    80005bb6:	86ce                	mv	a3,s3
    80005bb8:	f1840613          	addi	a2,s0,-232
    80005bbc:	4581                	li	a1,0
    80005bbe:	854a                	mv	a0,s2
    80005bc0:	ffffe097          	auipc	ra,0xffffe
    80005bc4:	390080e7          	jalr	912(ra) # 80003f50 <readi>
    80005bc8:	47c1                	li	a5,16
    80005bca:	00f51b63          	bne	a0,a5,80005be0 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005bce:	f1845783          	lhu	a5,-232(s0)
    80005bd2:	e7a1                	bnez	a5,80005c1a <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005bd4:	29c1                	addiw	s3,s3,16
    80005bd6:	04c92783          	lw	a5,76(s2)
    80005bda:	fcf9ede3          	bltu	s3,a5,80005bb4 <sys_unlink+0x140>
    80005bde:	b781                	j	80005b1e <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005be0:	00003517          	auipc	a0,0x3
    80005be4:	d5050513          	addi	a0,a0,-688 # 80008930 <systemCallsNames+0x2d8>
    80005be8:	ffffb097          	auipc	ra,0xffffb
    80005bec:	958080e7          	jalr	-1704(ra) # 80000540 <panic>
    panic("unlink: writei");
    80005bf0:	00003517          	auipc	a0,0x3
    80005bf4:	d5850513          	addi	a0,a0,-680 # 80008948 <systemCallsNames+0x2f0>
    80005bf8:	ffffb097          	auipc	ra,0xffffb
    80005bfc:	948080e7          	jalr	-1720(ra) # 80000540 <panic>
    dp->nlink--;
    80005c00:	04a4d783          	lhu	a5,74(s1)
    80005c04:	37fd                	addiw	a5,a5,-1
    80005c06:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005c0a:	8526                	mv	a0,s1
    80005c0c:	ffffe097          	auipc	ra,0xffffe
    80005c10:	fc4080e7          	jalr	-60(ra) # 80003bd0 <iupdate>
    80005c14:	b781                	j	80005b54 <sys_unlink+0xe0>
    return -1;
    80005c16:	557d                	li	a0,-1
    80005c18:	a005                	j	80005c38 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005c1a:	854a                	mv	a0,s2
    80005c1c:	ffffe097          	auipc	ra,0xffffe
    80005c20:	2e2080e7          	jalr	738(ra) # 80003efe <iunlockput>
  iunlockput(dp);
    80005c24:	8526                	mv	a0,s1
    80005c26:	ffffe097          	auipc	ra,0xffffe
    80005c2a:	2d8080e7          	jalr	728(ra) # 80003efe <iunlockput>
  end_op();
    80005c2e:	fffff097          	auipc	ra,0xfffff
    80005c32:	ab8080e7          	jalr	-1352(ra) # 800046e6 <end_op>
  return -1;
    80005c36:	557d                	li	a0,-1
}
    80005c38:	70ae                	ld	ra,232(sp)
    80005c3a:	740e                	ld	s0,224(sp)
    80005c3c:	64ee                	ld	s1,216(sp)
    80005c3e:	694e                	ld	s2,208(sp)
    80005c40:	69ae                	ld	s3,200(sp)
    80005c42:	616d                	addi	sp,sp,240
    80005c44:	8082                	ret

0000000080005c46 <sys_open>:

uint64
sys_open(void)
{
    80005c46:	7131                	addi	sp,sp,-192
    80005c48:	fd06                	sd	ra,184(sp)
    80005c4a:	f922                	sd	s0,176(sp)
    80005c4c:	f526                	sd	s1,168(sp)
    80005c4e:	f14a                	sd	s2,160(sp)
    80005c50:	ed4e                	sd	s3,152(sp)
    80005c52:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005c54:	f4c40593          	addi	a1,s0,-180
    80005c58:	4505                	li	a0,1
    80005c5a:	ffffd097          	auipc	ra,0xffffd
    80005c5e:	2be080e7          	jalr	702(ra) # 80002f18 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005c62:	08000613          	li	a2,128
    80005c66:	f5040593          	addi	a1,s0,-176
    80005c6a:	4501                	li	a0,0
    80005c6c:	ffffd097          	auipc	ra,0xffffd
    80005c70:	2f0080e7          	jalr	752(ra) # 80002f5c <argstr>
    80005c74:	87aa                	mv	a5,a0
    return -1;
    80005c76:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005c78:	0a07c963          	bltz	a5,80005d2a <sys_open+0xe4>

  begin_op();
    80005c7c:	fffff097          	auipc	ra,0xfffff
    80005c80:	9ec080e7          	jalr	-1556(ra) # 80004668 <begin_op>

  if(omode & O_CREATE){
    80005c84:	f4c42783          	lw	a5,-180(s0)
    80005c88:	2007f793          	andi	a5,a5,512
    80005c8c:	cfc5                	beqz	a5,80005d44 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005c8e:	4681                	li	a3,0
    80005c90:	4601                	li	a2,0
    80005c92:	4589                	li	a1,2
    80005c94:	f5040513          	addi	a0,s0,-176
    80005c98:	00000097          	auipc	ra,0x0
    80005c9c:	972080e7          	jalr	-1678(ra) # 8000560a <create>
    80005ca0:	84aa                	mv	s1,a0
    if(ip == 0){
    80005ca2:	c959                	beqz	a0,80005d38 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005ca4:	04449703          	lh	a4,68(s1)
    80005ca8:	478d                	li	a5,3
    80005caa:	00f71763          	bne	a4,a5,80005cb8 <sys_open+0x72>
    80005cae:	0464d703          	lhu	a4,70(s1)
    80005cb2:	47a5                	li	a5,9
    80005cb4:	0ce7ed63          	bltu	a5,a4,80005d8e <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005cb8:	fffff097          	auipc	ra,0xfffff
    80005cbc:	dbc080e7          	jalr	-580(ra) # 80004a74 <filealloc>
    80005cc0:	89aa                	mv	s3,a0
    80005cc2:	10050363          	beqz	a0,80005dc8 <sys_open+0x182>
    80005cc6:	00000097          	auipc	ra,0x0
    80005cca:	902080e7          	jalr	-1790(ra) # 800055c8 <fdalloc>
    80005cce:	892a                	mv	s2,a0
    80005cd0:	0e054763          	bltz	a0,80005dbe <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005cd4:	04449703          	lh	a4,68(s1)
    80005cd8:	478d                	li	a5,3
    80005cda:	0cf70563          	beq	a4,a5,80005da4 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005cde:	4789                	li	a5,2
    80005ce0:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005ce4:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005ce8:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005cec:	f4c42783          	lw	a5,-180(s0)
    80005cf0:	0017c713          	xori	a4,a5,1
    80005cf4:	8b05                	andi	a4,a4,1
    80005cf6:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005cfa:	0037f713          	andi	a4,a5,3
    80005cfe:	00e03733          	snez	a4,a4
    80005d02:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005d06:	4007f793          	andi	a5,a5,1024
    80005d0a:	c791                	beqz	a5,80005d16 <sys_open+0xd0>
    80005d0c:	04449703          	lh	a4,68(s1)
    80005d10:	4789                	li	a5,2
    80005d12:	0af70063          	beq	a4,a5,80005db2 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005d16:	8526                	mv	a0,s1
    80005d18:	ffffe097          	auipc	ra,0xffffe
    80005d1c:	046080e7          	jalr	70(ra) # 80003d5e <iunlock>
  end_op();
    80005d20:	fffff097          	auipc	ra,0xfffff
    80005d24:	9c6080e7          	jalr	-1594(ra) # 800046e6 <end_op>

  return fd;
    80005d28:	854a                	mv	a0,s2
}
    80005d2a:	70ea                	ld	ra,184(sp)
    80005d2c:	744a                	ld	s0,176(sp)
    80005d2e:	74aa                	ld	s1,168(sp)
    80005d30:	790a                	ld	s2,160(sp)
    80005d32:	69ea                	ld	s3,152(sp)
    80005d34:	6129                	addi	sp,sp,192
    80005d36:	8082                	ret
      end_op();
    80005d38:	fffff097          	auipc	ra,0xfffff
    80005d3c:	9ae080e7          	jalr	-1618(ra) # 800046e6 <end_op>
      return -1;
    80005d40:	557d                	li	a0,-1
    80005d42:	b7e5                	j	80005d2a <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005d44:	f5040513          	addi	a0,s0,-176
    80005d48:	ffffe097          	auipc	ra,0xffffe
    80005d4c:	700080e7          	jalr	1792(ra) # 80004448 <namei>
    80005d50:	84aa                	mv	s1,a0
    80005d52:	c905                	beqz	a0,80005d82 <sys_open+0x13c>
    ilock(ip);
    80005d54:	ffffe097          	auipc	ra,0xffffe
    80005d58:	f48080e7          	jalr	-184(ra) # 80003c9c <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005d5c:	04449703          	lh	a4,68(s1)
    80005d60:	4785                	li	a5,1
    80005d62:	f4f711e3          	bne	a4,a5,80005ca4 <sys_open+0x5e>
    80005d66:	f4c42783          	lw	a5,-180(s0)
    80005d6a:	d7b9                	beqz	a5,80005cb8 <sys_open+0x72>
      iunlockput(ip);
    80005d6c:	8526                	mv	a0,s1
    80005d6e:	ffffe097          	auipc	ra,0xffffe
    80005d72:	190080e7          	jalr	400(ra) # 80003efe <iunlockput>
      end_op();
    80005d76:	fffff097          	auipc	ra,0xfffff
    80005d7a:	970080e7          	jalr	-1680(ra) # 800046e6 <end_op>
      return -1;
    80005d7e:	557d                	li	a0,-1
    80005d80:	b76d                	j	80005d2a <sys_open+0xe4>
      end_op();
    80005d82:	fffff097          	auipc	ra,0xfffff
    80005d86:	964080e7          	jalr	-1692(ra) # 800046e6 <end_op>
      return -1;
    80005d8a:	557d                	li	a0,-1
    80005d8c:	bf79                	j	80005d2a <sys_open+0xe4>
    iunlockput(ip);
    80005d8e:	8526                	mv	a0,s1
    80005d90:	ffffe097          	auipc	ra,0xffffe
    80005d94:	16e080e7          	jalr	366(ra) # 80003efe <iunlockput>
    end_op();
    80005d98:	fffff097          	auipc	ra,0xfffff
    80005d9c:	94e080e7          	jalr	-1714(ra) # 800046e6 <end_op>
    return -1;
    80005da0:	557d                	li	a0,-1
    80005da2:	b761                	j	80005d2a <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005da4:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005da8:	04649783          	lh	a5,70(s1)
    80005dac:	02f99223          	sh	a5,36(s3)
    80005db0:	bf25                	j	80005ce8 <sys_open+0xa2>
    itrunc(ip);
    80005db2:	8526                	mv	a0,s1
    80005db4:	ffffe097          	auipc	ra,0xffffe
    80005db8:	ff6080e7          	jalr	-10(ra) # 80003daa <itrunc>
    80005dbc:	bfa9                	j	80005d16 <sys_open+0xd0>
      fileclose(f);
    80005dbe:	854e                	mv	a0,s3
    80005dc0:	fffff097          	auipc	ra,0xfffff
    80005dc4:	d70080e7          	jalr	-656(ra) # 80004b30 <fileclose>
    iunlockput(ip);
    80005dc8:	8526                	mv	a0,s1
    80005dca:	ffffe097          	auipc	ra,0xffffe
    80005dce:	134080e7          	jalr	308(ra) # 80003efe <iunlockput>
    end_op();
    80005dd2:	fffff097          	auipc	ra,0xfffff
    80005dd6:	914080e7          	jalr	-1772(ra) # 800046e6 <end_op>
    return -1;
    80005dda:	557d                	li	a0,-1
    80005ddc:	b7b9                	j	80005d2a <sys_open+0xe4>

0000000080005dde <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005dde:	7175                	addi	sp,sp,-144
    80005de0:	e506                	sd	ra,136(sp)
    80005de2:	e122                	sd	s0,128(sp)
    80005de4:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005de6:	fffff097          	auipc	ra,0xfffff
    80005dea:	882080e7          	jalr	-1918(ra) # 80004668 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005dee:	08000613          	li	a2,128
    80005df2:	f7040593          	addi	a1,s0,-144
    80005df6:	4501                	li	a0,0
    80005df8:	ffffd097          	auipc	ra,0xffffd
    80005dfc:	164080e7          	jalr	356(ra) # 80002f5c <argstr>
    80005e00:	02054963          	bltz	a0,80005e32 <sys_mkdir+0x54>
    80005e04:	4681                	li	a3,0
    80005e06:	4601                	li	a2,0
    80005e08:	4585                	li	a1,1
    80005e0a:	f7040513          	addi	a0,s0,-144
    80005e0e:	fffff097          	auipc	ra,0xfffff
    80005e12:	7fc080e7          	jalr	2044(ra) # 8000560a <create>
    80005e16:	cd11                	beqz	a0,80005e32 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005e18:	ffffe097          	auipc	ra,0xffffe
    80005e1c:	0e6080e7          	jalr	230(ra) # 80003efe <iunlockput>
  end_op();
    80005e20:	fffff097          	auipc	ra,0xfffff
    80005e24:	8c6080e7          	jalr	-1850(ra) # 800046e6 <end_op>
  return 0;
    80005e28:	4501                	li	a0,0
}
    80005e2a:	60aa                	ld	ra,136(sp)
    80005e2c:	640a                	ld	s0,128(sp)
    80005e2e:	6149                	addi	sp,sp,144
    80005e30:	8082                	ret
    end_op();
    80005e32:	fffff097          	auipc	ra,0xfffff
    80005e36:	8b4080e7          	jalr	-1868(ra) # 800046e6 <end_op>
    return -1;
    80005e3a:	557d                	li	a0,-1
    80005e3c:	b7fd                	j	80005e2a <sys_mkdir+0x4c>

0000000080005e3e <sys_mknod>:

uint64
sys_mknod(void)
{
    80005e3e:	7135                	addi	sp,sp,-160
    80005e40:	ed06                	sd	ra,152(sp)
    80005e42:	e922                	sd	s0,144(sp)
    80005e44:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005e46:	fffff097          	auipc	ra,0xfffff
    80005e4a:	822080e7          	jalr	-2014(ra) # 80004668 <begin_op>
  argint(1, &major);
    80005e4e:	f6c40593          	addi	a1,s0,-148
    80005e52:	4505                	li	a0,1
    80005e54:	ffffd097          	auipc	ra,0xffffd
    80005e58:	0c4080e7          	jalr	196(ra) # 80002f18 <argint>
  argint(2, &minor);
    80005e5c:	f6840593          	addi	a1,s0,-152
    80005e60:	4509                	li	a0,2
    80005e62:	ffffd097          	auipc	ra,0xffffd
    80005e66:	0b6080e7          	jalr	182(ra) # 80002f18 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005e6a:	08000613          	li	a2,128
    80005e6e:	f7040593          	addi	a1,s0,-144
    80005e72:	4501                	li	a0,0
    80005e74:	ffffd097          	auipc	ra,0xffffd
    80005e78:	0e8080e7          	jalr	232(ra) # 80002f5c <argstr>
    80005e7c:	02054b63          	bltz	a0,80005eb2 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005e80:	f6841683          	lh	a3,-152(s0)
    80005e84:	f6c41603          	lh	a2,-148(s0)
    80005e88:	458d                	li	a1,3
    80005e8a:	f7040513          	addi	a0,s0,-144
    80005e8e:	fffff097          	auipc	ra,0xfffff
    80005e92:	77c080e7          	jalr	1916(ra) # 8000560a <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005e96:	cd11                	beqz	a0,80005eb2 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005e98:	ffffe097          	auipc	ra,0xffffe
    80005e9c:	066080e7          	jalr	102(ra) # 80003efe <iunlockput>
  end_op();
    80005ea0:	fffff097          	auipc	ra,0xfffff
    80005ea4:	846080e7          	jalr	-1978(ra) # 800046e6 <end_op>
  return 0;
    80005ea8:	4501                	li	a0,0
}
    80005eaa:	60ea                	ld	ra,152(sp)
    80005eac:	644a                	ld	s0,144(sp)
    80005eae:	610d                	addi	sp,sp,160
    80005eb0:	8082                	ret
    end_op();
    80005eb2:	fffff097          	auipc	ra,0xfffff
    80005eb6:	834080e7          	jalr	-1996(ra) # 800046e6 <end_op>
    return -1;
    80005eba:	557d                	li	a0,-1
    80005ebc:	b7fd                	j	80005eaa <sys_mknod+0x6c>

0000000080005ebe <sys_chdir>:

uint64
sys_chdir(void)
{
    80005ebe:	7135                	addi	sp,sp,-160
    80005ec0:	ed06                	sd	ra,152(sp)
    80005ec2:	e922                	sd	s0,144(sp)
    80005ec4:	e526                	sd	s1,136(sp)
    80005ec6:	e14a                	sd	s2,128(sp)
    80005ec8:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005eca:	ffffc097          	auipc	ra,0xffffc
    80005ece:	ae2080e7          	jalr	-1310(ra) # 800019ac <myproc>
    80005ed2:	892a                	mv	s2,a0
  
  begin_op();
    80005ed4:	ffffe097          	auipc	ra,0xffffe
    80005ed8:	794080e7          	jalr	1940(ra) # 80004668 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005edc:	08000613          	li	a2,128
    80005ee0:	f6040593          	addi	a1,s0,-160
    80005ee4:	4501                	li	a0,0
    80005ee6:	ffffd097          	auipc	ra,0xffffd
    80005eea:	076080e7          	jalr	118(ra) # 80002f5c <argstr>
    80005eee:	04054b63          	bltz	a0,80005f44 <sys_chdir+0x86>
    80005ef2:	f6040513          	addi	a0,s0,-160
    80005ef6:	ffffe097          	auipc	ra,0xffffe
    80005efa:	552080e7          	jalr	1362(ra) # 80004448 <namei>
    80005efe:	84aa                	mv	s1,a0
    80005f00:	c131                	beqz	a0,80005f44 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005f02:	ffffe097          	auipc	ra,0xffffe
    80005f06:	d9a080e7          	jalr	-614(ra) # 80003c9c <ilock>
  if(ip->type != T_DIR){
    80005f0a:	04449703          	lh	a4,68(s1)
    80005f0e:	4785                	li	a5,1
    80005f10:	04f71063          	bne	a4,a5,80005f50 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005f14:	8526                	mv	a0,s1
    80005f16:	ffffe097          	auipc	ra,0xffffe
    80005f1a:	e48080e7          	jalr	-440(ra) # 80003d5e <iunlock>
  iput(p->cwd);
    80005f1e:	15093503          	ld	a0,336(s2)
    80005f22:	ffffe097          	auipc	ra,0xffffe
    80005f26:	f34080e7          	jalr	-204(ra) # 80003e56 <iput>
  end_op();
    80005f2a:	ffffe097          	auipc	ra,0xffffe
    80005f2e:	7bc080e7          	jalr	1980(ra) # 800046e6 <end_op>
  p->cwd = ip;
    80005f32:	14993823          	sd	s1,336(s2)
  return 0;
    80005f36:	4501                	li	a0,0
}
    80005f38:	60ea                	ld	ra,152(sp)
    80005f3a:	644a                	ld	s0,144(sp)
    80005f3c:	64aa                	ld	s1,136(sp)
    80005f3e:	690a                	ld	s2,128(sp)
    80005f40:	610d                	addi	sp,sp,160
    80005f42:	8082                	ret
    end_op();
    80005f44:	ffffe097          	auipc	ra,0xffffe
    80005f48:	7a2080e7          	jalr	1954(ra) # 800046e6 <end_op>
    return -1;
    80005f4c:	557d                	li	a0,-1
    80005f4e:	b7ed                	j	80005f38 <sys_chdir+0x7a>
    iunlockput(ip);
    80005f50:	8526                	mv	a0,s1
    80005f52:	ffffe097          	auipc	ra,0xffffe
    80005f56:	fac080e7          	jalr	-84(ra) # 80003efe <iunlockput>
    end_op();
    80005f5a:	ffffe097          	auipc	ra,0xffffe
    80005f5e:	78c080e7          	jalr	1932(ra) # 800046e6 <end_op>
    return -1;
    80005f62:	557d                	li	a0,-1
    80005f64:	bfd1                	j	80005f38 <sys_chdir+0x7a>

0000000080005f66 <sys_exec>:

uint64
sys_exec(void)
{
    80005f66:	7145                	addi	sp,sp,-464
    80005f68:	e786                	sd	ra,456(sp)
    80005f6a:	e3a2                	sd	s0,448(sp)
    80005f6c:	ff26                	sd	s1,440(sp)
    80005f6e:	fb4a                	sd	s2,432(sp)
    80005f70:	f74e                	sd	s3,424(sp)
    80005f72:	f352                	sd	s4,416(sp)
    80005f74:	ef56                	sd	s5,408(sp)
    80005f76:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005f78:	e3840593          	addi	a1,s0,-456
    80005f7c:	4505                	li	a0,1
    80005f7e:	ffffd097          	auipc	ra,0xffffd
    80005f82:	fbc080e7          	jalr	-68(ra) # 80002f3a <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005f86:	08000613          	li	a2,128
    80005f8a:	f4040593          	addi	a1,s0,-192
    80005f8e:	4501                	li	a0,0
    80005f90:	ffffd097          	auipc	ra,0xffffd
    80005f94:	fcc080e7          	jalr	-52(ra) # 80002f5c <argstr>
    80005f98:	87aa                	mv	a5,a0
    return -1;
    80005f9a:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005f9c:	0c07c363          	bltz	a5,80006062 <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    80005fa0:	10000613          	li	a2,256
    80005fa4:	4581                	li	a1,0
    80005fa6:	e4040513          	addi	a0,s0,-448
    80005faa:	ffffb097          	auipc	ra,0xffffb
    80005fae:	d28080e7          	jalr	-728(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005fb2:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005fb6:	89a6                	mv	s3,s1
    80005fb8:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005fba:	02000a13          	li	s4,32
    80005fbe:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005fc2:	00391513          	slli	a0,s2,0x3
    80005fc6:	e3040593          	addi	a1,s0,-464
    80005fca:	e3843783          	ld	a5,-456(s0)
    80005fce:	953e                	add	a0,a0,a5
    80005fd0:	ffffd097          	auipc	ra,0xffffd
    80005fd4:	eaa080e7          	jalr	-342(ra) # 80002e7a <fetchaddr>
    80005fd8:	02054a63          	bltz	a0,8000600c <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005fdc:	e3043783          	ld	a5,-464(s0)
    80005fe0:	c3b9                	beqz	a5,80006026 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005fe2:	ffffb097          	auipc	ra,0xffffb
    80005fe6:	b04080e7          	jalr	-1276(ra) # 80000ae6 <kalloc>
    80005fea:	85aa                	mv	a1,a0
    80005fec:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005ff0:	cd11                	beqz	a0,8000600c <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005ff2:	6605                	lui	a2,0x1
    80005ff4:	e3043503          	ld	a0,-464(s0)
    80005ff8:	ffffd097          	auipc	ra,0xffffd
    80005ffc:	ed4080e7          	jalr	-300(ra) # 80002ecc <fetchstr>
    80006000:	00054663          	bltz	a0,8000600c <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80006004:	0905                	addi	s2,s2,1
    80006006:	09a1                	addi	s3,s3,8
    80006008:	fb491be3          	bne	s2,s4,80005fbe <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000600c:	f4040913          	addi	s2,s0,-192
    80006010:	6088                	ld	a0,0(s1)
    80006012:	c539                	beqz	a0,80006060 <sys_exec+0xfa>
    kfree(argv[i]);
    80006014:	ffffb097          	auipc	ra,0xffffb
    80006018:	9d4080e7          	jalr	-1580(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000601c:	04a1                	addi	s1,s1,8
    8000601e:	ff2499e3          	bne	s1,s2,80006010 <sys_exec+0xaa>
  return -1;
    80006022:	557d                	li	a0,-1
    80006024:	a83d                	j	80006062 <sys_exec+0xfc>
      argv[i] = 0;
    80006026:	0a8e                	slli	s5,s5,0x3
    80006028:	fc0a8793          	addi	a5,s5,-64
    8000602c:	00878ab3          	add	s5,a5,s0
    80006030:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80006034:	e4040593          	addi	a1,s0,-448
    80006038:	f4040513          	addi	a0,s0,-192
    8000603c:	fffff097          	auipc	ra,0xfffff
    80006040:	16e080e7          	jalr	366(ra) # 800051aa <exec>
    80006044:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006046:	f4040993          	addi	s3,s0,-192
    8000604a:	6088                	ld	a0,0(s1)
    8000604c:	c901                	beqz	a0,8000605c <sys_exec+0xf6>
    kfree(argv[i]);
    8000604e:	ffffb097          	auipc	ra,0xffffb
    80006052:	99a080e7          	jalr	-1638(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006056:	04a1                	addi	s1,s1,8
    80006058:	ff3499e3          	bne	s1,s3,8000604a <sys_exec+0xe4>
  return ret;
    8000605c:	854a                	mv	a0,s2
    8000605e:	a011                	j	80006062 <sys_exec+0xfc>
  return -1;
    80006060:	557d                	li	a0,-1
}
    80006062:	60be                	ld	ra,456(sp)
    80006064:	641e                	ld	s0,448(sp)
    80006066:	74fa                	ld	s1,440(sp)
    80006068:	795a                	ld	s2,432(sp)
    8000606a:	79ba                	ld	s3,424(sp)
    8000606c:	7a1a                	ld	s4,416(sp)
    8000606e:	6afa                	ld	s5,408(sp)
    80006070:	6179                	addi	sp,sp,464
    80006072:	8082                	ret

0000000080006074 <sys_pipe>:

uint64
sys_pipe(void)
{
    80006074:	7139                	addi	sp,sp,-64
    80006076:	fc06                	sd	ra,56(sp)
    80006078:	f822                	sd	s0,48(sp)
    8000607a:	f426                	sd	s1,40(sp)
    8000607c:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    8000607e:	ffffc097          	auipc	ra,0xffffc
    80006082:	92e080e7          	jalr	-1746(ra) # 800019ac <myproc>
    80006086:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80006088:	fd840593          	addi	a1,s0,-40
    8000608c:	4501                	li	a0,0
    8000608e:	ffffd097          	auipc	ra,0xffffd
    80006092:	eac080e7          	jalr	-340(ra) # 80002f3a <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80006096:	fc840593          	addi	a1,s0,-56
    8000609a:	fd040513          	addi	a0,s0,-48
    8000609e:	fffff097          	auipc	ra,0xfffff
    800060a2:	dc2080e7          	jalr	-574(ra) # 80004e60 <pipealloc>
    return -1;
    800060a6:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800060a8:	0c054463          	bltz	a0,80006170 <sys_pipe+0xfc>
  fd0 = -1;
    800060ac:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800060b0:	fd043503          	ld	a0,-48(s0)
    800060b4:	fffff097          	auipc	ra,0xfffff
    800060b8:	514080e7          	jalr	1300(ra) # 800055c8 <fdalloc>
    800060bc:	fca42223          	sw	a0,-60(s0)
    800060c0:	08054b63          	bltz	a0,80006156 <sys_pipe+0xe2>
    800060c4:	fc843503          	ld	a0,-56(s0)
    800060c8:	fffff097          	auipc	ra,0xfffff
    800060cc:	500080e7          	jalr	1280(ra) # 800055c8 <fdalloc>
    800060d0:	fca42023          	sw	a0,-64(s0)
    800060d4:	06054863          	bltz	a0,80006144 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800060d8:	4691                	li	a3,4
    800060da:	fc440613          	addi	a2,s0,-60
    800060de:	fd843583          	ld	a1,-40(s0)
    800060e2:	68a8                	ld	a0,80(s1)
    800060e4:	ffffb097          	auipc	ra,0xffffb
    800060e8:	588080e7          	jalr	1416(ra) # 8000166c <copyout>
    800060ec:	02054063          	bltz	a0,8000610c <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    800060f0:	4691                	li	a3,4
    800060f2:	fc040613          	addi	a2,s0,-64
    800060f6:	fd843583          	ld	a1,-40(s0)
    800060fa:	0591                	addi	a1,a1,4
    800060fc:	68a8                	ld	a0,80(s1)
    800060fe:	ffffb097          	auipc	ra,0xffffb
    80006102:	56e080e7          	jalr	1390(ra) # 8000166c <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006106:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006108:	06055463          	bgez	a0,80006170 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    8000610c:	fc442783          	lw	a5,-60(s0)
    80006110:	07e9                	addi	a5,a5,26
    80006112:	078e                	slli	a5,a5,0x3
    80006114:	97a6                	add	a5,a5,s1
    80006116:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    8000611a:	fc042783          	lw	a5,-64(s0)
    8000611e:	07e9                	addi	a5,a5,26
    80006120:	078e                	slli	a5,a5,0x3
    80006122:	94be                	add	s1,s1,a5
    80006124:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80006128:	fd043503          	ld	a0,-48(s0)
    8000612c:	fffff097          	auipc	ra,0xfffff
    80006130:	a04080e7          	jalr	-1532(ra) # 80004b30 <fileclose>
    fileclose(wf);
    80006134:	fc843503          	ld	a0,-56(s0)
    80006138:	fffff097          	auipc	ra,0xfffff
    8000613c:	9f8080e7          	jalr	-1544(ra) # 80004b30 <fileclose>
    return -1;
    80006140:	57fd                	li	a5,-1
    80006142:	a03d                	j	80006170 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80006144:	fc442783          	lw	a5,-60(s0)
    80006148:	0007c763          	bltz	a5,80006156 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    8000614c:	07e9                	addi	a5,a5,26
    8000614e:	078e                	slli	a5,a5,0x3
    80006150:	97a6                	add	a5,a5,s1
    80006152:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80006156:	fd043503          	ld	a0,-48(s0)
    8000615a:	fffff097          	auipc	ra,0xfffff
    8000615e:	9d6080e7          	jalr	-1578(ra) # 80004b30 <fileclose>
    fileclose(wf);
    80006162:	fc843503          	ld	a0,-56(s0)
    80006166:	fffff097          	auipc	ra,0xfffff
    8000616a:	9ca080e7          	jalr	-1590(ra) # 80004b30 <fileclose>
    return -1;
    8000616e:	57fd                	li	a5,-1
}
    80006170:	853e                	mv	a0,a5
    80006172:	70e2                	ld	ra,56(sp)
    80006174:	7442                	ld	s0,48(sp)
    80006176:	74a2                	ld	s1,40(sp)
    80006178:	6121                	addi	sp,sp,64
    8000617a:	8082                	ret
    8000617c:	0000                	unimp
	...

0000000080006180 <kernelvec>:
    80006180:	7111                	addi	sp,sp,-256
    80006182:	e006                	sd	ra,0(sp)
    80006184:	e40a                	sd	sp,8(sp)
    80006186:	e80e                	sd	gp,16(sp)
    80006188:	ec12                	sd	tp,24(sp)
    8000618a:	f016                	sd	t0,32(sp)
    8000618c:	f41a                	sd	t1,40(sp)
    8000618e:	f81e                	sd	t2,48(sp)
    80006190:	fc22                	sd	s0,56(sp)
    80006192:	e0a6                	sd	s1,64(sp)
    80006194:	e4aa                	sd	a0,72(sp)
    80006196:	e8ae                	sd	a1,80(sp)
    80006198:	ecb2                	sd	a2,88(sp)
    8000619a:	f0b6                	sd	a3,96(sp)
    8000619c:	f4ba                	sd	a4,104(sp)
    8000619e:	f8be                	sd	a5,112(sp)
    800061a0:	fcc2                	sd	a6,120(sp)
    800061a2:	e146                	sd	a7,128(sp)
    800061a4:	e54a                	sd	s2,136(sp)
    800061a6:	e94e                	sd	s3,144(sp)
    800061a8:	ed52                	sd	s4,152(sp)
    800061aa:	f156                	sd	s5,160(sp)
    800061ac:	f55a                	sd	s6,168(sp)
    800061ae:	f95e                	sd	s7,176(sp)
    800061b0:	fd62                	sd	s8,184(sp)
    800061b2:	e1e6                	sd	s9,192(sp)
    800061b4:	e5ea                	sd	s10,200(sp)
    800061b6:	e9ee                	sd	s11,208(sp)
    800061b8:	edf2                	sd	t3,216(sp)
    800061ba:	f1f6                	sd	t4,224(sp)
    800061bc:	f5fa                	sd	t5,232(sp)
    800061be:	f9fe                	sd	t6,240(sp)
    800061c0:	b39fc0ef          	jal	ra,80002cf8 <kerneltrap>
    800061c4:	6082                	ld	ra,0(sp)
    800061c6:	6122                	ld	sp,8(sp)
    800061c8:	61c2                	ld	gp,16(sp)
    800061ca:	7282                	ld	t0,32(sp)
    800061cc:	7322                	ld	t1,40(sp)
    800061ce:	73c2                	ld	t2,48(sp)
    800061d0:	7462                	ld	s0,56(sp)
    800061d2:	6486                	ld	s1,64(sp)
    800061d4:	6526                	ld	a0,72(sp)
    800061d6:	65c6                	ld	a1,80(sp)
    800061d8:	6666                	ld	a2,88(sp)
    800061da:	7686                	ld	a3,96(sp)
    800061dc:	7726                	ld	a4,104(sp)
    800061de:	77c6                	ld	a5,112(sp)
    800061e0:	7866                	ld	a6,120(sp)
    800061e2:	688a                	ld	a7,128(sp)
    800061e4:	692a                	ld	s2,136(sp)
    800061e6:	69ca                	ld	s3,144(sp)
    800061e8:	6a6a                	ld	s4,152(sp)
    800061ea:	7a8a                	ld	s5,160(sp)
    800061ec:	7b2a                	ld	s6,168(sp)
    800061ee:	7bca                	ld	s7,176(sp)
    800061f0:	7c6a                	ld	s8,184(sp)
    800061f2:	6c8e                	ld	s9,192(sp)
    800061f4:	6d2e                	ld	s10,200(sp)
    800061f6:	6dce                	ld	s11,208(sp)
    800061f8:	6e6e                	ld	t3,216(sp)
    800061fa:	7e8e                	ld	t4,224(sp)
    800061fc:	7f2e                	ld	t5,232(sp)
    800061fe:	7fce                	ld	t6,240(sp)
    80006200:	6111                	addi	sp,sp,256
    80006202:	10200073          	sret
    80006206:	00000013          	nop
    8000620a:	00000013          	nop
    8000620e:	0001                	nop

0000000080006210 <timervec>:
    80006210:	34051573          	csrrw	a0,mscratch,a0
    80006214:	e10c                	sd	a1,0(a0)
    80006216:	e510                	sd	a2,8(a0)
    80006218:	e914                	sd	a3,16(a0)
    8000621a:	6d0c                	ld	a1,24(a0)
    8000621c:	7110                	ld	a2,32(a0)
    8000621e:	6194                	ld	a3,0(a1)
    80006220:	96b2                	add	a3,a3,a2
    80006222:	e194                	sd	a3,0(a1)
    80006224:	4589                	li	a1,2
    80006226:	14459073          	csrw	sip,a1
    8000622a:	6914                	ld	a3,16(a0)
    8000622c:	6510                	ld	a2,8(a0)
    8000622e:	610c                	ld	a1,0(a0)
    80006230:	34051573          	csrrw	a0,mscratch,a0
    80006234:	30200073          	mret
	...

000000008000623a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000623a:	1141                	addi	sp,sp,-16
    8000623c:	e422                	sd	s0,8(sp)
    8000623e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006240:	0c0007b7          	lui	a5,0xc000
    80006244:	4705                	li	a4,1
    80006246:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006248:	c3d8                	sw	a4,4(a5)
}
    8000624a:	6422                	ld	s0,8(sp)
    8000624c:	0141                	addi	sp,sp,16
    8000624e:	8082                	ret

0000000080006250 <plicinithart>:

void
plicinithart(void)
{
    80006250:	1141                	addi	sp,sp,-16
    80006252:	e406                	sd	ra,8(sp)
    80006254:	e022                	sd	s0,0(sp)
    80006256:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006258:	ffffb097          	auipc	ra,0xffffb
    8000625c:	728080e7          	jalr	1832(ra) # 80001980 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006260:	0085171b          	slliw	a4,a0,0x8
    80006264:	0c0027b7          	lui	a5,0xc002
    80006268:	97ba                	add	a5,a5,a4
    8000626a:	40200713          	li	a4,1026
    8000626e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006272:	00d5151b          	slliw	a0,a0,0xd
    80006276:	0c2017b7          	lui	a5,0xc201
    8000627a:	97aa                	add	a5,a5,a0
    8000627c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80006280:	60a2                	ld	ra,8(sp)
    80006282:	6402                	ld	s0,0(sp)
    80006284:	0141                	addi	sp,sp,16
    80006286:	8082                	ret

0000000080006288 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006288:	1141                	addi	sp,sp,-16
    8000628a:	e406                	sd	ra,8(sp)
    8000628c:	e022                	sd	s0,0(sp)
    8000628e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006290:	ffffb097          	auipc	ra,0xffffb
    80006294:	6f0080e7          	jalr	1776(ra) # 80001980 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006298:	00d5151b          	slliw	a0,a0,0xd
    8000629c:	0c2017b7          	lui	a5,0xc201
    800062a0:	97aa                	add	a5,a5,a0
  return irq;
}
    800062a2:	43c8                	lw	a0,4(a5)
    800062a4:	60a2                	ld	ra,8(sp)
    800062a6:	6402                	ld	s0,0(sp)
    800062a8:	0141                	addi	sp,sp,16
    800062aa:	8082                	ret

00000000800062ac <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800062ac:	1101                	addi	sp,sp,-32
    800062ae:	ec06                	sd	ra,24(sp)
    800062b0:	e822                	sd	s0,16(sp)
    800062b2:	e426                	sd	s1,8(sp)
    800062b4:	1000                	addi	s0,sp,32
    800062b6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800062b8:	ffffb097          	auipc	ra,0xffffb
    800062bc:	6c8080e7          	jalr	1736(ra) # 80001980 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800062c0:	00d5151b          	slliw	a0,a0,0xd
    800062c4:	0c2017b7          	lui	a5,0xc201
    800062c8:	97aa                	add	a5,a5,a0
    800062ca:	c3c4                	sw	s1,4(a5)
}
    800062cc:	60e2                	ld	ra,24(sp)
    800062ce:	6442                	ld	s0,16(sp)
    800062d0:	64a2                	ld	s1,8(sp)
    800062d2:	6105                	addi	sp,sp,32
    800062d4:	8082                	ret

00000000800062d6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800062d6:	1141                	addi	sp,sp,-16
    800062d8:	e406                	sd	ra,8(sp)
    800062da:	e022                	sd	s0,0(sp)
    800062dc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800062de:	479d                	li	a5,7
    800062e0:	04a7cc63          	blt	a5,a0,80006338 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    800062e4:	0001d797          	auipc	a5,0x1d
    800062e8:	bbc78793          	addi	a5,a5,-1092 # 80022ea0 <disk>
    800062ec:	97aa                	add	a5,a5,a0
    800062ee:	0187c783          	lbu	a5,24(a5)
    800062f2:	ebb9                	bnez	a5,80006348 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800062f4:	00451693          	slli	a3,a0,0x4
    800062f8:	0001d797          	auipc	a5,0x1d
    800062fc:	ba878793          	addi	a5,a5,-1112 # 80022ea0 <disk>
    80006300:	6398                	ld	a4,0(a5)
    80006302:	9736                	add	a4,a4,a3
    80006304:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80006308:	6398                	ld	a4,0(a5)
    8000630a:	9736                	add	a4,a4,a3
    8000630c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006310:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006314:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80006318:	97aa                	add	a5,a5,a0
    8000631a:	4705                	li	a4,1
    8000631c:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80006320:	0001d517          	auipc	a0,0x1d
    80006324:	b9850513          	addi	a0,a0,-1128 # 80022eb8 <disk+0x18>
    80006328:	ffffc097          	auipc	ra,0xffffc
    8000632c:	0c2080e7          	jalr	194(ra) # 800023ea <wakeup>
}
    80006330:	60a2                	ld	ra,8(sp)
    80006332:	6402                	ld	s0,0(sp)
    80006334:	0141                	addi	sp,sp,16
    80006336:	8082                	ret
    panic("free_desc 1");
    80006338:	00002517          	auipc	a0,0x2
    8000633c:	62050513          	addi	a0,a0,1568 # 80008958 <systemCallsNames+0x300>
    80006340:	ffffa097          	auipc	ra,0xffffa
    80006344:	200080e7          	jalr	512(ra) # 80000540 <panic>
    panic("free_desc 2");
    80006348:	00002517          	auipc	a0,0x2
    8000634c:	62050513          	addi	a0,a0,1568 # 80008968 <systemCallsNames+0x310>
    80006350:	ffffa097          	auipc	ra,0xffffa
    80006354:	1f0080e7          	jalr	496(ra) # 80000540 <panic>

0000000080006358 <virtio_disk_init>:
{
    80006358:	1101                	addi	sp,sp,-32
    8000635a:	ec06                	sd	ra,24(sp)
    8000635c:	e822                	sd	s0,16(sp)
    8000635e:	e426                	sd	s1,8(sp)
    80006360:	e04a                	sd	s2,0(sp)
    80006362:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006364:	00002597          	auipc	a1,0x2
    80006368:	61458593          	addi	a1,a1,1556 # 80008978 <systemCallsNames+0x320>
    8000636c:	0001d517          	auipc	a0,0x1d
    80006370:	c5c50513          	addi	a0,a0,-932 # 80022fc8 <disk+0x128>
    80006374:	ffffa097          	auipc	ra,0xffffa
    80006378:	7d2080e7          	jalr	2002(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000637c:	100017b7          	lui	a5,0x10001
    80006380:	4398                	lw	a4,0(a5)
    80006382:	2701                	sext.w	a4,a4
    80006384:	747277b7          	lui	a5,0x74727
    80006388:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000638c:	14f71b63          	bne	a4,a5,800064e2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006390:	100017b7          	lui	a5,0x10001
    80006394:	43dc                	lw	a5,4(a5)
    80006396:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006398:	4709                	li	a4,2
    8000639a:	14e79463          	bne	a5,a4,800064e2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000639e:	100017b7          	lui	a5,0x10001
    800063a2:	479c                	lw	a5,8(a5)
    800063a4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800063a6:	12e79e63          	bne	a5,a4,800064e2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800063aa:	100017b7          	lui	a5,0x10001
    800063ae:	47d8                	lw	a4,12(a5)
    800063b0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800063b2:	554d47b7          	lui	a5,0x554d4
    800063b6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800063ba:	12f71463          	bne	a4,a5,800064e2 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    800063be:	100017b7          	lui	a5,0x10001
    800063c2:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    800063c6:	4705                	li	a4,1
    800063c8:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800063ca:	470d                	li	a4,3
    800063cc:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800063ce:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800063d0:	c7ffe6b7          	lui	a3,0xc7ffe
    800063d4:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fdb77f>
    800063d8:	8f75                	and	a4,a4,a3
    800063da:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800063dc:	472d                	li	a4,11
    800063de:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    800063e0:	5bbc                	lw	a5,112(a5)
    800063e2:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    800063e6:	8ba1                	andi	a5,a5,8
    800063e8:	10078563          	beqz	a5,800064f2 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800063ec:	100017b7          	lui	a5,0x10001
    800063f0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    800063f4:	43fc                	lw	a5,68(a5)
    800063f6:	2781                	sext.w	a5,a5
    800063f8:	10079563          	bnez	a5,80006502 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800063fc:	100017b7          	lui	a5,0x10001
    80006400:	5bdc                	lw	a5,52(a5)
    80006402:	2781                	sext.w	a5,a5
  if(max == 0)
    80006404:	10078763          	beqz	a5,80006512 <virtio_disk_init+0x1ba>
  if(max < NUM)
    80006408:	471d                	li	a4,7
    8000640a:	10f77c63          	bgeu	a4,a5,80006522 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    8000640e:	ffffa097          	auipc	ra,0xffffa
    80006412:	6d8080e7          	jalr	1752(ra) # 80000ae6 <kalloc>
    80006416:	0001d497          	auipc	s1,0x1d
    8000641a:	a8a48493          	addi	s1,s1,-1398 # 80022ea0 <disk>
    8000641e:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006420:	ffffa097          	auipc	ra,0xffffa
    80006424:	6c6080e7          	jalr	1734(ra) # 80000ae6 <kalloc>
    80006428:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000642a:	ffffa097          	auipc	ra,0xffffa
    8000642e:	6bc080e7          	jalr	1724(ra) # 80000ae6 <kalloc>
    80006432:	87aa                	mv	a5,a0
    80006434:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006436:	6088                	ld	a0,0(s1)
    80006438:	cd6d                	beqz	a0,80006532 <virtio_disk_init+0x1da>
    8000643a:	0001d717          	auipc	a4,0x1d
    8000643e:	a6e73703          	ld	a4,-1426(a4) # 80022ea8 <disk+0x8>
    80006442:	cb65                	beqz	a4,80006532 <virtio_disk_init+0x1da>
    80006444:	c7fd                	beqz	a5,80006532 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    80006446:	6605                	lui	a2,0x1
    80006448:	4581                	li	a1,0
    8000644a:	ffffb097          	auipc	ra,0xffffb
    8000644e:	888080e7          	jalr	-1912(ra) # 80000cd2 <memset>
  memset(disk.avail, 0, PGSIZE);
    80006452:	0001d497          	auipc	s1,0x1d
    80006456:	a4e48493          	addi	s1,s1,-1458 # 80022ea0 <disk>
    8000645a:	6605                	lui	a2,0x1
    8000645c:	4581                	li	a1,0
    8000645e:	6488                	ld	a0,8(s1)
    80006460:	ffffb097          	auipc	ra,0xffffb
    80006464:	872080e7          	jalr	-1934(ra) # 80000cd2 <memset>
  memset(disk.used, 0, PGSIZE);
    80006468:	6605                	lui	a2,0x1
    8000646a:	4581                	li	a1,0
    8000646c:	6888                	ld	a0,16(s1)
    8000646e:	ffffb097          	auipc	ra,0xffffb
    80006472:	864080e7          	jalr	-1948(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006476:	100017b7          	lui	a5,0x10001
    8000647a:	4721                	li	a4,8
    8000647c:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    8000647e:	4098                	lw	a4,0(s1)
    80006480:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006484:	40d8                	lw	a4,4(s1)
    80006486:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000648a:	6498                	ld	a4,8(s1)
    8000648c:	0007069b          	sext.w	a3,a4
    80006490:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006494:	9701                	srai	a4,a4,0x20
    80006496:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000649a:	6898                	ld	a4,16(s1)
    8000649c:	0007069b          	sext.w	a3,a4
    800064a0:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    800064a4:	9701                	srai	a4,a4,0x20
    800064a6:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    800064aa:	4705                	li	a4,1
    800064ac:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    800064ae:	00e48c23          	sb	a4,24(s1)
    800064b2:	00e48ca3          	sb	a4,25(s1)
    800064b6:	00e48d23          	sb	a4,26(s1)
    800064ba:	00e48da3          	sb	a4,27(s1)
    800064be:	00e48e23          	sb	a4,28(s1)
    800064c2:	00e48ea3          	sb	a4,29(s1)
    800064c6:	00e48f23          	sb	a4,30(s1)
    800064ca:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    800064ce:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    800064d2:	0727a823          	sw	s2,112(a5)
}
    800064d6:	60e2                	ld	ra,24(sp)
    800064d8:	6442                	ld	s0,16(sp)
    800064da:	64a2                	ld	s1,8(sp)
    800064dc:	6902                	ld	s2,0(sp)
    800064de:	6105                	addi	sp,sp,32
    800064e0:	8082                	ret
    panic("could not find virtio disk");
    800064e2:	00002517          	auipc	a0,0x2
    800064e6:	4a650513          	addi	a0,a0,1190 # 80008988 <systemCallsNames+0x330>
    800064ea:	ffffa097          	auipc	ra,0xffffa
    800064ee:	056080e7          	jalr	86(ra) # 80000540 <panic>
    panic("virtio disk FEATURES_OK unset");
    800064f2:	00002517          	auipc	a0,0x2
    800064f6:	4b650513          	addi	a0,a0,1206 # 800089a8 <systemCallsNames+0x350>
    800064fa:	ffffa097          	auipc	ra,0xffffa
    800064fe:	046080e7          	jalr	70(ra) # 80000540 <panic>
    panic("virtio disk should not be ready");
    80006502:	00002517          	auipc	a0,0x2
    80006506:	4c650513          	addi	a0,a0,1222 # 800089c8 <systemCallsNames+0x370>
    8000650a:	ffffa097          	auipc	ra,0xffffa
    8000650e:	036080e7          	jalr	54(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    80006512:	00002517          	auipc	a0,0x2
    80006516:	4d650513          	addi	a0,a0,1238 # 800089e8 <systemCallsNames+0x390>
    8000651a:	ffffa097          	auipc	ra,0xffffa
    8000651e:	026080e7          	jalr	38(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    80006522:	00002517          	auipc	a0,0x2
    80006526:	4e650513          	addi	a0,a0,1254 # 80008a08 <systemCallsNames+0x3b0>
    8000652a:	ffffa097          	auipc	ra,0xffffa
    8000652e:	016080e7          	jalr	22(ra) # 80000540 <panic>
    panic("virtio disk kalloc");
    80006532:	00002517          	auipc	a0,0x2
    80006536:	4f650513          	addi	a0,a0,1270 # 80008a28 <systemCallsNames+0x3d0>
    8000653a:	ffffa097          	auipc	ra,0xffffa
    8000653e:	006080e7          	jalr	6(ra) # 80000540 <panic>

0000000080006542 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006542:	7119                	addi	sp,sp,-128
    80006544:	fc86                	sd	ra,120(sp)
    80006546:	f8a2                	sd	s0,112(sp)
    80006548:	f4a6                	sd	s1,104(sp)
    8000654a:	f0ca                	sd	s2,96(sp)
    8000654c:	ecce                	sd	s3,88(sp)
    8000654e:	e8d2                	sd	s4,80(sp)
    80006550:	e4d6                	sd	s5,72(sp)
    80006552:	e0da                	sd	s6,64(sp)
    80006554:	fc5e                	sd	s7,56(sp)
    80006556:	f862                	sd	s8,48(sp)
    80006558:	f466                	sd	s9,40(sp)
    8000655a:	f06a                	sd	s10,32(sp)
    8000655c:	ec6e                	sd	s11,24(sp)
    8000655e:	0100                	addi	s0,sp,128
    80006560:	8aaa                	mv	s5,a0
    80006562:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006564:	00c52d03          	lw	s10,12(a0)
    80006568:	001d1d1b          	slliw	s10,s10,0x1
    8000656c:	1d02                	slli	s10,s10,0x20
    8000656e:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    80006572:	0001d517          	auipc	a0,0x1d
    80006576:	a5650513          	addi	a0,a0,-1450 # 80022fc8 <disk+0x128>
    8000657a:	ffffa097          	auipc	ra,0xffffa
    8000657e:	65c080e7          	jalr	1628(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    80006582:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006584:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006586:	0001db97          	auipc	s7,0x1d
    8000658a:	91ab8b93          	addi	s7,s7,-1766 # 80022ea0 <disk>
  for(int i = 0; i < 3; i++){
    8000658e:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006590:	0001dc97          	auipc	s9,0x1d
    80006594:	a38c8c93          	addi	s9,s9,-1480 # 80022fc8 <disk+0x128>
    80006598:	a08d                	j	800065fa <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    8000659a:	00fb8733          	add	a4,s7,a5
    8000659e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    800065a2:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    800065a4:	0207c563          	bltz	a5,800065ce <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    800065a8:	2905                	addiw	s2,s2,1
    800065aa:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    800065ac:	05690c63          	beq	s2,s6,80006604 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    800065b0:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    800065b2:	0001d717          	auipc	a4,0x1d
    800065b6:	8ee70713          	addi	a4,a4,-1810 # 80022ea0 <disk>
    800065ba:	87ce                	mv	a5,s3
    if(disk.free[i]){
    800065bc:	01874683          	lbu	a3,24(a4)
    800065c0:	fee9                	bnez	a3,8000659a <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    800065c2:	2785                	addiw	a5,a5,1
    800065c4:	0705                	addi	a4,a4,1
    800065c6:	fe979be3          	bne	a5,s1,800065bc <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    800065ca:	57fd                	li	a5,-1
    800065cc:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    800065ce:	01205d63          	blez	s2,800065e8 <virtio_disk_rw+0xa6>
    800065d2:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    800065d4:	000a2503          	lw	a0,0(s4)
    800065d8:	00000097          	auipc	ra,0x0
    800065dc:	cfe080e7          	jalr	-770(ra) # 800062d6 <free_desc>
      for(int j = 0; j < i; j++)
    800065e0:	2d85                	addiw	s11,s11,1
    800065e2:	0a11                	addi	s4,s4,4
    800065e4:	ff2d98e3          	bne	s11,s2,800065d4 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    800065e8:	85e6                	mv	a1,s9
    800065ea:	0001d517          	auipc	a0,0x1d
    800065ee:	8ce50513          	addi	a0,a0,-1842 # 80022eb8 <disk+0x18>
    800065f2:	ffffc097          	auipc	ra,0xffffc
    800065f6:	c48080e7          	jalr	-952(ra) # 8000223a <sleep>
  for(int i = 0; i < 3; i++){
    800065fa:	f8040a13          	addi	s4,s0,-128
{
    800065fe:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006600:	894e                	mv	s2,s3
    80006602:	b77d                	j	800065b0 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006604:	f8042503          	lw	a0,-128(s0)
    80006608:	00a50713          	addi	a4,a0,10
    8000660c:	0712                	slli	a4,a4,0x4

  if(write)
    8000660e:	0001d797          	auipc	a5,0x1d
    80006612:	89278793          	addi	a5,a5,-1902 # 80022ea0 <disk>
    80006616:	00e786b3          	add	a3,a5,a4
    8000661a:	01803633          	snez	a2,s8
    8000661e:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006620:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    80006624:	01a6b823          	sd	s10,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006628:	f6070613          	addi	a2,a4,-160
    8000662c:	6394                	ld	a3,0(a5)
    8000662e:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006630:	00870593          	addi	a1,a4,8
    80006634:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006636:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006638:	0007b803          	ld	a6,0(a5)
    8000663c:	9642                	add	a2,a2,a6
    8000663e:	46c1                	li	a3,16
    80006640:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006642:	4585                	li	a1,1
    80006644:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    80006648:	f8442683          	lw	a3,-124(s0)
    8000664c:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006650:	0692                	slli	a3,a3,0x4
    80006652:	9836                	add	a6,a6,a3
    80006654:	058a8613          	addi	a2,s5,88
    80006658:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    8000665c:	0007b803          	ld	a6,0(a5)
    80006660:	96c2                	add	a3,a3,a6
    80006662:	40000613          	li	a2,1024
    80006666:	c690                	sw	a2,8(a3)
  if(write)
    80006668:	001c3613          	seqz	a2,s8
    8000666c:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006670:	00166613          	ori	a2,a2,1
    80006674:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80006678:	f8842603          	lw	a2,-120(s0)
    8000667c:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006680:	00250693          	addi	a3,a0,2
    80006684:	0692                	slli	a3,a3,0x4
    80006686:	96be                	add	a3,a3,a5
    80006688:	58fd                	li	a7,-1
    8000668a:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000668e:	0612                	slli	a2,a2,0x4
    80006690:	9832                	add	a6,a6,a2
    80006692:	f9070713          	addi	a4,a4,-112
    80006696:	973e                	add	a4,a4,a5
    80006698:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    8000669c:	6398                	ld	a4,0(a5)
    8000669e:	9732                	add	a4,a4,a2
    800066a0:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800066a2:	4609                	li	a2,2
    800066a4:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    800066a8:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800066ac:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    800066b0:	0156b423          	sd	s5,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800066b4:	6794                	ld	a3,8(a5)
    800066b6:	0026d703          	lhu	a4,2(a3)
    800066ba:	8b1d                	andi	a4,a4,7
    800066bc:	0706                	slli	a4,a4,0x1
    800066be:	96ba                	add	a3,a3,a4
    800066c0:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    800066c4:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800066c8:	6798                	ld	a4,8(a5)
    800066ca:	00275783          	lhu	a5,2(a4)
    800066ce:	2785                	addiw	a5,a5,1
    800066d0:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800066d4:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800066d8:	100017b7          	lui	a5,0x10001
    800066dc:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800066e0:	004aa783          	lw	a5,4(s5)
    sleep(b, &disk.vdisk_lock);
    800066e4:	0001d917          	auipc	s2,0x1d
    800066e8:	8e490913          	addi	s2,s2,-1820 # 80022fc8 <disk+0x128>
  while(b->disk == 1) {
    800066ec:	4485                	li	s1,1
    800066ee:	00b79c63          	bne	a5,a1,80006706 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    800066f2:	85ca                	mv	a1,s2
    800066f4:	8556                	mv	a0,s5
    800066f6:	ffffc097          	auipc	ra,0xffffc
    800066fa:	b44080e7          	jalr	-1212(ra) # 8000223a <sleep>
  while(b->disk == 1) {
    800066fe:	004aa783          	lw	a5,4(s5)
    80006702:	fe9788e3          	beq	a5,s1,800066f2 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006706:	f8042903          	lw	s2,-128(s0)
    8000670a:	00290713          	addi	a4,s2,2
    8000670e:	0712                	slli	a4,a4,0x4
    80006710:	0001c797          	auipc	a5,0x1c
    80006714:	79078793          	addi	a5,a5,1936 # 80022ea0 <disk>
    80006718:	97ba                	add	a5,a5,a4
    8000671a:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000671e:	0001c997          	auipc	s3,0x1c
    80006722:	78298993          	addi	s3,s3,1922 # 80022ea0 <disk>
    80006726:	00491713          	slli	a4,s2,0x4
    8000672a:	0009b783          	ld	a5,0(s3)
    8000672e:	97ba                	add	a5,a5,a4
    80006730:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006734:	854a                	mv	a0,s2
    80006736:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000673a:	00000097          	auipc	ra,0x0
    8000673e:	b9c080e7          	jalr	-1124(ra) # 800062d6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006742:	8885                	andi	s1,s1,1
    80006744:	f0ed                	bnez	s1,80006726 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006746:	0001d517          	auipc	a0,0x1d
    8000674a:	88250513          	addi	a0,a0,-1918 # 80022fc8 <disk+0x128>
    8000674e:	ffffa097          	auipc	ra,0xffffa
    80006752:	53c080e7          	jalr	1340(ra) # 80000c8a <release>
}
    80006756:	70e6                	ld	ra,120(sp)
    80006758:	7446                	ld	s0,112(sp)
    8000675a:	74a6                	ld	s1,104(sp)
    8000675c:	7906                	ld	s2,96(sp)
    8000675e:	69e6                	ld	s3,88(sp)
    80006760:	6a46                	ld	s4,80(sp)
    80006762:	6aa6                	ld	s5,72(sp)
    80006764:	6b06                	ld	s6,64(sp)
    80006766:	7be2                	ld	s7,56(sp)
    80006768:	7c42                	ld	s8,48(sp)
    8000676a:	7ca2                	ld	s9,40(sp)
    8000676c:	7d02                	ld	s10,32(sp)
    8000676e:	6de2                	ld	s11,24(sp)
    80006770:	6109                	addi	sp,sp,128
    80006772:	8082                	ret

0000000080006774 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006774:	1101                	addi	sp,sp,-32
    80006776:	ec06                	sd	ra,24(sp)
    80006778:	e822                	sd	s0,16(sp)
    8000677a:	e426                	sd	s1,8(sp)
    8000677c:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000677e:	0001c497          	auipc	s1,0x1c
    80006782:	72248493          	addi	s1,s1,1826 # 80022ea0 <disk>
    80006786:	0001d517          	auipc	a0,0x1d
    8000678a:	84250513          	addi	a0,a0,-1982 # 80022fc8 <disk+0x128>
    8000678e:	ffffa097          	auipc	ra,0xffffa
    80006792:	448080e7          	jalr	1096(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006796:	10001737          	lui	a4,0x10001
    8000679a:	533c                	lw	a5,96(a4)
    8000679c:	8b8d                	andi	a5,a5,3
    8000679e:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800067a0:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800067a4:	689c                	ld	a5,16(s1)
    800067a6:	0204d703          	lhu	a4,32(s1)
    800067aa:	0027d783          	lhu	a5,2(a5)
    800067ae:	04f70863          	beq	a4,a5,800067fe <virtio_disk_intr+0x8a>
    __sync_synchronize();
    800067b2:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800067b6:	6898                	ld	a4,16(s1)
    800067b8:	0204d783          	lhu	a5,32(s1)
    800067bc:	8b9d                	andi	a5,a5,7
    800067be:	078e                	slli	a5,a5,0x3
    800067c0:	97ba                	add	a5,a5,a4
    800067c2:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800067c4:	00278713          	addi	a4,a5,2
    800067c8:	0712                	slli	a4,a4,0x4
    800067ca:	9726                	add	a4,a4,s1
    800067cc:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    800067d0:	e721                	bnez	a4,80006818 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800067d2:	0789                	addi	a5,a5,2
    800067d4:	0792                	slli	a5,a5,0x4
    800067d6:	97a6                	add	a5,a5,s1
    800067d8:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    800067da:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800067de:	ffffc097          	auipc	ra,0xffffc
    800067e2:	c0c080e7          	jalr	-1012(ra) # 800023ea <wakeup>

    disk.used_idx += 1;
    800067e6:	0204d783          	lhu	a5,32(s1)
    800067ea:	2785                	addiw	a5,a5,1
    800067ec:	17c2                	slli	a5,a5,0x30
    800067ee:	93c1                	srli	a5,a5,0x30
    800067f0:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800067f4:	6898                	ld	a4,16(s1)
    800067f6:	00275703          	lhu	a4,2(a4)
    800067fa:	faf71ce3          	bne	a4,a5,800067b2 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    800067fe:	0001c517          	auipc	a0,0x1c
    80006802:	7ca50513          	addi	a0,a0,1994 # 80022fc8 <disk+0x128>
    80006806:	ffffa097          	auipc	ra,0xffffa
    8000680a:	484080e7          	jalr	1156(ra) # 80000c8a <release>
}
    8000680e:	60e2                	ld	ra,24(sp)
    80006810:	6442                	ld	s0,16(sp)
    80006812:	64a2                	ld	s1,8(sp)
    80006814:	6105                	addi	sp,sp,32
    80006816:	8082                	ret
      panic("virtio_disk_intr status");
    80006818:	00002517          	auipc	a0,0x2
    8000681c:	22850513          	addi	a0,a0,552 # 80008a40 <systemCallsNames+0x3e8>
    80006820:	ffffa097          	auipc	ra,0xffffa
    80006824:	d20080e7          	jalr	-736(ra) # 80000540 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0)
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0)
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
