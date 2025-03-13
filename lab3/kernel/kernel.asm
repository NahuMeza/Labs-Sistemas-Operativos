
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	a1010113          	add	sp,sp,-1520 # 80008a10 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	add	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	074000ef          	jal	8000008a <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	add	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	add	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007861b          	sext.w	a2,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000; // cycles; about 1/10th second in qemu. //Quantum Modified
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	sllw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873703          	ld	a4,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	3e870713          	add	a4,a4,1000
    80000040:	e398                	sd	a4,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000042:	00261693          	sll	a3,a2,0x2
    80000046:	96b2                	add	a3,a3,a2
    80000048:	068e                	sll	a3,a3,0x3
    8000004a:	00009717          	auipc	a4,0x9
    8000004e:	88670713          	add	a4,a4,-1914 # 800088d0 <timer_scratch>
    80000052:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    80000054:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    80000056:	3e800793          	li	a5,1000
    8000005a:	f31c                	sd	a5,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    8000005c:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000060:	00006797          	auipc	a5,0x6
    80000064:	ae078793          	add	a5,a5,-1312 # 80005b40 <timervec>
    80000068:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000006c:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000070:	0087e793          	or	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000074:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    80000078:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    8000007c:	0807e793          	or	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000080:	30479073          	csrw	mie,a5
}
    80000084:	6422                	ld	s0,8(sp)
    80000086:	0141                	add	sp,sp,16
    80000088:	8082                	ret

000000008000008a <start>:
{
    8000008a:	1141                	add	sp,sp,-16
    8000008c:	e406                	sd	ra,8(sp)
    8000008e:	e022                	sd	s0,0(sp)
    80000090:	0800                	add	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000092:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000096:	7779                	lui	a4,0xffffe
    80000098:	7ff70713          	add	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdcabf>
    8000009c:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    8000009e:	6705                	lui	a4,0x1
    800000a0:	80070713          	add	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a4:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a6:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000aa:	00001797          	auipc	a5,0x1
    800000ae:	dc678793          	add	a5,a5,-570 # 80000e70 <main>
    800000b2:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b6:	4781                	li	a5,0
    800000b8:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000bc:	67c1                	lui	a5,0x10
    800000be:	17fd                	add	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000c0:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c4:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000c8:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000cc:	2227e793          	or	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d0:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d4:	57fd                	li	a5,-1
    800000d6:	83a9                	srl	a5,a5,0xa
    800000d8:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000dc:	47bd                	li	a5,15
    800000de:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e2:	00000097          	auipc	ra,0x0
    800000e6:	f3a080e7          	jalr	-198(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ea:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000ee:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f0:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f2:	30200073          	mret
}
    800000f6:	60a2                	ld	ra,8(sp)
    800000f8:	6402                	ld	s0,0(sp)
    800000fa:	0141                	add	sp,sp,16
    800000fc:	8082                	ret

00000000800000fe <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000fe:	715d                	add	sp,sp,-80
    80000100:	e486                	sd	ra,72(sp)
    80000102:	e0a2                	sd	s0,64(sp)
    80000104:	fc26                	sd	s1,56(sp)
    80000106:	f84a                	sd	s2,48(sp)
    80000108:	f44e                	sd	s3,40(sp)
    8000010a:	f052                	sd	s4,32(sp)
    8000010c:	ec56                	sd	s5,24(sp)
    8000010e:	0880                	add	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000110:	04c05763          	blez	a2,8000015e <consolewrite+0x60>
    80000114:	8a2a                	mv	s4,a0
    80000116:	84ae                	mv	s1,a1
    80000118:	89b2                	mv	s3,a2
    8000011a:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011c:	5afd                	li	s5,-1
    8000011e:	4685                	li	a3,1
    80000120:	8626                	mv	a2,s1
    80000122:	85d2                	mv	a1,s4
    80000124:	fbf40513          	add	a0,s0,-65
    80000128:	00002097          	auipc	ra,0x2
    8000012c:	382080e7          	jalr	898(ra) # 800024aa <either_copyin>
    80000130:	01550d63          	beq	a0,s5,8000014a <consolewrite+0x4c>
      break;
    uartputc(c);
    80000134:	fbf44503          	lbu	a0,-65(s0)
    80000138:	00000097          	auipc	ra,0x0
    8000013c:	780080e7          	jalr	1920(ra) # 800008b8 <uartputc>
  for(i = 0; i < n; i++){
    80000140:	2905                	addw	s2,s2,1
    80000142:	0485                	add	s1,s1,1
    80000144:	fd299de3          	bne	s3,s2,8000011e <consolewrite+0x20>
    80000148:	894e                	mv	s2,s3
  }

  return i;
}
    8000014a:	854a                	mv	a0,s2
    8000014c:	60a6                	ld	ra,72(sp)
    8000014e:	6406                	ld	s0,64(sp)
    80000150:	74e2                	ld	s1,56(sp)
    80000152:	7942                	ld	s2,48(sp)
    80000154:	79a2                	ld	s3,40(sp)
    80000156:	7a02                	ld	s4,32(sp)
    80000158:	6ae2                	ld	s5,24(sp)
    8000015a:	6161                	add	sp,sp,80
    8000015c:	8082                	ret
  for(i = 0; i < n; i++){
    8000015e:	4901                	li	s2,0
    80000160:	b7ed                	j	8000014a <consolewrite+0x4c>

0000000080000162 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000162:	711d                	add	sp,sp,-96
    80000164:	ec86                	sd	ra,88(sp)
    80000166:	e8a2                	sd	s0,80(sp)
    80000168:	e4a6                	sd	s1,72(sp)
    8000016a:	e0ca                	sd	s2,64(sp)
    8000016c:	fc4e                	sd	s3,56(sp)
    8000016e:	f852                	sd	s4,48(sp)
    80000170:	f456                	sd	s5,40(sp)
    80000172:	f05a                	sd	s6,32(sp)
    80000174:	ec5e                	sd	s7,24(sp)
    80000176:	1080                	add	s0,sp,96
    80000178:	8aaa                	mv	s5,a0
    8000017a:	8a2e                	mv	s4,a1
    8000017c:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    8000017e:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    80000182:	00011517          	auipc	a0,0x11
    80000186:	88e50513          	add	a0,a0,-1906 # 80010a10 <cons>
    8000018a:	00001097          	auipc	ra,0x1
    8000018e:	a46080e7          	jalr	-1466(ra) # 80000bd0 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    80000192:	00011497          	auipc	s1,0x11
    80000196:	87e48493          	add	s1,s1,-1922 # 80010a10 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    8000019a:	00011917          	auipc	s2,0x11
    8000019e:	90e90913          	add	s2,s2,-1778 # 80010aa8 <cons+0x98>
  while(n > 0){
    800001a2:	09305263          	blez	s3,80000226 <consoleread+0xc4>
    while(cons.r == cons.w){
    800001a6:	0984a783          	lw	a5,152(s1)
    800001aa:	09c4a703          	lw	a4,156(s1)
    800001ae:	02f71763          	bne	a4,a5,800001dc <consoleread+0x7a>
      if(killed(myproc())){
    800001b2:	00001097          	auipc	ra,0x1
    800001b6:	7f2080e7          	jalr	2034(ra) # 800019a4 <myproc>
    800001ba:	00002097          	auipc	ra,0x2
    800001be:	13a080e7          	jalr	314(ra) # 800022f4 <killed>
    800001c2:	ed2d                	bnez	a0,8000023c <consoleread+0xda>
      sleep(&cons.r, &cons.lock);
    800001c4:	85a6                	mv	a1,s1
    800001c6:	854a                	mv	a0,s2
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	e84080e7          	jalr	-380(ra) # 8000204c <sleep>
    while(cons.r == cons.w){
    800001d0:	0984a783          	lw	a5,152(s1)
    800001d4:	09c4a703          	lw	a4,156(s1)
    800001d8:	fcf70de3          	beq	a4,a5,800001b2 <consoleread+0x50>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001dc:	00011717          	auipc	a4,0x11
    800001e0:	83470713          	add	a4,a4,-1996 # 80010a10 <cons>
    800001e4:	0017869b          	addw	a3,a5,1
    800001e8:	08d72c23          	sw	a3,152(a4)
    800001ec:	07f7f693          	and	a3,a5,127
    800001f0:	9736                	add	a4,a4,a3
    800001f2:	01874703          	lbu	a4,24(a4)
    800001f6:	00070b9b          	sext.w	s7,a4

    if(c == C('D')){  // end-of-file
    800001fa:	4691                	li	a3,4
    800001fc:	06db8463          	beq	s7,a3,80000264 <consoleread+0x102>
      }
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    80000200:	fae407a3          	sb	a4,-81(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000204:	4685                	li	a3,1
    80000206:	faf40613          	add	a2,s0,-81
    8000020a:	85d2                	mv	a1,s4
    8000020c:	8556                	mv	a0,s5
    8000020e:	00002097          	auipc	ra,0x2
    80000212:	246080e7          	jalr	582(ra) # 80002454 <either_copyout>
    80000216:	57fd                	li	a5,-1
    80000218:	00f50763          	beq	a0,a5,80000226 <consoleread+0xc4>
      break;

    dst++;
    8000021c:	0a05                	add	s4,s4,1
    --n;
    8000021e:	39fd                	addw	s3,s3,-1

    if(c == '\n'){
    80000220:	47a9                	li	a5,10
    80000222:	f8fb90e3          	bne	s7,a5,800001a2 <consoleread+0x40>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000226:	00010517          	auipc	a0,0x10
    8000022a:	7ea50513          	add	a0,a0,2026 # 80010a10 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	a56080e7          	jalr	-1450(ra) # 80000c84 <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xec>
        release(&cons.lock);
    8000023c:	00010517          	auipc	a0,0x10
    80000240:	7d450513          	add	a0,a0,2004 # 80010a10 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	a40080e7          	jalr	-1472(ra) # 80000c84 <release>
        return -1;
    8000024c:	557d                	li	a0,-1
}
    8000024e:	60e6                	ld	ra,88(sp)
    80000250:	6446                	ld	s0,80(sp)
    80000252:	64a6                	ld	s1,72(sp)
    80000254:	6906                	ld	s2,64(sp)
    80000256:	79e2                	ld	s3,56(sp)
    80000258:	7a42                	ld	s4,48(sp)
    8000025a:	7aa2                	ld	s5,40(sp)
    8000025c:	7b02                	ld	s6,32(sp)
    8000025e:	6be2                	ld	s7,24(sp)
    80000260:	6125                	add	sp,sp,96
    80000262:	8082                	ret
      if(n < target){
    80000264:	0009871b          	sext.w	a4,s3
    80000268:	fb677fe3          	bgeu	a4,s6,80000226 <consoleread+0xc4>
        cons.r--;
    8000026c:	00011717          	auipc	a4,0x11
    80000270:	82f72e23          	sw	a5,-1988(a4) # 80010aa8 <cons+0x98>
    80000274:	bf4d                	j	80000226 <consoleread+0xc4>

0000000080000276 <consputc>:
{
    80000276:	1141                	add	sp,sp,-16
    80000278:	e406                	sd	ra,8(sp)
    8000027a:	e022                	sd	s0,0(sp)
    8000027c:	0800                	add	s0,sp,16
  if(c == BACKSPACE){
    8000027e:	10000793          	li	a5,256
    80000282:	00f50a63          	beq	a0,a5,80000296 <consputc+0x20>
    uartputc_sync(c);
    80000286:	00000097          	auipc	ra,0x0
    8000028a:	560080e7          	jalr	1376(ra) # 800007e6 <uartputc_sync>
}
    8000028e:	60a2                	ld	ra,8(sp)
    80000290:	6402                	ld	s0,0(sp)
    80000292:	0141                	add	sp,sp,16
    80000294:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    80000296:	4521                	li	a0,8
    80000298:	00000097          	auipc	ra,0x0
    8000029c:	54e080e7          	jalr	1358(ra) # 800007e6 <uartputc_sync>
    800002a0:	02000513          	li	a0,32
    800002a4:	00000097          	auipc	ra,0x0
    800002a8:	542080e7          	jalr	1346(ra) # 800007e6 <uartputc_sync>
    800002ac:	4521                	li	a0,8
    800002ae:	00000097          	auipc	ra,0x0
    800002b2:	538080e7          	jalr	1336(ra) # 800007e6 <uartputc_sync>
    800002b6:	bfe1                	j	8000028e <consputc+0x18>

00000000800002b8 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002b8:	1101                	add	sp,sp,-32
    800002ba:	ec06                	sd	ra,24(sp)
    800002bc:	e822                	sd	s0,16(sp)
    800002be:	e426                	sd	s1,8(sp)
    800002c0:	e04a                	sd	s2,0(sp)
    800002c2:	1000                	add	s0,sp,32
    800002c4:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002c6:	00010517          	auipc	a0,0x10
    800002ca:	74a50513          	add	a0,a0,1866 # 80010a10 <cons>
    800002ce:	00001097          	auipc	ra,0x1
    800002d2:	902080e7          	jalr	-1790(ra) # 80000bd0 <acquire>

  switch(c){
    800002d6:	47d5                	li	a5,21
    800002d8:	0af48663          	beq	s1,a5,80000384 <consoleintr+0xcc>
    800002dc:	0297ca63          	blt	a5,s1,80000310 <consoleintr+0x58>
    800002e0:	47a1                	li	a5,8
    800002e2:	0ef48763          	beq	s1,a5,800003d0 <consoleintr+0x118>
    800002e6:	47c1                	li	a5,16
    800002e8:	10f49a63          	bne	s1,a5,800003fc <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002ec:	00002097          	auipc	ra,0x2
    800002f0:	214080e7          	jalr	532(ra) # 80002500 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002f4:	00010517          	auipc	a0,0x10
    800002f8:	71c50513          	add	a0,a0,1820 # 80010a10 <cons>
    800002fc:	00001097          	auipc	ra,0x1
    80000300:	988080e7          	jalr	-1656(ra) # 80000c84 <release>
}
    80000304:	60e2                	ld	ra,24(sp)
    80000306:	6442                	ld	s0,16(sp)
    80000308:	64a2                	ld	s1,8(sp)
    8000030a:	6902                	ld	s2,0(sp)
    8000030c:	6105                	add	sp,sp,32
    8000030e:	8082                	ret
  switch(c){
    80000310:	07f00793          	li	a5,127
    80000314:	0af48e63          	beq	s1,a5,800003d0 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000318:	00010717          	auipc	a4,0x10
    8000031c:	6f870713          	add	a4,a4,1784 # 80010a10 <cons>
    80000320:	0a072783          	lw	a5,160(a4)
    80000324:	09872703          	lw	a4,152(a4)
    80000328:	9f99                	subw	a5,a5,a4
    8000032a:	07f00713          	li	a4,127
    8000032e:	fcf763e3          	bltu	a4,a5,800002f4 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000332:	47b5                	li	a5,13
    80000334:	0cf48763          	beq	s1,a5,80000402 <consoleintr+0x14a>
      consputc(c);
    80000338:	8526                	mv	a0,s1
    8000033a:	00000097          	auipc	ra,0x0
    8000033e:	f3c080e7          	jalr	-196(ra) # 80000276 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000342:	00010797          	auipc	a5,0x10
    80000346:	6ce78793          	add	a5,a5,1742 # 80010a10 <cons>
    8000034a:	0a07a683          	lw	a3,160(a5)
    8000034e:	0016871b          	addw	a4,a3,1
    80000352:	0007061b          	sext.w	a2,a4
    80000356:	0ae7a023          	sw	a4,160(a5)
    8000035a:	07f6f693          	and	a3,a3,127
    8000035e:	97b6                	add	a5,a5,a3
    80000360:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    80000364:	47a9                	li	a5,10
    80000366:	0cf48563          	beq	s1,a5,80000430 <consoleintr+0x178>
    8000036a:	4791                	li	a5,4
    8000036c:	0cf48263          	beq	s1,a5,80000430 <consoleintr+0x178>
    80000370:	00010797          	auipc	a5,0x10
    80000374:	7387a783          	lw	a5,1848(a5) # 80010aa8 <cons+0x98>
    80000378:	9f1d                	subw	a4,a4,a5
    8000037a:	08000793          	li	a5,128
    8000037e:	f6f71be3          	bne	a4,a5,800002f4 <consoleintr+0x3c>
    80000382:	a07d                	j	80000430 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000384:	00010717          	auipc	a4,0x10
    80000388:	68c70713          	add	a4,a4,1676 # 80010a10 <cons>
    8000038c:	0a072783          	lw	a5,160(a4)
    80000390:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    80000394:	00010497          	auipc	s1,0x10
    80000398:	67c48493          	add	s1,s1,1660 # 80010a10 <cons>
    while(cons.e != cons.w &&
    8000039c:	4929                	li	s2,10
    8000039e:	f4f70be3          	beq	a4,a5,800002f4 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a2:	37fd                	addw	a5,a5,-1
    800003a4:	07f7f713          	and	a4,a5,127
    800003a8:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003aa:	01874703          	lbu	a4,24(a4)
    800003ae:	f52703e3          	beq	a4,s2,800002f4 <consoleintr+0x3c>
      cons.e--;
    800003b2:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003b6:	10000513          	li	a0,256
    800003ba:	00000097          	auipc	ra,0x0
    800003be:	ebc080e7          	jalr	-324(ra) # 80000276 <consputc>
    while(cons.e != cons.w &&
    800003c2:	0a04a783          	lw	a5,160(s1)
    800003c6:	09c4a703          	lw	a4,156(s1)
    800003ca:	fcf71ce3          	bne	a4,a5,800003a2 <consoleintr+0xea>
    800003ce:	b71d                	j	800002f4 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d0:	00010717          	auipc	a4,0x10
    800003d4:	64070713          	add	a4,a4,1600 # 80010a10 <cons>
    800003d8:	0a072783          	lw	a5,160(a4)
    800003dc:	09c72703          	lw	a4,156(a4)
    800003e0:	f0f70ae3          	beq	a4,a5,800002f4 <consoleintr+0x3c>
      cons.e--;
    800003e4:	37fd                	addw	a5,a5,-1
    800003e6:	00010717          	auipc	a4,0x10
    800003ea:	6cf72523          	sw	a5,1738(a4) # 80010ab0 <cons+0xa0>
      consputc(BACKSPACE);
    800003ee:	10000513          	li	a0,256
    800003f2:	00000097          	auipc	ra,0x0
    800003f6:	e84080e7          	jalr	-380(ra) # 80000276 <consputc>
    800003fa:	bded                	j	800002f4 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    800003fc:	ee048ce3          	beqz	s1,800002f4 <consoleintr+0x3c>
    80000400:	bf21                	j	80000318 <consoleintr+0x60>
      consputc(c);
    80000402:	4529                	li	a0,10
    80000404:	00000097          	auipc	ra,0x0
    80000408:	e72080e7          	jalr	-398(ra) # 80000276 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    8000040c:	00010797          	auipc	a5,0x10
    80000410:	60478793          	add	a5,a5,1540 # 80010a10 <cons>
    80000414:	0a07a703          	lw	a4,160(a5)
    80000418:	0017069b          	addw	a3,a4,1
    8000041c:	0006861b          	sext.w	a2,a3
    80000420:	0ad7a023          	sw	a3,160(a5)
    80000424:	07f77713          	and	a4,a4,127
    80000428:	97ba                	add	a5,a5,a4
    8000042a:	4729                	li	a4,10
    8000042c:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000430:	00010797          	auipc	a5,0x10
    80000434:	66c7ae23          	sw	a2,1660(a5) # 80010aac <cons+0x9c>
        wakeup(&cons.r);
    80000438:	00010517          	auipc	a0,0x10
    8000043c:	67050513          	add	a0,a0,1648 # 80010aa8 <cons+0x98>
    80000440:	00002097          	auipc	ra,0x2
    80000444:	c70080e7          	jalr	-912(ra) # 800020b0 <wakeup>
    80000448:	b575                	j	800002f4 <consoleintr+0x3c>

000000008000044a <consoleinit>:

void
consoleinit(void)
{
    8000044a:	1141                	add	sp,sp,-16
    8000044c:	e406                	sd	ra,8(sp)
    8000044e:	e022                	sd	s0,0(sp)
    80000450:	0800                	add	s0,sp,16
  initlock(&cons.lock, "cons");
    80000452:	00008597          	auipc	a1,0x8
    80000456:	bbe58593          	add	a1,a1,-1090 # 80008010 <etext+0x10>
    8000045a:	00010517          	auipc	a0,0x10
    8000045e:	5b650513          	add	a0,a0,1462 # 80010a10 <cons>
    80000462:	00000097          	auipc	ra,0x0
    80000466:	6de080e7          	jalr	1758(ra) # 80000b40 <initlock>

  uartinit();
    8000046a:	00000097          	auipc	ra,0x0
    8000046e:	32c080e7          	jalr	812(ra) # 80000796 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000472:	00020797          	auipc	a5,0x20
    80000476:	73678793          	add	a5,a5,1846 # 80020ba8 <devsw>
    8000047a:	00000717          	auipc	a4,0x0
    8000047e:	ce870713          	add	a4,a4,-792 # 80000162 <consoleread>
    80000482:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000484:	00000717          	auipc	a4,0x0
    80000488:	c7a70713          	add	a4,a4,-902 # 800000fe <consolewrite>
    8000048c:	ef98                	sd	a4,24(a5)
}
    8000048e:	60a2                	ld	ra,8(sp)
    80000490:	6402                	ld	s0,0(sp)
    80000492:	0141                	add	sp,sp,16
    80000494:	8082                	ret

0000000080000496 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    80000496:	7179                	add	sp,sp,-48
    80000498:	f406                	sd	ra,40(sp)
    8000049a:	f022                	sd	s0,32(sp)
    8000049c:	ec26                	sd	s1,24(sp)
    8000049e:	e84a                	sd	s2,16(sp)
    800004a0:	1800                	add	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a2:	c219                	beqz	a2,800004a8 <printint+0x12>
    800004a4:	08054763          	bltz	a0,80000532 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    800004a8:	2501                	sext.w	a0,a0
    800004aa:	4881                	li	a7,0
    800004ac:	fd040693          	add	a3,s0,-48

  i = 0;
    800004b0:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b2:	2581                	sext.w	a1,a1
    800004b4:	00008617          	auipc	a2,0x8
    800004b8:	b8c60613          	add	a2,a2,-1140 # 80008040 <digits>
    800004bc:	883a                	mv	a6,a4
    800004be:	2705                	addw	a4,a4,1
    800004c0:	02b577bb          	remuw	a5,a0,a1
    800004c4:	1782                	sll	a5,a5,0x20
    800004c6:	9381                	srl	a5,a5,0x20
    800004c8:	97b2                	add	a5,a5,a2
    800004ca:	0007c783          	lbu	a5,0(a5)
    800004ce:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d2:	0005079b          	sext.w	a5,a0
    800004d6:	02b5553b          	divuw	a0,a0,a1
    800004da:	0685                	add	a3,a3,1
    800004dc:	feb7f0e3          	bgeu	a5,a1,800004bc <printint+0x26>

  if(sign)
    800004e0:	00088c63          	beqz	a7,800004f8 <printint+0x62>
    buf[i++] = '-';
    800004e4:	fe070793          	add	a5,a4,-32
    800004e8:	00878733          	add	a4,a5,s0
    800004ec:	02d00793          	li	a5,45
    800004f0:	fef70823          	sb	a5,-16(a4)
    800004f4:	0028071b          	addw	a4,a6,2

  while(--i >= 0)
    800004f8:	02e05763          	blez	a4,80000526 <printint+0x90>
    800004fc:	fd040793          	add	a5,s0,-48
    80000500:	00e784b3          	add	s1,a5,a4
    80000504:	fff78913          	add	s2,a5,-1
    80000508:	993a                	add	s2,s2,a4
    8000050a:	377d                	addw	a4,a4,-1
    8000050c:	1702                	sll	a4,a4,0x20
    8000050e:	9301                	srl	a4,a4,0x20
    80000510:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000514:	fff4c503          	lbu	a0,-1(s1)
    80000518:	00000097          	auipc	ra,0x0
    8000051c:	d5e080e7          	jalr	-674(ra) # 80000276 <consputc>
  while(--i >= 0)
    80000520:	14fd                	add	s1,s1,-1
    80000522:	ff2499e3          	bne	s1,s2,80000514 <printint+0x7e>
}
    80000526:	70a2                	ld	ra,40(sp)
    80000528:	7402                	ld	s0,32(sp)
    8000052a:	64e2                	ld	s1,24(sp)
    8000052c:	6942                	ld	s2,16(sp)
    8000052e:	6145                	add	sp,sp,48
    80000530:	8082                	ret
    x = -xx;
    80000532:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000536:	4885                	li	a7,1
    x = -xx;
    80000538:	bf95                	j	800004ac <printint+0x16>

000000008000053a <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053a:	1101                	add	sp,sp,-32
    8000053c:	ec06                	sd	ra,24(sp)
    8000053e:	e822                	sd	s0,16(sp)
    80000540:	e426                	sd	s1,8(sp)
    80000542:	1000                	add	s0,sp,32
    80000544:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000546:	00010797          	auipc	a5,0x10
    8000054a:	5807a523          	sw	zero,1418(a5) # 80010ad0 <pr+0x18>
  printf("panic: ");
    8000054e:	00008517          	auipc	a0,0x8
    80000552:	aca50513          	add	a0,a0,-1334 # 80008018 <etext+0x18>
    80000556:	00000097          	auipc	ra,0x0
    8000055a:	02e080e7          	jalr	46(ra) # 80000584 <printf>
  printf(s);
    8000055e:	8526                	mv	a0,s1
    80000560:	00000097          	auipc	ra,0x0
    80000564:	024080e7          	jalr	36(ra) # 80000584 <printf>
  printf("\n");
    80000568:	00008517          	auipc	a0,0x8
    8000056c:	b6050513          	add	a0,a0,-1184 # 800080c8 <digits+0x88>
    80000570:	00000097          	auipc	ra,0x0
    80000574:	014080e7          	jalr	20(ra) # 80000584 <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000578:	4785                	li	a5,1
    8000057a:	00008717          	auipc	a4,0x8
    8000057e:	30f72b23          	sw	a5,790(a4) # 80008890 <panicked>
  for(;;)
    80000582:	a001                	j	80000582 <panic+0x48>

0000000080000584 <printf>:
{
    80000584:	7131                	add	sp,sp,-192
    80000586:	fc86                	sd	ra,120(sp)
    80000588:	f8a2                	sd	s0,112(sp)
    8000058a:	f4a6                	sd	s1,104(sp)
    8000058c:	f0ca                	sd	s2,96(sp)
    8000058e:	ecce                	sd	s3,88(sp)
    80000590:	e8d2                	sd	s4,80(sp)
    80000592:	e4d6                	sd	s5,72(sp)
    80000594:	e0da                	sd	s6,64(sp)
    80000596:	fc5e                	sd	s7,56(sp)
    80000598:	f862                	sd	s8,48(sp)
    8000059a:	f466                	sd	s9,40(sp)
    8000059c:	f06a                	sd	s10,32(sp)
    8000059e:	ec6e                	sd	s11,24(sp)
    800005a0:	0100                	add	s0,sp,128
    800005a2:	8a2a                	mv	s4,a0
    800005a4:	e40c                	sd	a1,8(s0)
    800005a6:	e810                	sd	a2,16(s0)
    800005a8:	ec14                	sd	a3,24(s0)
    800005aa:	f018                	sd	a4,32(s0)
    800005ac:	f41c                	sd	a5,40(s0)
    800005ae:	03043823          	sd	a6,48(s0)
    800005b2:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005b6:	00010d97          	auipc	s11,0x10
    800005ba:	51adad83          	lw	s11,1306(s11) # 80010ad0 <pr+0x18>
  if(locking)
    800005be:	020d9b63          	bnez	s11,800005f4 <printf+0x70>
  if (fmt == 0)
    800005c2:	040a0263          	beqz	s4,80000606 <printf+0x82>
  va_start(ap, fmt);
    800005c6:	00840793          	add	a5,s0,8
    800005ca:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005ce:	000a4503          	lbu	a0,0(s4)
    800005d2:	14050f63          	beqz	a0,80000730 <printf+0x1ac>
    800005d6:	4981                	li	s3,0
    if(c != '%'){
    800005d8:	02500a93          	li	s5,37
    switch(c){
    800005dc:	07000b93          	li	s7,112
  consputc('x');
    800005e0:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e2:	00008b17          	auipc	s6,0x8
    800005e6:	a5eb0b13          	add	s6,s6,-1442 # 80008040 <digits>
    switch(c){
    800005ea:	07300c93          	li	s9,115
    800005ee:	06400c13          	li	s8,100
    800005f2:	a82d                	j	8000062c <printf+0xa8>
    acquire(&pr.lock);
    800005f4:	00010517          	auipc	a0,0x10
    800005f8:	4c450513          	add	a0,a0,1220 # 80010ab8 <pr>
    800005fc:	00000097          	auipc	ra,0x0
    80000600:	5d4080e7          	jalr	1492(ra) # 80000bd0 <acquire>
    80000604:	bf7d                	j	800005c2 <printf+0x3e>
    panic("null fmt");
    80000606:	00008517          	auipc	a0,0x8
    8000060a:	a2250513          	add	a0,a0,-1502 # 80008028 <etext+0x28>
    8000060e:	00000097          	auipc	ra,0x0
    80000612:	f2c080e7          	jalr	-212(ra) # 8000053a <panic>
      consputc(c);
    80000616:	00000097          	auipc	ra,0x0
    8000061a:	c60080e7          	jalr	-928(ra) # 80000276 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    8000061e:	2985                	addw	s3,s3,1
    80000620:	013a07b3          	add	a5,s4,s3
    80000624:	0007c503          	lbu	a0,0(a5)
    80000628:	10050463          	beqz	a0,80000730 <printf+0x1ac>
    if(c != '%'){
    8000062c:	ff5515e3          	bne	a0,s5,80000616 <printf+0x92>
    c = fmt[++i] & 0xff;
    80000630:	2985                	addw	s3,s3,1
    80000632:	013a07b3          	add	a5,s4,s3
    80000636:	0007c783          	lbu	a5,0(a5)
    8000063a:	0007849b          	sext.w	s1,a5
    if(c == 0)
    8000063e:	cbed                	beqz	a5,80000730 <printf+0x1ac>
    switch(c){
    80000640:	05778a63          	beq	a5,s7,80000694 <printf+0x110>
    80000644:	02fbf663          	bgeu	s7,a5,80000670 <printf+0xec>
    80000648:	09978863          	beq	a5,s9,800006d8 <printf+0x154>
    8000064c:	07800713          	li	a4,120
    80000650:	0ce79563          	bne	a5,a4,8000071a <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000654:	f8843783          	ld	a5,-120(s0)
    80000658:	00878713          	add	a4,a5,8
    8000065c:	f8e43423          	sd	a4,-120(s0)
    80000660:	4605                	li	a2,1
    80000662:	85ea                	mv	a1,s10
    80000664:	4388                	lw	a0,0(a5)
    80000666:	00000097          	auipc	ra,0x0
    8000066a:	e30080e7          	jalr	-464(ra) # 80000496 <printint>
      break;
    8000066e:	bf45                	j	8000061e <printf+0x9a>
    switch(c){
    80000670:	09578f63          	beq	a5,s5,8000070e <printf+0x18a>
    80000674:	0b879363          	bne	a5,s8,8000071a <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    80000678:	f8843783          	ld	a5,-120(s0)
    8000067c:	00878713          	add	a4,a5,8
    80000680:	f8e43423          	sd	a4,-120(s0)
    80000684:	4605                	li	a2,1
    80000686:	45a9                	li	a1,10
    80000688:	4388                	lw	a0,0(a5)
    8000068a:	00000097          	auipc	ra,0x0
    8000068e:	e0c080e7          	jalr	-500(ra) # 80000496 <printint>
      break;
    80000692:	b771                	j	8000061e <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000694:	f8843783          	ld	a5,-120(s0)
    80000698:	00878713          	add	a4,a5,8
    8000069c:	f8e43423          	sd	a4,-120(s0)
    800006a0:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006a4:	03000513          	li	a0,48
    800006a8:	00000097          	auipc	ra,0x0
    800006ac:	bce080e7          	jalr	-1074(ra) # 80000276 <consputc>
  consputc('x');
    800006b0:	07800513          	li	a0,120
    800006b4:	00000097          	auipc	ra,0x0
    800006b8:	bc2080e7          	jalr	-1086(ra) # 80000276 <consputc>
    800006bc:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006be:	03c95793          	srl	a5,s2,0x3c
    800006c2:	97da                	add	a5,a5,s6
    800006c4:	0007c503          	lbu	a0,0(a5)
    800006c8:	00000097          	auipc	ra,0x0
    800006cc:	bae080e7          	jalr	-1106(ra) # 80000276 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d0:	0912                	sll	s2,s2,0x4
    800006d2:	34fd                	addw	s1,s1,-1
    800006d4:	f4ed                	bnez	s1,800006be <printf+0x13a>
    800006d6:	b7a1                	j	8000061e <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006d8:	f8843783          	ld	a5,-120(s0)
    800006dc:	00878713          	add	a4,a5,8
    800006e0:	f8e43423          	sd	a4,-120(s0)
    800006e4:	6384                	ld	s1,0(a5)
    800006e6:	cc89                	beqz	s1,80000700 <printf+0x17c>
      for(; *s; s++)
    800006e8:	0004c503          	lbu	a0,0(s1)
    800006ec:	d90d                	beqz	a0,8000061e <printf+0x9a>
        consputc(*s);
    800006ee:	00000097          	auipc	ra,0x0
    800006f2:	b88080e7          	jalr	-1144(ra) # 80000276 <consputc>
      for(; *s; s++)
    800006f6:	0485                	add	s1,s1,1
    800006f8:	0004c503          	lbu	a0,0(s1)
    800006fc:	f96d                	bnez	a0,800006ee <printf+0x16a>
    800006fe:	b705                	j	8000061e <printf+0x9a>
        s = "(null)";
    80000700:	00008497          	auipc	s1,0x8
    80000704:	92048493          	add	s1,s1,-1760 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000708:	02800513          	li	a0,40
    8000070c:	b7cd                	j	800006ee <printf+0x16a>
      consputc('%');
    8000070e:	8556                	mv	a0,s5
    80000710:	00000097          	auipc	ra,0x0
    80000714:	b66080e7          	jalr	-1178(ra) # 80000276 <consputc>
      break;
    80000718:	b719                	j	8000061e <printf+0x9a>
      consputc('%');
    8000071a:	8556                	mv	a0,s5
    8000071c:	00000097          	auipc	ra,0x0
    80000720:	b5a080e7          	jalr	-1190(ra) # 80000276 <consputc>
      consputc(c);
    80000724:	8526                	mv	a0,s1
    80000726:	00000097          	auipc	ra,0x0
    8000072a:	b50080e7          	jalr	-1200(ra) # 80000276 <consputc>
      break;
    8000072e:	bdc5                	j	8000061e <printf+0x9a>
  if(locking)
    80000730:	020d9163          	bnez	s11,80000752 <printf+0x1ce>
}
    80000734:	70e6                	ld	ra,120(sp)
    80000736:	7446                	ld	s0,112(sp)
    80000738:	74a6                	ld	s1,104(sp)
    8000073a:	7906                	ld	s2,96(sp)
    8000073c:	69e6                	ld	s3,88(sp)
    8000073e:	6a46                	ld	s4,80(sp)
    80000740:	6aa6                	ld	s5,72(sp)
    80000742:	6b06                	ld	s6,64(sp)
    80000744:	7be2                	ld	s7,56(sp)
    80000746:	7c42                	ld	s8,48(sp)
    80000748:	7ca2                	ld	s9,40(sp)
    8000074a:	7d02                	ld	s10,32(sp)
    8000074c:	6de2                	ld	s11,24(sp)
    8000074e:	6129                	add	sp,sp,192
    80000750:	8082                	ret
    release(&pr.lock);
    80000752:	00010517          	auipc	a0,0x10
    80000756:	36650513          	add	a0,a0,870 # 80010ab8 <pr>
    8000075a:	00000097          	auipc	ra,0x0
    8000075e:	52a080e7          	jalr	1322(ra) # 80000c84 <release>
}
    80000762:	bfc9                	j	80000734 <printf+0x1b0>

0000000080000764 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000764:	1101                	add	sp,sp,-32
    80000766:	ec06                	sd	ra,24(sp)
    80000768:	e822                	sd	s0,16(sp)
    8000076a:	e426                	sd	s1,8(sp)
    8000076c:	1000                	add	s0,sp,32
  initlock(&pr.lock, "pr");
    8000076e:	00010497          	auipc	s1,0x10
    80000772:	34a48493          	add	s1,s1,842 # 80010ab8 <pr>
    80000776:	00008597          	auipc	a1,0x8
    8000077a:	8c258593          	add	a1,a1,-1854 # 80008038 <etext+0x38>
    8000077e:	8526                	mv	a0,s1
    80000780:	00000097          	auipc	ra,0x0
    80000784:	3c0080e7          	jalr	960(ra) # 80000b40 <initlock>
  pr.locking = 1;
    80000788:	4785                	li	a5,1
    8000078a:	cc9c                	sw	a5,24(s1)
}
    8000078c:	60e2                	ld	ra,24(sp)
    8000078e:	6442                	ld	s0,16(sp)
    80000790:	64a2                	ld	s1,8(sp)
    80000792:	6105                	add	sp,sp,32
    80000794:	8082                	ret

0000000080000796 <uartinit>:

void uartstart();

void
uartinit(void)
{
    80000796:	1141                	add	sp,sp,-16
    80000798:	e406                	sd	ra,8(sp)
    8000079a:	e022                	sd	s0,0(sp)
    8000079c:	0800                	add	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    8000079e:	100007b7          	lui	a5,0x10000
    800007a2:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007a6:	f8000713          	li	a4,-128
    800007aa:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007ae:	470d                	li	a4,3
    800007b0:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007b4:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007b8:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007bc:	469d                	li	a3,7
    800007be:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c2:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007c6:	00008597          	auipc	a1,0x8
    800007ca:	89258593          	add	a1,a1,-1902 # 80008058 <digits+0x18>
    800007ce:	00010517          	auipc	a0,0x10
    800007d2:	30a50513          	add	a0,a0,778 # 80010ad8 <uart_tx_lock>
    800007d6:	00000097          	auipc	ra,0x0
    800007da:	36a080e7          	jalr	874(ra) # 80000b40 <initlock>
}
    800007de:	60a2                	ld	ra,8(sp)
    800007e0:	6402                	ld	s0,0(sp)
    800007e2:	0141                	add	sp,sp,16
    800007e4:	8082                	ret

00000000800007e6 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007e6:	1101                	add	sp,sp,-32
    800007e8:	ec06                	sd	ra,24(sp)
    800007ea:	e822                	sd	s0,16(sp)
    800007ec:	e426                	sd	s1,8(sp)
    800007ee:	1000                	add	s0,sp,32
    800007f0:	84aa                	mv	s1,a0
  push_off();
    800007f2:	00000097          	auipc	ra,0x0
    800007f6:	392080e7          	jalr	914(ra) # 80000b84 <push_off>

  if(panicked){
    800007fa:	00008797          	auipc	a5,0x8
    800007fe:	0967a783          	lw	a5,150(a5) # 80008890 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000802:	10000737          	lui	a4,0x10000
  if(panicked){
    80000806:	c391                	beqz	a5,8000080a <uartputc_sync+0x24>
    for(;;)
    80000808:	a001                	j	80000808 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080a:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    8000080e:	0207f793          	and	a5,a5,32
    80000812:	dfe5                	beqz	a5,8000080a <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000814:	0ff4f513          	zext.b	a0,s1
    80000818:	100007b7          	lui	a5,0x10000
    8000081c:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000820:	00000097          	auipc	ra,0x0
    80000824:	404080e7          	jalr	1028(ra) # 80000c24 <pop_off>
}
    80000828:	60e2                	ld	ra,24(sp)
    8000082a:	6442                	ld	s0,16(sp)
    8000082c:	64a2                	ld	s1,8(sp)
    8000082e:	6105                	add	sp,sp,32
    80000830:	8082                	ret

0000000080000832 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000832:	00008797          	auipc	a5,0x8
    80000836:	0667b783          	ld	a5,102(a5) # 80008898 <uart_tx_r>
    8000083a:	00008717          	auipc	a4,0x8
    8000083e:	06673703          	ld	a4,102(a4) # 800088a0 <uart_tx_w>
    80000842:	06f70a63          	beq	a4,a5,800008b6 <uartstart+0x84>
{
    80000846:	7139                	add	sp,sp,-64
    80000848:	fc06                	sd	ra,56(sp)
    8000084a:	f822                	sd	s0,48(sp)
    8000084c:	f426                	sd	s1,40(sp)
    8000084e:	f04a                	sd	s2,32(sp)
    80000850:	ec4e                	sd	s3,24(sp)
    80000852:	e852                	sd	s4,16(sp)
    80000854:	e456                	sd	s5,8(sp)
    80000856:	0080                	add	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000858:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000085c:	00010a17          	auipc	s4,0x10
    80000860:	27ca0a13          	add	s4,s4,636 # 80010ad8 <uart_tx_lock>
    uart_tx_r += 1;
    80000864:	00008497          	auipc	s1,0x8
    80000868:	03448493          	add	s1,s1,52 # 80008898 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000086c:	00008997          	auipc	s3,0x8
    80000870:	03498993          	add	s3,s3,52 # 800088a0 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000874:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000878:	02077713          	and	a4,a4,32
    8000087c:	c705                	beqz	a4,800008a4 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000087e:	01f7f713          	and	a4,a5,31
    80000882:	9752                	add	a4,a4,s4
    80000884:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    80000888:	0785                	add	a5,a5,1
    8000088a:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000088c:	8526                	mv	a0,s1
    8000088e:	00002097          	auipc	ra,0x2
    80000892:	822080e7          	jalr	-2014(ra) # 800020b0 <wakeup>
    
    WriteReg(THR, c);
    80000896:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000089a:	609c                	ld	a5,0(s1)
    8000089c:	0009b703          	ld	a4,0(s3)
    800008a0:	fcf71ae3          	bne	a4,a5,80000874 <uartstart+0x42>
  }
}
    800008a4:	70e2                	ld	ra,56(sp)
    800008a6:	7442                	ld	s0,48(sp)
    800008a8:	74a2                	ld	s1,40(sp)
    800008aa:	7902                	ld	s2,32(sp)
    800008ac:	69e2                	ld	s3,24(sp)
    800008ae:	6a42                	ld	s4,16(sp)
    800008b0:	6aa2                	ld	s5,8(sp)
    800008b2:	6121                	add	sp,sp,64
    800008b4:	8082                	ret
    800008b6:	8082                	ret

00000000800008b8 <uartputc>:
{
    800008b8:	7179                	add	sp,sp,-48
    800008ba:	f406                	sd	ra,40(sp)
    800008bc:	f022                	sd	s0,32(sp)
    800008be:	ec26                	sd	s1,24(sp)
    800008c0:	e84a                	sd	s2,16(sp)
    800008c2:	e44e                	sd	s3,8(sp)
    800008c4:	e052                	sd	s4,0(sp)
    800008c6:	1800                	add	s0,sp,48
    800008c8:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008ca:	00010517          	auipc	a0,0x10
    800008ce:	20e50513          	add	a0,a0,526 # 80010ad8 <uart_tx_lock>
    800008d2:	00000097          	auipc	ra,0x0
    800008d6:	2fe080e7          	jalr	766(ra) # 80000bd0 <acquire>
  if(panicked){
    800008da:	00008797          	auipc	a5,0x8
    800008de:	fb67a783          	lw	a5,-74(a5) # 80008890 <panicked>
    800008e2:	e7c9                	bnez	a5,8000096c <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008e4:	00008717          	auipc	a4,0x8
    800008e8:	fbc73703          	ld	a4,-68(a4) # 800088a0 <uart_tx_w>
    800008ec:	00008797          	auipc	a5,0x8
    800008f0:	fac7b783          	ld	a5,-84(a5) # 80008898 <uart_tx_r>
    800008f4:	02078793          	add	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008f8:	00010997          	auipc	s3,0x10
    800008fc:	1e098993          	add	s3,s3,480 # 80010ad8 <uart_tx_lock>
    80000900:	00008497          	auipc	s1,0x8
    80000904:	f9848493          	add	s1,s1,-104 # 80008898 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000908:	00008917          	auipc	s2,0x8
    8000090c:	f9890913          	add	s2,s2,-104 # 800088a0 <uart_tx_w>
    80000910:	00e79f63          	bne	a5,a4,8000092e <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    80000914:	85ce                	mv	a1,s3
    80000916:	8526                	mv	a0,s1
    80000918:	00001097          	auipc	ra,0x1
    8000091c:	734080e7          	jalr	1844(ra) # 8000204c <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00093703          	ld	a4,0(s2)
    80000924:	609c                	ld	a5,0(s1)
    80000926:	02078793          	add	a5,a5,32
    8000092a:	fee785e3          	beq	a5,a4,80000914 <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    8000092e:	00010497          	auipc	s1,0x10
    80000932:	1aa48493          	add	s1,s1,426 # 80010ad8 <uart_tx_lock>
    80000936:	01f77793          	and	a5,a4,31
    8000093a:	97a6                	add	a5,a5,s1
    8000093c:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000940:	0705                	add	a4,a4,1
    80000942:	00008797          	auipc	a5,0x8
    80000946:	f4e7bf23          	sd	a4,-162(a5) # 800088a0 <uart_tx_w>
  uartstart();
    8000094a:	00000097          	auipc	ra,0x0
    8000094e:	ee8080e7          	jalr	-280(ra) # 80000832 <uartstart>
  release(&uart_tx_lock);
    80000952:	8526                	mv	a0,s1
    80000954:	00000097          	auipc	ra,0x0
    80000958:	330080e7          	jalr	816(ra) # 80000c84 <release>
}
    8000095c:	70a2                	ld	ra,40(sp)
    8000095e:	7402                	ld	s0,32(sp)
    80000960:	64e2                	ld	s1,24(sp)
    80000962:	6942                	ld	s2,16(sp)
    80000964:	69a2                	ld	s3,8(sp)
    80000966:	6a02                	ld	s4,0(sp)
    80000968:	6145                	add	sp,sp,48
    8000096a:	8082                	ret
    for(;;)
    8000096c:	a001                	j	8000096c <uartputc+0xb4>

000000008000096e <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    8000096e:	1141                	add	sp,sp,-16
    80000970:	e422                	sd	s0,8(sp)
    80000972:	0800                	add	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000974:	100007b7          	lui	a5,0x10000
    80000978:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000097c:	8b85                	and	a5,a5,1
    8000097e:	cb81                	beqz	a5,8000098e <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000980:	100007b7          	lui	a5,0x10000
    80000984:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    80000988:	6422                	ld	s0,8(sp)
    8000098a:	0141                	add	sp,sp,16
    8000098c:	8082                	ret
    return -1;
    8000098e:	557d                	li	a0,-1
    80000990:	bfe5                	j	80000988 <uartgetc+0x1a>

0000000080000992 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    80000992:	1101                	add	sp,sp,-32
    80000994:	ec06                	sd	ra,24(sp)
    80000996:	e822                	sd	s0,16(sp)
    80000998:	e426                	sd	s1,8(sp)
    8000099a:	1000                	add	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    8000099c:	54fd                	li	s1,-1
    8000099e:	a029                	j	800009a8 <uartintr+0x16>
      break;
    consoleintr(c);
    800009a0:	00000097          	auipc	ra,0x0
    800009a4:	918080e7          	jalr	-1768(ra) # 800002b8 <consoleintr>
    int c = uartgetc();
    800009a8:	00000097          	auipc	ra,0x0
    800009ac:	fc6080e7          	jalr	-58(ra) # 8000096e <uartgetc>
    if(c == -1)
    800009b0:	fe9518e3          	bne	a0,s1,800009a0 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009b4:	00010497          	auipc	s1,0x10
    800009b8:	12448493          	add	s1,s1,292 # 80010ad8 <uart_tx_lock>
    800009bc:	8526                	mv	a0,s1
    800009be:	00000097          	auipc	ra,0x0
    800009c2:	212080e7          	jalr	530(ra) # 80000bd0 <acquire>
  uartstart();
    800009c6:	00000097          	auipc	ra,0x0
    800009ca:	e6c080e7          	jalr	-404(ra) # 80000832 <uartstart>
  release(&uart_tx_lock);
    800009ce:	8526                	mv	a0,s1
    800009d0:	00000097          	auipc	ra,0x0
    800009d4:	2b4080e7          	jalr	692(ra) # 80000c84 <release>
}
    800009d8:	60e2                	ld	ra,24(sp)
    800009da:	6442                	ld	s0,16(sp)
    800009dc:	64a2                	ld	s1,8(sp)
    800009de:	6105                	add	sp,sp,32
    800009e0:	8082                	ret

00000000800009e2 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009e2:	1101                	add	sp,sp,-32
    800009e4:	ec06                	sd	ra,24(sp)
    800009e6:	e822                	sd	s0,16(sp)
    800009e8:	e426                	sd	s1,8(sp)
    800009ea:	e04a                	sd	s2,0(sp)
    800009ec:	1000                	add	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009ee:	03451793          	sll	a5,a0,0x34
    800009f2:	ebb9                	bnez	a5,80000a48 <kfree+0x66>
    800009f4:	84aa                	mv	s1,a0
    800009f6:	00021797          	auipc	a5,0x21
    800009fa:	34a78793          	add	a5,a5,842 # 80021d40 <end>
    800009fe:	04f56563          	bltu	a0,a5,80000a48 <kfree+0x66>
    80000a02:	47c5                	li	a5,17
    80000a04:	07ee                	sll	a5,a5,0x1b
    80000a06:	04f57163          	bgeu	a0,a5,80000a48 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a0a:	6605                	lui	a2,0x1
    80000a0c:	4585                	li	a1,1
    80000a0e:	00000097          	auipc	ra,0x0
    80000a12:	2be080e7          	jalr	702(ra) # 80000ccc <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a16:	00010917          	auipc	s2,0x10
    80000a1a:	0fa90913          	add	s2,s2,250 # 80010b10 <kmem>
    80000a1e:	854a                	mv	a0,s2
    80000a20:	00000097          	auipc	ra,0x0
    80000a24:	1b0080e7          	jalr	432(ra) # 80000bd0 <acquire>
  r->next = kmem.freelist;
    80000a28:	01893783          	ld	a5,24(s2)
    80000a2c:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a2e:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a32:	854a                	mv	a0,s2
    80000a34:	00000097          	auipc	ra,0x0
    80000a38:	250080e7          	jalr	592(ra) # 80000c84 <release>
}
    80000a3c:	60e2                	ld	ra,24(sp)
    80000a3e:	6442                	ld	s0,16(sp)
    80000a40:	64a2                	ld	s1,8(sp)
    80000a42:	6902                	ld	s2,0(sp)
    80000a44:	6105                	add	sp,sp,32
    80000a46:	8082                	ret
    panic("kfree");
    80000a48:	00007517          	auipc	a0,0x7
    80000a4c:	61850513          	add	a0,a0,1560 # 80008060 <digits+0x20>
    80000a50:	00000097          	auipc	ra,0x0
    80000a54:	aea080e7          	jalr	-1302(ra) # 8000053a <panic>

0000000080000a58 <freerange>:
{
    80000a58:	7179                	add	sp,sp,-48
    80000a5a:	f406                	sd	ra,40(sp)
    80000a5c:	f022                	sd	s0,32(sp)
    80000a5e:	ec26                	sd	s1,24(sp)
    80000a60:	e84a                	sd	s2,16(sp)
    80000a62:	e44e                	sd	s3,8(sp)
    80000a64:	e052                	sd	s4,0(sp)
    80000a66:	1800                	add	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a68:	6785                	lui	a5,0x1
    80000a6a:	fff78713          	add	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000a6e:	00e504b3          	add	s1,a0,a4
    80000a72:	777d                	lui	a4,0xfffff
    80000a74:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a76:	94be                	add	s1,s1,a5
    80000a78:	0095ee63          	bltu	a1,s1,80000a94 <freerange+0x3c>
    80000a7c:	892e                	mv	s2,a1
    kfree(p);
    80000a7e:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a80:	6985                	lui	s3,0x1
    kfree(p);
    80000a82:	01448533          	add	a0,s1,s4
    80000a86:	00000097          	auipc	ra,0x0
    80000a8a:	f5c080e7          	jalr	-164(ra) # 800009e2 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a8e:	94ce                	add	s1,s1,s3
    80000a90:	fe9979e3          	bgeu	s2,s1,80000a82 <freerange+0x2a>
}
    80000a94:	70a2                	ld	ra,40(sp)
    80000a96:	7402                	ld	s0,32(sp)
    80000a98:	64e2                	ld	s1,24(sp)
    80000a9a:	6942                	ld	s2,16(sp)
    80000a9c:	69a2                	ld	s3,8(sp)
    80000a9e:	6a02                	ld	s4,0(sp)
    80000aa0:	6145                	add	sp,sp,48
    80000aa2:	8082                	ret

0000000080000aa4 <kinit>:
{
    80000aa4:	1141                	add	sp,sp,-16
    80000aa6:	e406                	sd	ra,8(sp)
    80000aa8:	e022                	sd	s0,0(sp)
    80000aaa:	0800                	add	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000aac:	00007597          	auipc	a1,0x7
    80000ab0:	5bc58593          	add	a1,a1,1468 # 80008068 <digits+0x28>
    80000ab4:	00010517          	auipc	a0,0x10
    80000ab8:	05c50513          	add	a0,a0,92 # 80010b10 <kmem>
    80000abc:	00000097          	auipc	ra,0x0
    80000ac0:	084080e7          	jalr	132(ra) # 80000b40 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ac4:	45c5                	li	a1,17
    80000ac6:	05ee                	sll	a1,a1,0x1b
    80000ac8:	00021517          	auipc	a0,0x21
    80000acc:	27850513          	add	a0,a0,632 # 80021d40 <end>
    80000ad0:	00000097          	auipc	ra,0x0
    80000ad4:	f88080e7          	jalr	-120(ra) # 80000a58 <freerange>
}
    80000ad8:	60a2                	ld	ra,8(sp)
    80000ada:	6402                	ld	s0,0(sp)
    80000adc:	0141                	add	sp,sp,16
    80000ade:	8082                	ret

0000000080000ae0 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae0:	1101                	add	sp,sp,-32
    80000ae2:	ec06                	sd	ra,24(sp)
    80000ae4:	e822                	sd	s0,16(sp)
    80000ae6:	e426                	sd	s1,8(sp)
    80000ae8:	1000                	add	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000aea:	00010497          	auipc	s1,0x10
    80000aee:	02648493          	add	s1,s1,38 # 80010b10 <kmem>
    80000af2:	8526                	mv	a0,s1
    80000af4:	00000097          	auipc	ra,0x0
    80000af8:	0dc080e7          	jalr	220(ra) # 80000bd0 <acquire>
  r = kmem.freelist;
    80000afc:	6c84                	ld	s1,24(s1)
  if(r)
    80000afe:	c885                	beqz	s1,80000b2e <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b00:	609c                	ld	a5,0(s1)
    80000b02:	00010517          	auipc	a0,0x10
    80000b06:	00e50513          	add	a0,a0,14 # 80010b10 <kmem>
    80000b0a:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b0c:	00000097          	auipc	ra,0x0
    80000b10:	178080e7          	jalr	376(ra) # 80000c84 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b14:	6605                	lui	a2,0x1
    80000b16:	4595                	li	a1,5
    80000b18:	8526                	mv	a0,s1
    80000b1a:	00000097          	auipc	ra,0x0
    80000b1e:	1b2080e7          	jalr	434(ra) # 80000ccc <memset>
  return (void*)r;
}
    80000b22:	8526                	mv	a0,s1
    80000b24:	60e2                	ld	ra,24(sp)
    80000b26:	6442                	ld	s0,16(sp)
    80000b28:	64a2                	ld	s1,8(sp)
    80000b2a:	6105                	add	sp,sp,32
    80000b2c:	8082                	ret
  release(&kmem.lock);
    80000b2e:	00010517          	auipc	a0,0x10
    80000b32:	fe250513          	add	a0,a0,-30 # 80010b10 <kmem>
    80000b36:	00000097          	auipc	ra,0x0
    80000b3a:	14e080e7          	jalr	334(ra) # 80000c84 <release>
  if(r)
    80000b3e:	b7d5                	j	80000b22 <kalloc+0x42>

0000000080000b40 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b40:	1141                	add	sp,sp,-16
    80000b42:	e422                	sd	s0,8(sp)
    80000b44:	0800                	add	s0,sp,16
  lk->name = name;
    80000b46:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b48:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b4c:	00053823          	sd	zero,16(a0)
}
    80000b50:	6422                	ld	s0,8(sp)
    80000b52:	0141                	add	sp,sp,16
    80000b54:	8082                	ret

0000000080000b56 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b56:	411c                	lw	a5,0(a0)
    80000b58:	e399                	bnez	a5,80000b5e <holding+0x8>
    80000b5a:	4501                	li	a0,0
  return r;
}
    80000b5c:	8082                	ret
{
    80000b5e:	1101                	add	sp,sp,-32
    80000b60:	ec06                	sd	ra,24(sp)
    80000b62:	e822                	sd	s0,16(sp)
    80000b64:	e426                	sd	s1,8(sp)
    80000b66:	1000                	add	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b68:	6904                	ld	s1,16(a0)
    80000b6a:	00001097          	auipc	ra,0x1
    80000b6e:	e1e080e7          	jalr	-482(ra) # 80001988 <mycpu>
    80000b72:	40a48533          	sub	a0,s1,a0
    80000b76:	00153513          	seqz	a0,a0
}
    80000b7a:	60e2                	ld	ra,24(sp)
    80000b7c:	6442                	ld	s0,16(sp)
    80000b7e:	64a2                	ld	s1,8(sp)
    80000b80:	6105                	add	sp,sp,32
    80000b82:	8082                	ret

0000000080000b84 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b84:	1101                	add	sp,sp,-32
    80000b86:	ec06                	sd	ra,24(sp)
    80000b88:	e822                	sd	s0,16(sp)
    80000b8a:	e426                	sd	s1,8(sp)
    80000b8c:	1000                	add	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b8e:	100024f3          	csrr	s1,sstatus
    80000b92:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b96:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b98:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000b9c:	00001097          	auipc	ra,0x1
    80000ba0:	dec080e7          	jalr	-532(ra) # 80001988 <mycpu>
    80000ba4:	5d3c                	lw	a5,120(a0)
    80000ba6:	cf89                	beqz	a5,80000bc0 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000ba8:	00001097          	auipc	ra,0x1
    80000bac:	de0080e7          	jalr	-544(ra) # 80001988 <mycpu>
    80000bb0:	5d3c                	lw	a5,120(a0)
    80000bb2:	2785                	addw	a5,a5,1
    80000bb4:	dd3c                	sw	a5,120(a0)
}
    80000bb6:	60e2                	ld	ra,24(sp)
    80000bb8:	6442                	ld	s0,16(sp)
    80000bba:	64a2                	ld	s1,8(sp)
    80000bbc:	6105                	add	sp,sp,32
    80000bbe:	8082                	ret
    mycpu()->intena = old;
    80000bc0:	00001097          	auipc	ra,0x1
    80000bc4:	dc8080e7          	jalr	-568(ra) # 80001988 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bc8:	8085                	srl	s1,s1,0x1
    80000bca:	8885                	and	s1,s1,1
    80000bcc:	dd64                	sw	s1,124(a0)
    80000bce:	bfe9                	j	80000ba8 <push_off+0x24>

0000000080000bd0 <acquire>:
{
    80000bd0:	1101                	add	sp,sp,-32
    80000bd2:	ec06                	sd	ra,24(sp)
    80000bd4:	e822                	sd	s0,16(sp)
    80000bd6:	e426                	sd	s1,8(sp)
    80000bd8:	1000                	add	s0,sp,32
    80000bda:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bdc:	00000097          	auipc	ra,0x0
    80000be0:	fa8080e7          	jalr	-88(ra) # 80000b84 <push_off>
  if(holding(lk))
    80000be4:	8526                	mv	a0,s1
    80000be6:	00000097          	auipc	ra,0x0
    80000bea:	f70080e7          	jalr	-144(ra) # 80000b56 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bee:	4705                	li	a4,1
  if(holding(lk))
    80000bf0:	e115                	bnez	a0,80000c14 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf2:	87ba                	mv	a5,a4
    80000bf4:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bf8:	2781                	sext.w	a5,a5
    80000bfa:	ffe5                	bnez	a5,80000bf2 <acquire+0x22>
  __sync_synchronize();
    80000bfc:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c00:	00001097          	auipc	ra,0x1
    80000c04:	d88080e7          	jalr	-632(ra) # 80001988 <mycpu>
    80000c08:	e888                	sd	a0,16(s1)
}
    80000c0a:	60e2                	ld	ra,24(sp)
    80000c0c:	6442                	ld	s0,16(sp)
    80000c0e:	64a2                	ld	s1,8(sp)
    80000c10:	6105                	add	sp,sp,32
    80000c12:	8082                	ret
    panic("acquire");
    80000c14:	00007517          	auipc	a0,0x7
    80000c18:	45c50513          	add	a0,a0,1116 # 80008070 <digits+0x30>
    80000c1c:	00000097          	auipc	ra,0x0
    80000c20:	91e080e7          	jalr	-1762(ra) # 8000053a <panic>

0000000080000c24 <pop_off>:

void
pop_off(void)
{
    80000c24:	1141                	add	sp,sp,-16
    80000c26:	e406                	sd	ra,8(sp)
    80000c28:	e022                	sd	s0,0(sp)
    80000c2a:	0800                	add	s0,sp,16
  struct cpu *c = mycpu();
    80000c2c:	00001097          	auipc	ra,0x1
    80000c30:	d5c080e7          	jalr	-676(ra) # 80001988 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c34:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c38:	8b89                	and	a5,a5,2
  if(intr_get())
    80000c3a:	e78d                	bnez	a5,80000c64 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c3c:	5d3c                	lw	a5,120(a0)
    80000c3e:	02f05b63          	blez	a5,80000c74 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c42:	37fd                	addw	a5,a5,-1
    80000c44:	0007871b          	sext.w	a4,a5
    80000c48:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c4a:	eb09                	bnez	a4,80000c5c <pop_off+0x38>
    80000c4c:	5d7c                	lw	a5,124(a0)
    80000c4e:	c799                	beqz	a5,80000c5c <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c50:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c54:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c58:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c5c:	60a2                	ld	ra,8(sp)
    80000c5e:	6402                	ld	s0,0(sp)
    80000c60:	0141                	add	sp,sp,16
    80000c62:	8082                	ret
    panic("pop_off - interruptible");
    80000c64:	00007517          	auipc	a0,0x7
    80000c68:	41450513          	add	a0,a0,1044 # 80008078 <digits+0x38>
    80000c6c:	00000097          	auipc	ra,0x0
    80000c70:	8ce080e7          	jalr	-1842(ra) # 8000053a <panic>
    panic("pop_off");
    80000c74:	00007517          	auipc	a0,0x7
    80000c78:	41c50513          	add	a0,a0,1052 # 80008090 <digits+0x50>
    80000c7c:	00000097          	auipc	ra,0x0
    80000c80:	8be080e7          	jalr	-1858(ra) # 8000053a <panic>

0000000080000c84 <release>:
{
    80000c84:	1101                	add	sp,sp,-32
    80000c86:	ec06                	sd	ra,24(sp)
    80000c88:	e822                	sd	s0,16(sp)
    80000c8a:	e426                	sd	s1,8(sp)
    80000c8c:	1000                	add	s0,sp,32
    80000c8e:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c90:	00000097          	auipc	ra,0x0
    80000c94:	ec6080e7          	jalr	-314(ra) # 80000b56 <holding>
    80000c98:	c115                	beqz	a0,80000cbc <release+0x38>
  lk->cpu = 0;
    80000c9a:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000c9e:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca2:	0f50000f          	fence	iorw,ow
    80000ca6:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000caa:	00000097          	auipc	ra,0x0
    80000cae:	f7a080e7          	jalr	-134(ra) # 80000c24 <pop_off>
}
    80000cb2:	60e2                	ld	ra,24(sp)
    80000cb4:	6442                	ld	s0,16(sp)
    80000cb6:	64a2                	ld	s1,8(sp)
    80000cb8:	6105                	add	sp,sp,32
    80000cba:	8082                	ret
    panic("release");
    80000cbc:	00007517          	auipc	a0,0x7
    80000cc0:	3dc50513          	add	a0,a0,988 # 80008098 <digits+0x58>
    80000cc4:	00000097          	auipc	ra,0x0
    80000cc8:	876080e7          	jalr	-1930(ra) # 8000053a <panic>

0000000080000ccc <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ccc:	1141                	add	sp,sp,-16
    80000cce:	e422                	sd	s0,8(sp)
    80000cd0:	0800                	add	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd2:	ca19                	beqz	a2,80000ce8 <memset+0x1c>
    80000cd4:	87aa                	mv	a5,a0
    80000cd6:	1602                	sll	a2,a2,0x20
    80000cd8:	9201                	srl	a2,a2,0x20
    80000cda:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000cde:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ce2:	0785                	add	a5,a5,1
    80000ce4:	fee79de3          	bne	a5,a4,80000cde <memset+0x12>
  }
  return dst;
}
    80000ce8:	6422                	ld	s0,8(sp)
    80000cea:	0141                	add	sp,sp,16
    80000cec:	8082                	ret

0000000080000cee <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cee:	1141                	add	sp,sp,-16
    80000cf0:	e422                	sd	s0,8(sp)
    80000cf2:	0800                	add	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cf4:	ca05                	beqz	a2,80000d24 <memcmp+0x36>
    80000cf6:	fff6069b          	addw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000cfa:	1682                	sll	a3,a3,0x20
    80000cfc:	9281                	srl	a3,a3,0x20
    80000cfe:	0685                	add	a3,a3,1
    80000d00:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d02:	00054783          	lbu	a5,0(a0)
    80000d06:	0005c703          	lbu	a4,0(a1)
    80000d0a:	00e79863          	bne	a5,a4,80000d1a <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d0e:	0505                	add	a0,a0,1
    80000d10:	0585                	add	a1,a1,1
  while(n-- > 0){
    80000d12:	fed518e3          	bne	a0,a3,80000d02 <memcmp+0x14>
  }

  return 0;
    80000d16:	4501                	li	a0,0
    80000d18:	a019                	j	80000d1e <memcmp+0x30>
      return *s1 - *s2;
    80000d1a:	40e7853b          	subw	a0,a5,a4
}
    80000d1e:	6422                	ld	s0,8(sp)
    80000d20:	0141                	add	sp,sp,16
    80000d22:	8082                	ret
  return 0;
    80000d24:	4501                	li	a0,0
    80000d26:	bfe5                	j	80000d1e <memcmp+0x30>

0000000080000d28 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d28:	1141                	add	sp,sp,-16
    80000d2a:	e422                	sd	s0,8(sp)
    80000d2c:	0800                	add	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d2e:	c205                	beqz	a2,80000d4e <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d30:	02a5e263          	bltu	a1,a0,80000d54 <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d34:	1602                	sll	a2,a2,0x20
    80000d36:	9201                	srl	a2,a2,0x20
    80000d38:	00c587b3          	add	a5,a1,a2
{
    80000d3c:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d3e:	0585                	add	a1,a1,1
    80000d40:	0705                	add	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffdd2c1>
    80000d42:	fff5c683          	lbu	a3,-1(a1)
    80000d46:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d4a:	fef59ae3          	bne	a1,a5,80000d3e <memmove+0x16>

  return dst;
}
    80000d4e:	6422                	ld	s0,8(sp)
    80000d50:	0141                	add	sp,sp,16
    80000d52:	8082                	ret
  if(s < d && s + n > d){
    80000d54:	02061693          	sll	a3,a2,0x20
    80000d58:	9281                	srl	a3,a3,0x20
    80000d5a:	00d58733          	add	a4,a1,a3
    80000d5e:	fce57be3          	bgeu	a0,a4,80000d34 <memmove+0xc>
    d += n;
    80000d62:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d64:	fff6079b          	addw	a5,a2,-1
    80000d68:	1782                	sll	a5,a5,0x20
    80000d6a:	9381                	srl	a5,a5,0x20
    80000d6c:	fff7c793          	not	a5,a5
    80000d70:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d72:	177d                	add	a4,a4,-1
    80000d74:	16fd                	add	a3,a3,-1
    80000d76:	00074603          	lbu	a2,0(a4)
    80000d7a:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d7e:	fee79ae3          	bne	a5,a4,80000d72 <memmove+0x4a>
    80000d82:	b7f1                	j	80000d4e <memmove+0x26>

0000000080000d84 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d84:	1141                	add	sp,sp,-16
    80000d86:	e406                	sd	ra,8(sp)
    80000d88:	e022                	sd	s0,0(sp)
    80000d8a:	0800                	add	s0,sp,16
  return memmove(dst, src, n);
    80000d8c:	00000097          	auipc	ra,0x0
    80000d90:	f9c080e7          	jalr	-100(ra) # 80000d28 <memmove>
}
    80000d94:	60a2                	ld	ra,8(sp)
    80000d96:	6402                	ld	s0,0(sp)
    80000d98:	0141                	add	sp,sp,16
    80000d9a:	8082                	ret

0000000080000d9c <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000d9c:	1141                	add	sp,sp,-16
    80000d9e:	e422                	sd	s0,8(sp)
    80000da0:	0800                	add	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000da2:	ce11                	beqz	a2,80000dbe <strncmp+0x22>
    80000da4:	00054783          	lbu	a5,0(a0)
    80000da8:	cf89                	beqz	a5,80000dc2 <strncmp+0x26>
    80000daa:	0005c703          	lbu	a4,0(a1)
    80000dae:	00f71a63          	bne	a4,a5,80000dc2 <strncmp+0x26>
    n--, p++, q++;
    80000db2:	367d                	addw	a2,a2,-1
    80000db4:	0505                	add	a0,a0,1
    80000db6:	0585                	add	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000db8:	f675                	bnez	a2,80000da4 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dba:	4501                	li	a0,0
    80000dbc:	a809                	j	80000dce <strncmp+0x32>
    80000dbe:	4501                	li	a0,0
    80000dc0:	a039                	j	80000dce <strncmp+0x32>
  if(n == 0)
    80000dc2:	ca09                	beqz	a2,80000dd4 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dc4:	00054503          	lbu	a0,0(a0)
    80000dc8:	0005c783          	lbu	a5,0(a1)
    80000dcc:	9d1d                	subw	a0,a0,a5
}
    80000dce:	6422                	ld	s0,8(sp)
    80000dd0:	0141                	add	sp,sp,16
    80000dd2:	8082                	ret
    return 0;
    80000dd4:	4501                	li	a0,0
    80000dd6:	bfe5                	j	80000dce <strncmp+0x32>

0000000080000dd8 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dd8:	1141                	add	sp,sp,-16
    80000dda:	e422                	sd	s0,8(sp)
    80000ddc:	0800                	add	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000dde:	87aa                	mv	a5,a0
    80000de0:	86b2                	mv	a3,a2
    80000de2:	367d                	addw	a2,a2,-1
    80000de4:	00d05963          	blez	a3,80000df6 <strncpy+0x1e>
    80000de8:	0785                	add	a5,a5,1
    80000dea:	0005c703          	lbu	a4,0(a1)
    80000dee:	fee78fa3          	sb	a4,-1(a5)
    80000df2:	0585                	add	a1,a1,1
    80000df4:	f775                	bnez	a4,80000de0 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000df6:	873e                	mv	a4,a5
    80000df8:	9fb5                	addw	a5,a5,a3
    80000dfa:	37fd                	addw	a5,a5,-1
    80000dfc:	00c05963          	blez	a2,80000e0e <strncpy+0x36>
    *s++ = 0;
    80000e00:	0705                	add	a4,a4,1
    80000e02:	fe070fa3          	sb	zero,-1(a4)
  while(n-- > 0)
    80000e06:	40e786bb          	subw	a3,a5,a4
    80000e0a:	fed04be3          	bgtz	a3,80000e00 <strncpy+0x28>
  return os;
}
    80000e0e:	6422                	ld	s0,8(sp)
    80000e10:	0141                	add	sp,sp,16
    80000e12:	8082                	ret

0000000080000e14 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e14:	1141                	add	sp,sp,-16
    80000e16:	e422                	sd	s0,8(sp)
    80000e18:	0800                	add	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e1a:	02c05363          	blez	a2,80000e40 <safestrcpy+0x2c>
    80000e1e:	fff6069b          	addw	a3,a2,-1
    80000e22:	1682                	sll	a3,a3,0x20
    80000e24:	9281                	srl	a3,a3,0x20
    80000e26:	96ae                	add	a3,a3,a1
    80000e28:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e2a:	00d58963          	beq	a1,a3,80000e3c <safestrcpy+0x28>
    80000e2e:	0585                	add	a1,a1,1
    80000e30:	0785                	add	a5,a5,1
    80000e32:	fff5c703          	lbu	a4,-1(a1)
    80000e36:	fee78fa3          	sb	a4,-1(a5)
    80000e3a:	fb65                	bnez	a4,80000e2a <safestrcpy+0x16>
    ;
  *s = 0;
    80000e3c:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e40:	6422                	ld	s0,8(sp)
    80000e42:	0141                	add	sp,sp,16
    80000e44:	8082                	ret

0000000080000e46 <strlen>:

int
strlen(const char *s)
{
    80000e46:	1141                	add	sp,sp,-16
    80000e48:	e422                	sd	s0,8(sp)
    80000e4a:	0800                	add	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e4c:	00054783          	lbu	a5,0(a0)
    80000e50:	cf91                	beqz	a5,80000e6c <strlen+0x26>
    80000e52:	0505                	add	a0,a0,1
    80000e54:	87aa                	mv	a5,a0
    80000e56:	86be                	mv	a3,a5
    80000e58:	0785                	add	a5,a5,1
    80000e5a:	fff7c703          	lbu	a4,-1(a5)
    80000e5e:	ff65                	bnez	a4,80000e56 <strlen+0x10>
    80000e60:	40a6853b          	subw	a0,a3,a0
    80000e64:	2505                	addw	a0,a0,1
    ;
  return n;
}
    80000e66:	6422                	ld	s0,8(sp)
    80000e68:	0141                	add	sp,sp,16
    80000e6a:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e6c:	4501                	li	a0,0
    80000e6e:	bfe5                	j	80000e66 <strlen+0x20>

0000000080000e70 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e70:	1141                	add	sp,sp,-16
    80000e72:	e406                	sd	ra,8(sp)
    80000e74:	e022                	sd	s0,0(sp)
    80000e76:	0800                	add	s0,sp,16
  if(cpuid() == 0){
    80000e78:	00001097          	auipc	ra,0x1
    80000e7c:	b00080e7          	jalr	-1280(ra) # 80001978 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e80:	00008717          	auipc	a4,0x8
    80000e84:	a2870713          	add	a4,a4,-1496 # 800088a8 <started>
  if(cpuid() == 0){
    80000e88:	c139                	beqz	a0,80000ece <main+0x5e>
    while(started == 0)
    80000e8a:	431c                	lw	a5,0(a4)
    80000e8c:	2781                	sext.w	a5,a5
    80000e8e:	dff5                	beqz	a5,80000e8a <main+0x1a>
      ;
    __sync_synchronize();
    80000e90:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e94:	00001097          	auipc	ra,0x1
    80000e98:	ae4080e7          	jalr	-1308(ra) # 80001978 <cpuid>
    80000e9c:	85aa                	mv	a1,a0
    80000e9e:	00007517          	auipc	a0,0x7
    80000ea2:	21a50513          	add	a0,a0,538 # 800080b8 <digits+0x78>
    80000ea6:	fffff097          	auipc	ra,0xfffff
    80000eaa:	6de080e7          	jalr	1758(ra) # 80000584 <printf>
    kvminithart();    // turn on paging
    80000eae:	00000097          	auipc	ra,0x0
    80000eb2:	0d8080e7          	jalr	216(ra) # 80000f86 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eb6:	00001097          	auipc	ra,0x1
    80000eba:	78c080e7          	jalr	1932(ra) # 80002642 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ebe:	00005097          	auipc	ra,0x5
    80000ec2:	cc2080e7          	jalr	-830(ra) # 80005b80 <plicinithart>
  }

  scheduler();        
    80000ec6:	00001097          	auipc	ra,0x1
    80000eca:	fd4080e7          	jalr	-44(ra) # 80001e9a <scheduler>
    consoleinit();
    80000ece:	fffff097          	auipc	ra,0xfffff
    80000ed2:	57c080e7          	jalr	1404(ra) # 8000044a <consoleinit>
    printfinit();
    80000ed6:	00000097          	auipc	ra,0x0
    80000eda:	88e080e7          	jalr	-1906(ra) # 80000764 <printfinit>
    printf("\n");
    80000ede:	00007517          	auipc	a0,0x7
    80000ee2:	1ea50513          	add	a0,a0,490 # 800080c8 <digits+0x88>
    80000ee6:	fffff097          	auipc	ra,0xfffff
    80000eea:	69e080e7          	jalr	1694(ra) # 80000584 <printf>
    printf("xv6 kernel is booting\n");
    80000eee:	00007517          	auipc	a0,0x7
    80000ef2:	1b250513          	add	a0,a0,434 # 800080a0 <digits+0x60>
    80000ef6:	fffff097          	auipc	ra,0xfffff
    80000efa:	68e080e7          	jalr	1678(ra) # 80000584 <printf>
    printf("\n");
    80000efe:	00007517          	auipc	a0,0x7
    80000f02:	1ca50513          	add	a0,a0,458 # 800080c8 <digits+0x88>
    80000f06:	fffff097          	auipc	ra,0xfffff
    80000f0a:	67e080e7          	jalr	1662(ra) # 80000584 <printf>
    kinit();         // physical page allocator
    80000f0e:	00000097          	auipc	ra,0x0
    80000f12:	b96080e7          	jalr	-1130(ra) # 80000aa4 <kinit>
    kvminit();       // create kernel page table
    80000f16:	00000097          	auipc	ra,0x0
    80000f1a:	326080e7          	jalr	806(ra) # 8000123c <kvminit>
    kvminithart();   // turn on paging
    80000f1e:	00000097          	auipc	ra,0x0
    80000f22:	068080e7          	jalr	104(ra) # 80000f86 <kvminithart>
    procinit();      // process table
    80000f26:	00001097          	auipc	ra,0x1
    80000f2a:	99e080e7          	jalr	-1634(ra) # 800018c4 <procinit>
    trapinit();      // trap vectors
    80000f2e:	00001097          	auipc	ra,0x1
    80000f32:	6ec080e7          	jalr	1772(ra) # 8000261a <trapinit>
    trapinithart();  // install kernel trap vector
    80000f36:	00001097          	auipc	ra,0x1
    80000f3a:	70c080e7          	jalr	1804(ra) # 80002642 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f3e:	00005097          	auipc	ra,0x5
    80000f42:	c2c080e7          	jalr	-980(ra) # 80005b6a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f46:	00005097          	auipc	ra,0x5
    80000f4a:	c3a080e7          	jalr	-966(ra) # 80005b80 <plicinithart>
    binit();         // buffer cache
    80000f4e:	00002097          	auipc	ra,0x2
    80000f52:	e34080e7          	jalr	-460(ra) # 80002d82 <binit>
    iinit();         // inode table
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	4d2080e7          	jalr	1234(ra) # 80003428 <iinit>
    fileinit();      // file table
    80000f5e:	00003097          	auipc	ra,0x3
    80000f62:	448080e7          	jalr	1096(ra) # 800043a6 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f66:	00005097          	auipc	ra,0x5
    80000f6a:	d22080e7          	jalr	-734(ra) # 80005c88 <virtio_disk_init>
    userinit();      // first user process
    80000f6e:	00001097          	auipc	ra,0x1
    80000f72:	d0e080e7          	jalr	-754(ra) # 80001c7c <userinit>
    __sync_synchronize();
    80000f76:	0ff0000f          	fence
    started = 1;
    80000f7a:	4785                	li	a5,1
    80000f7c:	00008717          	auipc	a4,0x8
    80000f80:	92f72623          	sw	a5,-1748(a4) # 800088a8 <started>
    80000f84:	b789                	j	80000ec6 <main+0x56>

0000000080000f86 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f86:	1141                	add	sp,sp,-16
    80000f88:	e422                	sd	s0,8(sp)
    80000f8a:	0800                	add	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000f8c:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000f90:	00008797          	auipc	a5,0x8
    80000f94:	9207b783          	ld	a5,-1760(a5) # 800088b0 <kernel_pagetable>
    80000f98:	83b1                	srl	a5,a5,0xc
    80000f9a:	577d                	li	a4,-1
    80000f9c:	177e                	sll	a4,a4,0x3f
    80000f9e:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fa0:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000fa4:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000fa8:	6422                	ld	s0,8(sp)
    80000faa:	0141                	add	sp,sp,16
    80000fac:	8082                	ret

0000000080000fae <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fae:	7139                	add	sp,sp,-64
    80000fb0:	fc06                	sd	ra,56(sp)
    80000fb2:	f822                	sd	s0,48(sp)
    80000fb4:	f426                	sd	s1,40(sp)
    80000fb6:	f04a                	sd	s2,32(sp)
    80000fb8:	ec4e                	sd	s3,24(sp)
    80000fba:	e852                	sd	s4,16(sp)
    80000fbc:	e456                	sd	s5,8(sp)
    80000fbe:	e05a                	sd	s6,0(sp)
    80000fc0:	0080                	add	s0,sp,64
    80000fc2:	84aa                	mv	s1,a0
    80000fc4:	89ae                	mv	s3,a1
    80000fc6:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fc8:	57fd                	li	a5,-1
    80000fca:	83e9                	srl	a5,a5,0x1a
    80000fcc:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fce:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fd0:	04b7f263          	bgeu	a5,a1,80001014 <walk+0x66>
    panic("walk");
    80000fd4:	00007517          	auipc	a0,0x7
    80000fd8:	0fc50513          	add	a0,a0,252 # 800080d0 <digits+0x90>
    80000fdc:	fffff097          	auipc	ra,0xfffff
    80000fe0:	55e080e7          	jalr	1374(ra) # 8000053a <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fe4:	060a8663          	beqz	s5,80001050 <walk+0xa2>
    80000fe8:	00000097          	auipc	ra,0x0
    80000fec:	af8080e7          	jalr	-1288(ra) # 80000ae0 <kalloc>
    80000ff0:	84aa                	mv	s1,a0
    80000ff2:	c529                	beqz	a0,8000103c <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000ff4:	6605                	lui	a2,0x1
    80000ff6:	4581                	li	a1,0
    80000ff8:	00000097          	auipc	ra,0x0
    80000ffc:	cd4080e7          	jalr	-812(ra) # 80000ccc <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001000:	00c4d793          	srl	a5,s1,0xc
    80001004:	07aa                	sll	a5,a5,0xa
    80001006:	0017e793          	or	a5,a5,1
    8000100a:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    8000100e:	3a5d                	addw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffdd2b7>
    80001010:	036a0063          	beq	s4,s6,80001030 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001014:	0149d933          	srl	s2,s3,s4
    80001018:	1ff97913          	and	s2,s2,511
    8000101c:	090e                	sll	s2,s2,0x3
    8000101e:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001020:	00093483          	ld	s1,0(s2)
    80001024:	0014f793          	and	a5,s1,1
    80001028:	dfd5                	beqz	a5,80000fe4 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000102a:	80a9                	srl	s1,s1,0xa
    8000102c:	04b2                	sll	s1,s1,0xc
    8000102e:	b7c5                	j	8000100e <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001030:	00c9d513          	srl	a0,s3,0xc
    80001034:	1ff57513          	and	a0,a0,511
    80001038:	050e                	sll	a0,a0,0x3
    8000103a:	9526                	add	a0,a0,s1
}
    8000103c:	70e2                	ld	ra,56(sp)
    8000103e:	7442                	ld	s0,48(sp)
    80001040:	74a2                	ld	s1,40(sp)
    80001042:	7902                	ld	s2,32(sp)
    80001044:	69e2                	ld	s3,24(sp)
    80001046:	6a42                	ld	s4,16(sp)
    80001048:	6aa2                	ld	s5,8(sp)
    8000104a:	6b02                	ld	s6,0(sp)
    8000104c:	6121                	add	sp,sp,64
    8000104e:	8082                	ret
        return 0;
    80001050:	4501                	li	a0,0
    80001052:	b7ed                	j	8000103c <walk+0x8e>

0000000080001054 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001054:	57fd                	li	a5,-1
    80001056:	83e9                	srl	a5,a5,0x1a
    80001058:	00b7f463          	bgeu	a5,a1,80001060 <walkaddr+0xc>
    return 0;
    8000105c:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    8000105e:	8082                	ret
{
    80001060:	1141                	add	sp,sp,-16
    80001062:	e406                	sd	ra,8(sp)
    80001064:	e022                	sd	s0,0(sp)
    80001066:	0800                	add	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001068:	4601                	li	a2,0
    8000106a:	00000097          	auipc	ra,0x0
    8000106e:	f44080e7          	jalr	-188(ra) # 80000fae <walk>
  if(pte == 0)
    80001072:	c105                	beqz	a0,80001092 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001074:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001076:	0117f693          	and	a3,a5,17
    8000107a:	4745                	li	a4,17
    return 0;
    8000107c:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    8000107e:	00e68663          	beq	a3,a4,8000108a <walkaddr+0x36>
}
    80001082:	60a2                	ld	ra,8(sp)
    80001084:	6402                	ld	s0,0(sp)
    80001086:	0141                	add	sp,sp,16
    80001088:	8082                	ret
  pa = PTE2PA(*pte);
    8000108a:	83a9                	srl	a5,a5,0xa
    8000108c:	00c79513          	sll	a0,a5,0xc
  return pa;
    80001090:	bfcd                	j	80001082 <walkaddr+0x2e>
    return 0;
    80001092:	4501                	li	a0,0
    80001094:	b7fd                	j	80001082 <walkaddr+0x2e>

0000000080001096 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001096:	715d                	add	sp,sp,-80
    80001098:	e486                	sd	ra,72(sp)
    8000109a:	e0a2                	sd	s0,64(sp)
    8000109c:	fc26                	sd	s1,56(sp)
    8000109e:	f84a                	sd	s2,48(sp)
    800010a0:	f44e                	sd	s3,40(sp)
    800010a2:	f052                	sd	s4,32(sp)
    800010a4:	ec56                	sd	s5,24(sp)
    800010a6:	e85a                	sd	s6,16(sp)
    800010a8:	e45e                	sd	s7,8(sp)
    800010aa:	0880                	add	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010ac:	c639                	beqz	a2,800010fa <mappages+0x64>
    800010ae:	8aaa                	mv	s5,a0
    800010b0:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010b2:	777d                	lui	a4,0xfffff
    800010b4:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010b8:	fff58993          	add	s3,a1,-1
    800010bc:	99b2                	add	s3,s3,a2
    800010be:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010c2:	893e                	mv	s2,a5
    800010c4:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010c8:	6b85                	lui	s7,0x1
    800010ca:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010ce:	4605                	li	a2,1
    800010d0:	85ca                	mv	a1,s2
    800010d2:	8556                	mv	a0,s5
    800010d4:	00000097          	auipc	ra,0x0
    800010d8:	eda080e7          	jalr	-294(ra) # 80000fae <walk>
    800010dc:	cd1d                	beqz	a0,8000111a <mappages+0x84>
    if(*pte & PTE_V)
    800010de:	611c                	ld	a5,0(a0)
    800010e0:	8b85                	and	a5,a5,1
    800010e2:	e785                	bnez	a5,8000110a <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010e4:	80b1                	srl	s1,s1,0xc
    800010e6:	04aa                	sll	s1,s1,0xa
    800010e8:	0164e4b3          	or	s1,s1,s6
    800010ec:	0014e493          	or	s1,s1,1
    800010f0:	e104                	sd	s1,0(a0)
    if(a == last)
    800010f2:	05390063          	beq	s2,s3,80001132 <mappages+0x9c>
    a += PGSIZE;
    800010f6:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800010f8:	bfc9                	j	800010ca <mappages+0x34>
    panic("mappages: size");
    800010fa:	00007517          	auipc	a0,0x7
    800010fe:	fde50513          	add	a0,a0,-34 # 800080d8 <digits+0x98>
    80001102:	fffff097          	auipc	ra,0xfffff
    80001106:	438080e7          	jalr	1080(ra) # 8000053a <panic>
      panic("mappages: remap");
    8000110a:	00007517          	auipc	a0,0x7
    8000110e:	fde50513          	add	a0,a0,-34 # 800080e8 <digits+0xa8>
    80001112:	fffff097          	auipc	ra,0xfffff
    80001116:	428080e7          	jalr	1064(ra) # 8000053a <panic>
      return -1;
    8000111a:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    8000111c:	60a6                	ld	ra,72(sp)
    8000111e:	6406                	ld	s0,64(sp)
    80001120:	74e2                	ld	s1,56(sp)
    80001122:	7942                	ld	s2,48(sp)
    80001124:	79a2                	ld	s3,40(sp)
    80001126:	7a02                	ld	s4,32(sp)
    80001128:	6ae2                	ld	s5,24(sp)
    8000112a:	6b42                	ld	s6,16(sp)
    8000112c:	6ba2                	ld	s7,8(sp)
    8000112e:	6161                	add	sp,sp,80
    80001130:	8082                	ret
  return 0;
    80001132:	4501                	li	a0,0
    80001134:	b7e5                	j	8000111c <mappages+0x86>

0000000080001136 <kvmmap>:
{
    80001136:	1141                	add	sp,sp,-16
    80001138:	e406                	sd	ra,8(sp)
    8000113a:	e022                	sd	s0,0(sp)
    8000113c:	0800                	add	s0,sp,16
    8000113e:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001140:	86b2                	mv	a3,a2
    80001142:	863e                	mv	a2,a5
    80001144:	00000097          	auipc	ra,0x0
    80001148:	f52080e7          	jalr	-174(ra) # 80001096 <mappages>
    8000114c:	e509                	bnez	a0,80001156 <kvmmap+0x20>
}
    8000114e:	60a2                	ld	ra,8(sp)
    80001150:	6402                	ld	s0,0(sp)
    80001152:	0141                	add	sp,sp,16
    80001154:	8082                	ret
    panic("kvmmap");
    80001156:	00007517          	auipc	a0,0x7
    8000115a:	fa250513          	add	a0,a0,-94 # 800080f8 <digits+0xb8>
    8000115e:	fffff097          	auipc	ra,0xfffff
    80001162:	3dc080e7          	jalr	988(ra) # 8000053a <panic>

0000000080001166 <kvmmake>:
{
    80001166:	1101                	add	sp,sp,-32
    80001168:	ec06                	sd	ra,24(sp)
    8000116a:	e822                	sd	s0,16(sp)
    8000116c:	e426                	sd	s1,8(sp)
    8000116e:	e04a                	sd	s2,0(sp)
    80001170:	1000                	add	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001172:	00000097          	auipc	ra,0x0
    80001176:	96e080e7          	jalr	-1682(ra) # 80000ae0 <kalloc>
    8000117a:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    8000117c:	6605                	lui	a2,0x1
    8000117e:	4581                	li	a1,0
    80001180:	00000097          	auipc	ra,0x0
    80001184:	b4c080e7          	jalr	-1204(ra) # 80000ccc <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001188:	4719                	li	a4,6
    8000118a:	6685                	lui	a3,0x1
    8000118c:	10000637          	lui	a2,0x10000
    80001190:	100005b7          	lui	a1,0x10000
    80001194:	8526                	mv	a0,s1
    80001196:	00000097          	auipc	ra,0x0
    8000119a:	fa0080e7          	jalr	-96(ra) # 80001136 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000119e:	4719                	li	a4,6
    800011a0:	6685                	lui	a3,0x1
    800011a2:	10001637          	lui	a2,0x10001
    800011a6:	100015b7          	lui	a1,0x10001
    800011aa:	8526                	mv	a0,s1
    800011ac:	00000097          	auipc	ra,0x0
    800011b0:	f8a080e7          	jalr	-118(ra) # 80001136 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011b4:	4719                	li	a4,6
    800011b6:	004006b7          	lui	a3,0x400
    800011ba:	0c000637          	lui	a2,0xc000
    800011be:	0c0005b7          	lui	a1,0xc000
    800011c2:	8526                	mv	a0,s1
    800011c4:	00000097          	auipc	ra,0x0
    800011c8:	f72080e7          	jalr	-142(ra) # 80001136 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011cc:	00007917          	auipc	s2,0x7
    800011d0:	e3490913          	add	s2,s2,-460 # 80008000 <etext>
    800011d4:	4729                	li	a4,10
    800011d6:	80007697          	auipc	a3,0x80007
    800011da:	e2a68693          	add	a3,a3,-470 # 8000 <_entry-0x7fff8000>
    800011de:	4605                	li	a2,1
    800011e0:	067e                	sll	a2,a2,0x1f
    800011e2:	85b2                	mv	a1,a2
    800011e4:	8526                	mv	a0,s1
    800011e6:	00000097          	auipc	ra,0x0
    800011ea:	f50080e7          	jalr	-176(ra) # 80001136 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011ee:	4719                	li	a4,6
    800011f0:	46c5                	li	a3,17
    800011f2:	06ee                	sll	a3,a3,0x1b
    800011f4:	412686b3          	sub	a3,a3,s2
    800011f8:	864a                	mv	a2,s2
    800011fa:	85ca                	mv	a1,s2
    800011fc:	8526                	mv	a0,s1
    800011fe:	00000097          	auipc	ra,0x0
    80001202:	f38080e7          	jalr	-200(ra) # 80001136 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001206:	4729                	li	a4,10
    80001208:	6685                	lui	a3,0x1
    8000120a:	00006617          	auipc	a2,0x6
    8000120e:	df660613          	add	a2,a2,-522 # 80007000 <_trampoline>
    80001212:	040005b7          	lui	a1,0x4000
    80001216:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001218:	05b2                	sll	a1,a1,0xc
    8000121a:	8526                	mv	a0,s1
    8000121c:	00000097          	auipc	ra,0x0
    80001220:	f1a080e7          	jalr	-230(ra) # 80001136 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001224:	8526                	mv	a0,s1
    80001226:	00000097          	auipc	ra,0x0
    8000122a:	608080e7          	jalr	1544(ra) # 8000182e <proc_mapstacks>
}
    8000122e:	8526                	mv	a0,s1
    80001230:	60e2                	ld	ra,24(sp)
    80001232:	6442                	ld	s0,16(sp)
    80001234:	64a2                	ld	s1,8(sp)
    80001236:	6902                	ld	s2,0(sp)
    80001238:	6105                	add	sp,sp,32
    8000123a:	8082                	ret

000000008000123c <kvminit>:
{
    8000123c:	1141                	add	sp,sp,-16
    8000123e:	e406                	sd	ra,8(sp)
    80001240:	e022                	sd	s0,0(sp)
    80001242:	0800                	add	s0,sp,16
  kernel_pagetable = kvmmake();
    80001244:	00000097          	auipc	ra,0x0
    80001248:	f22080e7          	jalr	-222(ra) # 80001166 <kvmmake>
    8000124c:	00007797          	auipc	a5,0x7
    80001250:	66a7b223          	sd	a0,1636(a5) # 800088b0 <kernel_pagetable>
}
    80001254:	60a2                	ld	ra,8(sp)
    80001256:	6402                	ld	s0,0(sp)
    80001258:	0141                	add	sp,sp,16
    8000125a:	8082                	ret

000000008000125c <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    8000125c:	715d                	add	sp,sp,-80
    8000125e:	e486                	sd	ra,72(sp)
    80001260:	e0a2                	sd	s0,64(sp)
    80001262:	fc26                	sd	s1,56(sp)
    80001264:	f84a                	sd	s2,48(sp)
    80001266:	f44e                	sd	s3,40(sp)
    80001268:	f052                	sd	s4,32(sp)
    8000126a:	ec56                	sd	s5,24(sp)
    8000126c:	e85a                	sd	s6,16(sp)
    8000126e:	e45e                	sd	s7,8(sp)
    80001270:	0880                	add	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001272:	03459793          	sll	a5,a1,0x34
    80001276:	e795                	bnez	a5,800012a2 <uvmunmap+0x46>
    80001278:	8a2a                	mv	s4,a0
    8000127a:	892e                	mv	s2,a1
    8000127c:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000127e:	0632                	sll	a2,a2,0xc
    80001280:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001284:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001286:	6b05                	lui	s6,0x1
    80001288:	0735e263          	bltu	a1,s3,800012ec <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    8000128c:	60a6                	ld	ra,72(sp)
    8000128e:	6406                	ld	s0,64(sp)
    80001290:	74e2                	ld	s1,56(sp)
    80001292:	7942                	ld	s2,48(sp)
    80001294:	79a2                	ld	s3,40(sp)
    80001296:	7a02                	ld	s4,32(sp)
    80001298:	6ae2                	ld	s5,24(sp)
    8000129a:	6b42                	ld	s6,16(sp)
    8000129c:	6ba2                	ld	s7,8(sp)
    8000129e:	6161                	add	sp,sp,80
    800012a0:	8082                	ret
    panic("uvmunmap: not aligned");
    800012a2:	00007517          	auipc	a0,0x7
    800012a6:	e5e50513          	add	a0,a0,-418 # 80008100 <digits+0xc0>
    800012aa:	fffff097          	auipc	ra,0xfffff
    800012ae:	290080e7          	jalr	656(ra) # 8000053a <panic>
      panic("uvmunmap: walk");
    800012b2:	00007517          	auipc	a0,0x7
    800012b6:	e6650513          	add	a0,a0,-410 # 80008118 <digits+0xd8>
    800012ba:	fffff097          	auipc	ra,0xfffff
    800012be:	280080e7          	jalr	640(ra) # 8000053a <panic>
      panic("uvmunmap: not mapped");
    800012c2:	00007517          	auipc	a0,0x7
    800012c6:	e6650513          	add	a0,a0,-410 # 80008128 <digits+0xe8>
    800012ca:	fffff097          	auipc	ra,0xfffff
    800012ce:	270080e7          	jalr	624(ra) # 8000053a <panic>
      panic("uvmunmap: not a leaf");
    800012d2:	00007517          	auipc	a0,0x7
    800012d6:	e6e50513          	add	a0,a0,-402 # 80008140 <digits+0x100>
    800012da:	fffff097          	auipc	ra,0xfffff
    800012de:	260080e7          	jalr	608(ra) # 8000053a <panic>
    *pte = 0;
    800012e2:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012e6:	995a                	add	s2,s2,s6
    800012e8:	fb3972e3          	bgeu	s2,s3,8000128c <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012ec:	4601                	li	a2,0
    800012ee:	85ca                	mv	a1,s2
    800012f0:	8552                	mv	a0,s4
    800012f2:	00000097          	auipc	ra,0x0
    800012f6:	cbc080e7          	jalr	-836(ra) # 80000fae <walk>
    800012fa:	84aa                	mv	s1,a0
    800012fc:	d95d                	beqz	a0,800012b2 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800012fe:	6108                	ld	a0,0(a0)
    80001300:	00157793          	and	a5,a0,1
    80001304:	dfdd                	beqz	a5,800012c2 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001306:	3ff57793          	and	a5,a0,1023
    8000130a:	fd7784e3          	beq	a5,s7,800012d2 <uvmunmap+0x76>
    if(do_free){
    8000130e:	fc0a8ae3          	beqz	s5,800012e2 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    80001312:	8129                	srl	a0,a0,0xa
      kfree((void*)pa);
    80001314:	0532                	sll	a0,a0,0xc
    80001316:	fffff097          	auipc	ra,0xfffff
    8000131a:	6cc080e7          	jalr	1740(ra) # 800009e2 <kfree>
    8000131e:	b7d1                	j	800012e2 <uvmunmap+0x86>

0000000080001320 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001320:	1101                	add	sp,sp,-32
    80001322:	ec06                	sd	ra,24(sp)
    80001324:	e822                	sd	s0,16(sp)
    80001326:	e426                	sd	s1,8(sp)
    80001328:	1000                	add	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000132a:	fffff097          	auipc	ra,0xfffff
    8000132e:	7b6080e7          	jalr	1974(ra) # 80000ae0 <kalloc>
    80001332:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001334:	c519                	beqz	a0,80001342 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001336:	6605                	lui	a2,0x1
    80001338:	4581                	li	a1,0
    8000133a:	00000097          	auipc	ra,0x0
    8000133e:	992080e7          	jalr	-1646(ra) # 80000ccc <memset>
  return pagetable;
}
    80001342:	8526                	mv	a0,s1
    80001344:	60e2                	ld	ra,24(sp)
    80001346:	6442                	ld	s0,16(sp)
    80001348:	64a2                	ld	s1,8(sp)
    8000134a:	6105                	add	sp,sp,32
    8000134c:	8082                	ret

000000008000134e <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    8000134e:	7179                	add	sp,sp,-48
    80001350:	f406                	sd	ra,40(sp)
    80001352:	f022                	sd	s0,32(sp)
    80001354:	ec26                	sd	s1,24(sp)
    80001356:	e84a                	sd	s2,16(sp)
    80001358:	e44e                	sd	s3,8(sp)
    8000135a:	e052                	sd	s4,0(sp)
    8000135c:	1800                	add	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    8000135e:	6785                	lui	a5,0x1
    80001360:	04f67863          	bgeu	a2,a5,800013b0 <uvmfirst+0x62>
    80001364:	8a2a                	mv	s4,a0
    80001366:	89ae                	mv	s3,a1
    80001368:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    8000136a:	fffff097          	auipc	ra,0xfffff
    8000136e:	776080e7          	jalr	1910(ra) # 80000ae0 <kalloc>
    80001372:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001374:	6605                	lui	a2,0x1
    80001376:	4581                	li	a1,0
    80001378:	00000097          	auipc	ra,0x0
    8000137c:	954080e7          	jalr	-1708(ra) # 80000ccc <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001380:	4779                	li	a4,30
    80001382:	86ca                	mv	a3,s2
    80001384:	6605                	lui	a2,0x1
    80001386:	4581                	li	a1,0
    80001388:	8552                	mv	a0,s4
    8000138a:	00000097          	auipc	ra,0x0
    8000138e:	d0c080e7          	jalr	-756(ra) # 80001096 <mappages>
  memmove(mem, src, sz);
    80001392:	8626                	mv	a2,s1
    80001394:	85ce                	mv	a1,s3
    80001396:	854a                	mv	a0,s2
    80001398:	00000097          	auipc	ra,0x0
    8000139c:	990080e7          	jalr	-1648(ra) # 80000d28 <memmove>
}
    800013a0:	70a2                	ld	ra,40(sp)
    800013a2:	7402                	ld	s0,32(sp)
    800013a4:	64e2                	ld	s1,24(sp)
    800013a6:	6942                	ld	s2,16(sp)
    800013a8:	69a2                	ld	s3,8(sp)
    800013aa:	6a02                	ld	s4,0(sp)
    800013ac:	6145                	add	sp,sp,48
    800013ae:	8082                	ret
    panic("uvmfirst: more than a page");
    800013b0:	00007517          	auipc	a0,0x7
    800013b4:	da850513          	add	a0,a0,-600 # 80008158 <digits+0x118>
    800013b8:	fffff097          	auipc	ra,0xfffff
    800013bc:	182080e7          	jalr	386(ra) # 8000053a <panic>

00000000800013c0 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013c0:	1101                	add	sp,sp,-32
    800013c2:	ec06                	sd	ra,24(sp)
    800013c4:	e822                	sd	s0,16(sp)
    800013c6:	e426                	sd	s1,8(sp)
    800013c8:	1000                	add	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013ca:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013cc:	00b67d63          	bgeu	a2,a1,800013e6 <uvmdealloc+0x26>
    800013d0:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013d2:	6785                	lui	a5,0x1
    800013d4:	17fd                	add	a5,a5,-1 # fff <_entry-0x7ffff001>
    800013d6:	00f60733          	add	a4,a2,a5
    800013da:	76fd                	lui	a3,0xfffff
    800013dc:	8f75                	and	a4,a4,a3
    800013de:	97ae                	add	a5,a5,a1
    800013e0:	8ff5                	and	a5,a5,a3
    800013e2:	00f76863          	bltu	a4,a5,800013f2 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013e6:	8526                	mv	a0,s1
    800013e8:	60e2                	ld	ra,24(sp)
    800013ea:	6442                	ld	s0,16(sp)
    800013ec:	64a2                	ld	s1,8(sp)
    800013ee:	6105                	add	sp,sp,32
    800013f0:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013f2:	8f99                	sub	a5,a5,a4
    800013f4:	83b1                	srl	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013f6:	4685                	li	a3,1
    800013f8:	0007861b          	sext.w	a2,a5
    800013fc:	85ba                	mv	a1,a4
    800013fe:	00000097          	auipc	ra,0x0
    80001402:	e5e080e7          	jalr	-418(ra) # 8000125c <uvmunmap>
    80001406:	b7c5                	j	800013e6 <uvmdealloc+0x26>

0000000080001408 <uvmalloc>:
  if(newsz < oldsz)
    80001408:	0ab66563          	bltu	a2,a1,800014b2 <uvmalloc+0xaa>
{
    8000140c:	7139                	add	sp,sp,-64
    8000140e:	fc06                	sd	ra,56(sp)
    80001410:	f822                	sd	s0,48(sp)
    80001412:	f426                	sd	s1,40(sp)
    80001414:	f04a                	sd	s2,32(sp)
    80001416:	ec4e                	sd	s3,24(sp)
    80001418:	e852                	sd	s4,16(sp)
    8000141a:	e456                	sd	s5,8(sp)
    8000141c:	e05a                	sd	s6,0(sp)
    8000141e:	0080                	add	s0,sp,64
    80001420:	8aaa                	mv	s5,a0
    80001422:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001424:	6785                	lui	a5,0x1
    80001426:	17fd                	add	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001428:	95be                	add	a1,a1,a5
    8000142a:	77fd                	lui	a5,0xfffff
    8000142c:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001430:	08c9f363          	bgeu	s3,a2,800014b6 <uvmalloc+0xae>
    80001434:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001436:	0126eb13          	or	s6,a3,18
    mem = kalloc();
    8000143a:	fffff097          	auipc	ra,0xfffff
    8000143e:	6a6080e7          	jalr	1702(ra) # 80000ae0 <kalloc>
    80001442:	84aa                	mv	s1,a0
    if(mem == 0){
    80001444:	c51d                	beqz	a0,80001472 <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    80001446:	6605                	lui	a2,0x1
    80001448:	4581                	li	a1,0
    8000144a:	00000097          	auipc	ra,0x0
    8000144e:	882080e7          	jalr	-1918(ra) # 80000ccc <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001452:	875a                	mv	a4,s6
    80001454:	86a6                	mv	a3,s1
    80001456:	6605                	lui	a2,0x1
    80001458:	85ca                	mv	a1,s2
    8000145a:	8556                	mv	a0,s5
    8000145c:	00000097          	auipc	ra,0x0
    80001460:	c3a080e7          	jalr	-966(ra) # 80001096 <mappages>
    80001464:	e90d                	bnez	a0,80001496 <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001466:	6785                	lui	a5,0x1
    80001468:	993e                	add	s2,s2,a5
    8000146a:	fd4968e3          	bltu	s2,s4,8000143a <uvmalloc+0x32>
  return newsz;
    8000146e:	8552                	mv	a0,s4
    80001470:	a809                	j	80001482 <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    80001472:	864e                	mv	a2,s3
    80001474:	85ca                	mv	a1,s2
    80001476:	8556                	mv	a0,s5
    80001478:	00000097          	auipc	ra,0x0
    8000147c:	f48080e7          	jalr	-184(ra) # 800013c0 <uvmdealloc>
      return 0;
    80001480:	4501                	li	a0,0
}
    80001482:	70e2                	ld	ra,56(sp)
    80001484:	7442                	ld	s0,48(sp)
    80001486:	74a2                	ld	s1,40(sp)
    80001488:	7902                	ld	s2,32(sp)
    8000148a:	69e2                	ld	s3,24(sp)
    8000148c:	6a42                	ld	s4,16(sp)
    8000148e:	6aa2                	ld	s5,8(sp)
    80001490:	6b02                	ld	s6,0(sp)
    80001492:	6121                	add	sp,sp,64
    80001494:	8082                	ret
      kfree(mem);
    80001496:	8526                	mv	a0,s1
    80001498:	fffff097          	auipc	ra,0xfffff
    8000149c:	54a080e7          	jalr	1354(ra) # 800009e2 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014a0:	864e                	mv	a2,s3
    800014a2:	85ca                	mv	a1,s2
    800014a4:	8556                	mv	a0,s5
    800014a6:	00000097          	auipc	ra,0x0
    800014aa:	f1a080e7          	jalr	-230(ra) # 800013c0 <uvmdealloc>
      return 0;
    800014ae:	4501                	li	a0,0
    800014b0:	bfc9                	j	80001482 <uvmalloc+0x7a>
    return oldsz;
    800014b2:	852e                	mv	a0,a1
}
    800014b4:	8082                	ret
  return newsz;
    800014b6:	8532                	mv	a0,a2
    800014b8:	b7e9                	j	80001482 <uvmalloc+0x7a>

00000000800014ba <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014ba:	7179                	add	sp,sp,-48
    800014bc:	f406                	sd	ra,40(sp)
    800014be:	f022                	sd	s0,32(sp)
    800014c0:	ec26                	sd	s1,24(sp)
    800014c2:	e84a                	sd	s2,16(sp)
    800014c4:	e44e                	sd	s3,8(sp)
    800014c6:	e052                	sd	s4,0(sp)
    800014c8:	1800                	add	s0,sp,48
    800014ca:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014cc:	84aa                	mv	s1,a0
    800014ce:	6905                	lui	s2,0x1
    800014d0:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014d2:	4985                	li	s3,1
    800014d4:	a829                	j	800014ee <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014d6:	83a9                	srl	a5,a5,0xa
      freewalk((pagetable_t)child);
    800014d8:	00c79513          	sll	a0,a5,0xc
    800014dc:	00000097          	auipc	ra,0x0
    800014e0:	fde080e7          	jalr	-34(ra) # 800014ba <freewalk>
      pagetable[i] = 0;
    800014e4:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014e8:	04a1                	add	s1,s1,8
    800014ea:	03248163          	beq	s1,s2,8000150c <freewalk+0x52>
    pte_t pte = pagetable[i];
    800014ee:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014f0:	00f7f713          	and	a4,a5,15
    800014f4:	ff3701e3          	beq	a4,s3,800014d6 <freewalk+0x1c>
    } else if(pte & PTE_V){
    800014f8:	8b85                	and	a5,a5,1
    800014fa:	d7fd                	beqz	a5,800014e8 <freewalk+0x2e>
      panic("freewalk: leaf");
    800014fc:	00007517          	auipc	a0,0x7
    80001500:	c7c50513          	add	a0,a0,-900 # 80008178 <digits+0x138>
    80001504:	fffff097          	auipc	ra,0xfffff
    80001508:	036080e7          	jalr	54(ra) # 8000053a <panic>
    }
  }
  kfree((void*)pagetable);
    8000150c:	8552                	mv	a0,s4
    8000150e:	fffff097          	auipc	ra,0xfffff
    80001512:	4d4080e7          	jalr	1236(ra) # 800009e2 <kfree>
}
    80001516:	70a2                	ld	ra,40(sp)
    80001518:	7402                	ld	s0,32(sp)
    8000151a:	64e2                	ld	s1,24(sp)
    8000151c:	6942                	ld	s2,16(sp)
    8000151e:	69a2                	ld	s3,8(sp)
    80001520:	6a02                	ld	s4,0(sp)
    80001522:	6145                	add	sp,sp,48
    80001524:	8082                	ret

0000000080001526 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001526:	1101                	add	sp,sp,-32
    80001528:	ec06                	sd	ra,24(sp)
    8000152a:	e822                	sd	s0,16(sp)
    8000152c:	e426                	sd	s1,8(sp)
    8000152e:	1000                	add	s0,sp,32
    80001530:	84aa                	mv	s1,a0
  if(sz > 0)
    80001532:	e999                	bnez	a1,80001548 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001534:	8526                	mv	a0,s1
    80001536:	00000097          	auipc	ra,0x0
    8000153a:	f84080e7          	jalr	-124(ra) # 800014ba <freewalk>
}
    8000153e:	60e2                	ld	ra,24(sp)
    80001540:	6442                	ld	s0,16(sp)
    80001542:	64a2                	ld	s1,8(sp)
    80001544:	6105                	add	sp,sp,32
    80001546:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001548:	6785                	lui	a5,0x1
    8000154a:	17fd                	add	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000154c:	95be                	add	a1,a1,a5
    8000154e:	4685                	li	a3,1
    80001550:	00c5d613          	srl	a2,a1,0xc
    80001554:	4581                	li	a1,0
    80001556:	00000097          	auipc	ra,0x0
    8000155a:	d06080e7          	jalr	-762(ra) # 8000125c <uvmunmap>
    8000155e:	bfd9                	j	80001534 <uvmfree+0xe>

0000000080001560 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001560:	c679                	beqz	a2,8000162e <uvmcopy+0xce>
{
    80001562:	715d                	add	sp,sp,-80
    80001564:	e486                	sd	ra,72(sp)
    80001566:	e0a2                	sd	s0,64(sp)
    80001568:	fc26                	sd	s1,56(sp)
    8000156a:	f84a                	sd	s2,48(sp)
    8000156c:	f44e                	sd	s3,40(sp)
    8000156e:	f052                	sd	s4,32(sp)
    80001570:	ec56                	sd	s5,24(sp)
    80001572:	e85a                	sd	s6,16(sp)
    80001574:	e45e                	sd	s7,8(sp)
    80001576:	0880                	add	s0,sp,80
    80001578:	8b2a                	mv	s6,a0
    8000157a:	8aae                	mv	s5,a1
    8000157c:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000157e:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001580:	4601                	li	a2,0
    80001582:	85ce                	mv	a1,s3
    80001584:	855a                	mv	a0,s6
    80001586:	00000097          	auipc	ra,0x0
    8000158a:	a28080e7          	jalr	-1496(ra) # 80000fae <walk>
    8000158e:	c531                	beqz	a0,800015da <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001590:	6118                	ld	a4,0(a0)
    80001592:	00177793          	and	a5,a4,1
    80001596:	cbb1                	beqz	a5,800015ea <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001598:	00a75593          	srl	a1,a4,0xa
    8000159c:	00c59b93          	sll	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015a0:	3ff77493          	and	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015a4:	fffff097          	auipc	ra,0xfffff
    800015a8:	53c080e7          	jalr	1340(ra) # 80000ae0 <kalloc>
    800015ac:	892a                	mv	s2,a0
    800015ae:	c939                	beqz	a0,80001604 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015b0:	6605                	lui	a2,0x1
    800015b2:	85de                	mv	a1,s7
    800015b4:	fffff097          	auipc	ra,0xfffff
    800015b8:	774080e7          	jalr	1908(ra) # 80000d28 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015bc:	8726                	mv	a4,s1
    800015be:	86ca                	mv	a3,s2
    800015c0:	6605                	lui	a2,0x1
    800015c2:	85ce                	mv	a1,s3
    800015c4:	8556                	mv	a0,s5
    800015c6:	00000097          	auipc	ra,0x0
    800015ca:	ad0080e7          	jalr	-1328(ra) # 80001096 <mappages>
    800015ce:	e515                	bnez	a0,800015fa <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015d0:	6785                	lui	a5,0x1
    800015d2:	99be                	add	s3,s3,a5
    800015d4:	fb49e6e3          	bltu	s3,s4,80001580 <uvmcopy+0x20>
    800015d8:	a081                	j	80001618 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015da:	00007517          	auipc	a0,0x7
    800015de:	bae50513          	add	a0,a0,-1106 # 80008188 <digits+0x148>
    800015e2:	fffff097          	auipc	ra,0xfffff
    800015e6:	f58080e7          	jalr	-168(ra) # 8000053a <panic>
      panic("uvmcopy: page not present");
    800015ea:	00007517          	auipc	a0,0x7
    800015ee:	bbe50513          	add	a0,a0,-1090 # 800081a8 <digits+0x168>
    800015f2:	fffff097          	auipc	ra,0xfffff
    800015f6:	f48080e7          	jalr	-184(ra) # 8000053a <panic>
      kfree(mem);
    800015fa:	854a                	mv	a0,s2
    800015fc:	fffff097          	auipc	ra,0xfffff
    80001600:	3e6080e7          	jalr	998(ra) # 800009e2 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001604:	4685                	li	a3,1
    80001606:	00c9d613          	srl	a2,s3,0xc
    8000160a:	4581                	li	a1,0
    8000160c:	8556                	mv	a0,s5
    8000160e:	00000097          	auipc	ra,0x0
    80001612:	c4e080e7          	jalr	-946(ra) # 8000125c <uvmunmap>
  return -1;
    80001616:	557d                	li	a0,-1
}
    80001618:	60a6                	ld	ra,72(sp)
    8000161a:	6406                	ld	s0,64(sp)
    8000161c:	74e2                	ld	s1,56(sp)
    8000161e:	7942                	ld	s2,48(sp)
    80001620:	79a2                	ld	s3,40(sp)
    80001622:	7a02                	ld	s4,32(sp)
    80001624:	6ae2                	ld	s5,24(sp)
    80001626:	6b42                	ld	s6,16(sp)
    80001628:	6ba2                	ld	s7,8(sp)
    8000162a:	6161                	add	sp,sp,80
    8000162c:	8082                	ret
  return 0;
    8000162e:	4501                	li	a0,0
}
    80001630:	8082                	ret

0000000080001632 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001632:	1141                	add	sp,sp,-16
    80001634:	e406                	sd	ra,8(sp)
    80001636:	e022                	sd	s0,0(sp)
    80001638:	0800                	add	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000163a:	4601                	li	a2,0
    8000163c:	00000097          	auipc	ra,0x0
    80001640:	972080e7          	jalr	-1678(ra) # 80000fae <walk>
  if(pte == 0)
    80001644:	c901                	beqz	a0,80001654 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001646:	611c                	ld	a5,0(a0)
    80001648:	9bbd                	and	a5,a5,-17
    8000164a:	e11c                	sd	a5,0(a0)
}
    8000164c:	60a2                	ld	ra,8(sp)
    8000164e:	6402                	ld	s0,0(sp)
    80001650:	0141                	add	sp,sp,16
    80001652:	8082                	ret
    panic("uvmclear");
    80001654:	00007517          	auipc	a0,0x7
    80001658:	b7450513          	add	a0,a0,-1164 # 800081c8 <digits+0x188>
    8000165c:	fffff097          	auipc	ra,0xfffff
    80001660:	ede080e7          	jalr	-290(ra) # 8000053a <panic>

0000000080001664 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001664:	c6bd                	beqz	a3,800016d2 <copyout+0x6e>
{
    80001666:	715d                	add	sp,sp,-80
    80001668:	e486                	sd	ra,72(sp)
    8000166a:	e0a2                	sd	s0,64(sp)
    8000166c:	fc26                	sd	s1,56(sp)
    8000166e:	f84a                	sd	s2,48(sp)
    80001670:	f44e                	sd	s3,40(sp)
    80001672:	f052                	sd	s4,32(sp)
    80001674:	ec56                	sd	s5,24(sp)
    80001676:	e85a                	sd	s6,16(sp)
    80001678:	e45e                	sd	s7,8(sp)
    8000167a:	e062                	sd	s8,0(sp)
    8000167c:	0880                	add	s0,sp,80
    8000167e:	8b2a                	mv	s6,a0
    80001680:	8c2e                	mv	s8,a1
    80001682:	8a32                	mv	s4,a2
    80001684:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001686:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001688:	6a85                	lui	s5,0x1
    8000168a:	a015                	j	800016ae <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000168c:	9562                	add	a0,a0,s8
    8000168e:	0004861b          	sext.w	a2,s1
    80001692:	85d2                	mv	a1,s4
    80001694:	41250533          	sub	a0,a0,s2
    80001698:	fffff097          	auipc	ra,0xfffff
    8000169c:	690080e7          	jalr	1680(ra) # 80000d28 <memmove>

    len -= n;
    800016a0:	409989b3          	sub	s3,s3,s1
    src += n;
    800016a4:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016a6:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016aa:	02098263          	beqz	s3,800016ce <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016ae:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016b2:	85ca                	mv	a1,s2
    800016b4:	855a                	mv	a0,s6
    800016b6:	00000097          	auipc	ra,0x0
    800016ba:	99e080e7          	jalr	-1634(ra) # 80001054 <walkaddr>
    if(pa0 == 0)
    800016be:	cd01                	beqz	a0,800016d6 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016c0:	418904b3          	sub	s1,s2,s8
    800016c4:	94d6                	add	s1,s1,s5
    800016c6:	fc99f3e3          	bgeu	s3,s1,8000168c <copyout+0x28>
    800016ca:	84ce                	mv	s1,s3
    800016cc:	b7c1                	j	8000168c <copyout+0x28>
  }
  return 0;
    800016ce:	4501                	li	a0,0
    800016d0:	a021                	j	800016d8 <copyout+0x74>
    800016d2:	4501                	li	a0,0
}
    800016d4:	8082                	ret
      return -1;
    800016d6:	557d                	li	a0,-1
}
    800016d8:	60a6                	ld	ra,72(sp)
    800016da:	6406                	ld	s0,64(sp)
    800016dc:	74e2                	ld	s1,56(sp)
    800016de:	7942                	ld	s2,48(sp)
    800016e0:	79a2                	ld	s3,40(sp)
    800016e2:	7a02                	ld	s4,32(sp)
    800016e4:	6ae2                	ld	s5,24(sp)
    800016e6:	6b42                	ld	s6,16(sp)
    800016e8:	6ba2                	ld	s7,8(sp)
    800016ea:	6c02                	ld	s8,0(sp)
    800016ec:	6161                	add	sp,sp,80
    800016ee:	8082                	ret

00000000800016f0 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016f0:	caa5                	beqz	a3,80001760 <copyin+0x70>
{
    800016f2:	715d                	add	sp,sp,-80
    800016f4:	e486                	sd	ra,72(sp)
    800016f6:	e0a2                	sd	s0,64(sp)
    800016f8:	fc26                	sd	s1,56(sp)
    800016fa:	f84a                	sd	s2,48(sp)
    800016fc:	f44e                	sd	s3,40(sp)
    800016fe:	f052                	sd	s4,32(sp)
    80001700:	ec56                	sd	s5,24(sp)
    80001702:	e85a                	sd	s6,16(sp)
    80001704:	e45e                	sd	s7,8(sp)
    80001706:	e062                	sd	s8,0(sp)
    80001708:	0880                	add	s0,sp,80
    8000170a:	8b2a                	mv	s6,a0
    8000170c:	8a2e                	mv	s4,a1
    8000170e:	8c32                	mv	s8,a2
    80001710:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001712:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001714:	6a85                	lui	s5,0x1
    80001716:	a01d                	j	8000173c <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001718:	018505b3          	add	a1,a0,s8
    8000171c:	0004861b          	sext.w	a2,s1
    80001720:	412585b3          	sub	a1,a1,s2
    80001724:	8552                	mv	a0,s4
    80001726:	fffff097          	auipc	ra,0xfffff
    8000172a:	602080e7          	jalr	1538(ra) # 80000d28 <memmove>

    len -= n;
    8000172e:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001732:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001734:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001738:	02098263          	beqz	s3,8000175c <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    8000173c:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001740:	85ca                	mv	a1,s2
    80001742:	855a                	mv	a0,s6
    80001744:	00000097          	auipc	ra,0x0
    80001748:	910080e7          	jalr	-1776(ra) # 80001054 <walkaddr>
    if(pa0 == 0)
    8000174c:	cd01                	beqz	a0,80001764 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    8000174e:	418904b3          	sub	s1,s2,s8
    80001752:	94d6                	add	s1,s1,s5
    80001754:	fc99f2e3          	bgeu	s3,s1,80001718 <copyin+0x28>
    80001758:	84ce                	mv	s1,s3
    8000175a:	bf7d                	j	80001718 <copyin+0x28>
  }
  return 0;
    8000175c:	4501                	li	a0,0
    8000175e:	a021                	j	80001766 <copyin+0x76>
    80001760:	4501                	li	a0,0
}
    80001762:	8082                	ret
      return -1;
    80001764:	557d                	li	a0,-1
}
    80001766:	60a6                	ld	ra,72(sp)
    80001768:	6406                	ld	s0,64(sp)
    8000176a:	74e2                	ld	s1,56(sp)
    8000176c:	7942                	ld	s2,48(sp)
    8000176e:	79a2                	ld	s3,40(sp)
    80001770:	7a02                	ld	s4,32(sp)
    80001772:	6ae2                	ld	s5,24(sp)
    80001774:	6b42                	ld	s6,16(sp)
    80001776:	6ba2                	ld	s7,8(sp)
    80001778:	6c02                	ld	s8,0(sp)
    8000177a:	6161                	add	sp,sp,80
    8000177c:	8082                	ret

000000008000177e <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000177e:	c2dd                	beqz	a3,80001824 <copyinstr+0xa6>
{
    80001780:	715d                	add	sp,sp,-80
    80001782:	e486                	sd	ra,72(sp)
    80001784:	e0a2                	sd	s0,64(sp)
    80001786:	fc26                	sd	s1,56(sp)
    80001788:	f84a                	sd	s2,48(sp)
    8000178a:	f44e                	sd	s3,40(sp)
    8000178c:	f052                	sd	s4,32(sp)
    8000178e:	ec56                	sd	s5,24(sp)
    80001790:	e85a                	sd	s6,16(sp)
    80001792:	e45e                	sd	s7,8(sp)
    80001794:	0880                	add	s0,sp,80
    80001796:	8a2a                	mv	s4,a0
    80001798:	8b2e                	mv	s6,a1
    8000179a:	8bb2                	mv	s7,a2
    8000179c:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    8000179e:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017a0:	6985                	lui	s3,0x1
    800017a2:	a02d                	j	800017cc <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017a4:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017a8:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017aa:	37fd                	addw	a5,a5,-1
    800017ac:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017b0:	60a6                	ld	ra,72(sp)
    800017b2:	6406                	ld	s0,64(sp)
    800017b4:	74e2                	ld	s1,56(sp)
    800017b6:	7942                	ld	s2,48(sp)
    800017b8:	79a2                	ld	s3,40(sp)
    800017ba:	7a02                	ld	s4,32(sp)
    800017bc:	6ae2                	ld	s5,24(sp)
    800017be:	6b42                	ld	s6,16(sp)
    800017c0:	6ba2                	ld	s7,8(sp)
    800017c2:	6161                	add	sp,sp,80
    800017c4:	8082                	ret
    srcva = va0 + PGSIZE;
    800017c6:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017ca:	c8a9                	beqz	s1,8000181c <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    800017cc:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017d0:	85ca                	mv	a1,s2
    800017d2:	8552                	mv	a0,s4
    800017d4:	00000097          	auipc	ra,0x0
    800017d8:	880080e7          	jalr	-1920(ra) # 80001054 <walkaddr>
    if(pa0 == 0)
    800017dc:	c131                	beqz	a0,80001820 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    800017de:	417906b3          	sub	a3,s2,s7
    800017e2:	96ce                	add	a3,a3,s3
    800017e4:	00d4f363          	bgeu	s1,a3,800017ea <copyinstr+0x6c>
    800017e8:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017ea:	955e                	add	a0,a0,s7
    800017ec:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017f0:	daf9                	beqz	a3,800017c6 <copyinstr+0x48>
    800017f2:	87da                	mv	a5,s6
    800017f4:	885a                	mv	a6,s6
      if(*p == '\0'){
    800017f6:	41650633          	sub	a2,a0,s6
    while(n > 0){
    800017fa:	96da                	add	a3,a3,s6
    800017fc:	85be                	mv	a1,a5
      if(*p == '\0'){
    800017fe:	00f60733          	add	a4,a2,a5
    80001802:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffdd2c0>
    80001806:	df59                	beqz	a4,800017a4 <copyinstr+0x26>
        *dst = *p;
    80001808:	00e78023          	sb	a4,0(a5)
      dst++;
    8000180c:	0785                	add	a5,a5,1
    while(n > 0){
    8000180e:	fed797e3          	bne	a5,a3,800017fc <copyinstr+0x7e>
    80001812:	14fd                	add	s1,s1,-1
    80001814:	94c2                	add	s1,s1,a6
      --max;
    80001816:	8c8d                	sub	s1,s1,a1
      dst++;
    80001818:	8b3e                	mv	s6,a5
    8000181a:	b775                	j	800017c6 <copyinstr+0x48>
    8000181c:	4781                	li	a5,0
    8000181e:	b771                	j	800017aa <copyinstr+0x2c>
      return -1;
    80001820:	557d                	li	a0,-1
    80001822:	b779                	j	800017b0 <copyinstr+0x32>
  int got_null = 0;
    80001824:	4781                	li	a5,0
  if(got_null){
    80001826:	37fd                	addw	a5,a5,-1
    80001828:	0007851b          	sext.w	a0,a5
}
    8000182c:	8082                	ret

000000008000182e <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    8000182e:	7139                	add	sp,sp,-64
    80001830:	fc06                	sd	ra,56(sp)
    80001832:	f822                	sd	s0,48(sp)
    80001834:	f426                	sd	s1,40(sp)
    80001836:	f04a                	sd	s2,32(sp)
    80001838:	ec4e                	sd	s3,24(sp)
    8000183a:	e852                	sd	s4,16(sp)
    8000183c:	e456                	sd	s5,8(sp)
    8000183e:	e05a                	sd	s6,0(sp)
    80001840:	0080                	add	s0,sp,64
    80001842:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001844:	0000f497          	auipc	s1,0xf
    80001848:	71c48493          	add	s1,s1,1820 # 80010f60 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    8000184c:	8b26                	mv	s6,s1
    8000184e:	00006a97          	auipc	s5,0x6
    80001852:	7b2a8a93          	add	s5,s5,1970 # 80008000 <etext>
    80001856:	04000937          	lui	s2,0x4000
    8000185a:	197d                	add	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    8000185c:	0932                	sll	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000185e:	00015a17          	auipc	s4,0x15
    80001862:	102a0a13          	add	s4,s4,258 # 80016960 <tickslock>
    char *pa = kalloc();
    80001866:	fffff097          	auipc	ra,0xfffff
    8000186a:	27a080e7          	jalr	634(ra) # 80000ae0 <kalloc>
    8000186e:	862a                	mv	a2,a0
    if(pa == 0)
    80001870:	c131                	beqz	a0,800018b4 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001872:	416485b3          	sub	a1,s1,s6
    80001876:	858d                	sra	a1,a1,0x3
    80001878:	000ab783          	ld	a5,0(s5)
    8000187c:	02f585b3          	mul	a1,a1,a5
    80001880:	2585                	addw	a1,a1,1
    80001882:	00d5959b          	sllw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001886:	4719                	li	a4,6
    80001888:	6685                	lui	a3,0x1
    8000188a:	40b905b3          	sub	a1,s2,a1
    8000188e:	854e                	mv	a0,s3
    80001890:	00000097          	auipc	ra,0x0
    80001894:	8a6080e7          	jalr	-1882(ra) # 80001136 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001898:	16848493          	add	s1,s1,360
    8000189c:	fd4495e3          	bne	s1,s4,80001866 <proc_mapstacks+0x38>
  }
}
    800018a0:	70e2                	ld	ra,56(sp)
    800018a2:	7442                	ld	s0,48(sp)
    800018a4:	74a2                	ld	s1,40(sp)
    800018a6:	7902                	ld	s2,32(sp)
    800018a8:	69e2                	ld	s3,24(sp)
    800018aa:	6a42                	ld	s4,16(sp)
    800018ac:	6aa2                	ld	s5,8(sp)
    800018ae:	6b02                	ld	s6,0(sp)
    800018b0:	6121                	add	sp,sp,64
    800018b2:	8082                	ret
      panic("kalloc");
    800018b4:	00007517          	auipc	a0,0x7
    800018b8:	92450513          	add	a0,a0,-1756 # 800081d8 <digits+0x198>
    800018bc:	fffff097          	auipc	ra,0xfffff
    800018c0:	c7e080e7          	jalr	-898(ra) # 8000053a <panic>

00000000800018c4 <procinit>:

// initialize the proc table.
void
procinit(void)
{
    800018c4:	7139                	add	sp,sp,-64
    800018c6:	fc06                	sd	ra,56(sp)
    800018c8:	f822                	sd	s0,48(sp)
    800018ca:	f426                	sd	s1,40(sp)
    800018cc:	f04a                	sd	s2,32(sp)
    800018ce:	ec4e                	sd	s3,24(sp)
    800018d0:	e852                	sd	s4,16(sp)
    800018d2:	e456                	sd	s5,8(sp)
    800018d4:	e05a                	sd	s6,0(sp)
    800018d6:	0080                	add	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800018d8:	00007597          	auipc	a1,0x7
    800018dc:	90858593          	add	a1,a1,-1784 # 800081e0 <digits+0x1a0>
    800018e0:	0000f517          	auipc	a0,0xf
    800018e4:	25050513          	add	a0,a0,592 # 80010b30 <pid_lock>
    800018e8:	fffff097          	auipc	ra,0xfffff
    800018ec:	258080e7          	jalr	600(ra) # 80000b40 <initlock>
  initlock(&wait_lock, "wait_lock");
    800018f0:	00007597          	auipc	a1,0x7
    800018f4:	8f858593          	add	a1,a1,-1800 # 800081e8 <digits+0x1a8>
    800018f8:	0000f517          	auipc	a0,0xf
    800018fc:	25050513          	add	a0,a0,592 # 80010b48 <wait_lock>
    80001900:	fffff097          	auipc	ra,0xfffff
    80001904:	240080e7          	jalr	576(ra) # 80000b40 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001908:	0000f497          	auipc	s1,0xf
    8000190c:	65848493          	add	s1,s1,1624 # 80010f60 <proc>
      initlock(&p->lock, "proc");
    80001910:	00007b17          	auipc	s6,0x7
    80001914:	8e8b0b13          	add	s6,s6,-1816 # 800081f8 <digits+0x1b8>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    80001918:	8aa6                	mv	s5,s1
    8000191a:	00006a17          	auipc	s4,0x6
    8000191e:	6e6a0a13          	add	s4,s4,1766 # 80008000 <etext>
    80001922:	04000937          	lui	s2,0x4000
    80001926:	197d                	add	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001928:	0932                	sll	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000192a:	00015997          	auipc	s3,0x15
    8000192e:	03698993          	add	s3,s3,54 # 80016960 <tickslock>
      initlock(&p->lock, "proc");
    80001932:	85da                	mv	a1,s6
    80001934:	8526                	mv	a0,s1
    80001936:	fffff097          	auipc	ra,0xfffff
    8000193a:	20a080e7          	jalr	522(ra) # 80000b40 <initlock>
      p->state = UNUSED;
    8000193e:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    80001942:	415487b3          	sub	a5,s1,s5
    80001946:	878d                	sra	a5,a5,0x3
    80001948:	000a3703          	ld	a4,0(s4)
    8000194c:	02e787b3          	mul	a5,a5,a4
    80001950:	2785                	addw	a5,a5,1
    80001952:	00d7979b          	sllw	a5,a5,0xd
    80001956:	40f907b3          	sub	a5,s2,a5
    8000195a:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    8000195c:	16848493          	add	s1,s1,360
    80001960:	fd3499e3          	bne	s1,s3,80001932 <procinit+0x6e>
  }
}
    80001964:	70e2                	ld	ra,56(sp)
    80001966:	7442                	ld	s0,48(sp)
    80001968:	74a2                	ld	s1,40(sp)
    8000196a:	7902                	ld	s2,32(sp)
    8000196c:	69e2                	ld	s3,24(sp)
    8000196e:	6a42                	ld	s4,16(sp)
    80001970:	6aa2                	ld	s5,8(sp)
    80001972:	6b02                	ld	s6,0(sp)
    80001974:	6121                	add	sp,sp,64
    80001976:	8082                	ret

0000000080001978 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001978:	1141                	add	sp,sp,-16
    8000197a:	e422                	sd	s0,8(sp)
    8000197c:	0800                	add	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    8000197e:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001980:	2501                	sext.w	a0,a0
    80001982:	6422                	ld	s0,8(sp)
    80001984:	0141                	add	sp,sp,16
    80001986:	8082                	ret

0000000080001988 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    80001988:	1141                	add	sp,sp,-16
    8000198a:	e422                	sd	s0,8(sp)
    8000198c:	0800                	add	s0,sp,16
    8000198e:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001990:	2781                	sext.w	a5,a5
    80001992:	079e                	sll	a5,a5,0x7
  return c;
}
    80001994:	0000f517          	auipc	a0,0xf
    80001998:	1cc50513          	add	a0,a0,460 # 80010b60 <cpus>
    8000199c:	953e                	add	a0,a0,a5
    8000199e:	6422                	ld	s0,8(sp)
    800019a0:	0141                	add	sp,sp,16
    800019a2:	8082                	ret

00000000800019a4 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    800019a4:	1101                	add	sp,sp,-32
    800019a6:	ec06                	sd	ra,24(sp)
    800019a8:	e822                	sd	s0,16(sp)
    800019aa:	e426                	sd	s1,8(sp)
    800019ac:	1000                	add	s0,sp,32
  push_off();
    800019ae:	fffff097          	auipc	ra,0xfffff
    800019b2:	1d6080e7          	jalr	470(ra) # 80000b84 <push_off>
    800019b6:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019b8:	2781                	sext.w	a5,a5
    800019ba:	079e                	sll	a5,a5,0x7
    800019bc:	0000f717          	auipc	a4,0xf
    800019c0:	17470713          	add	a4,a4,372 # 80010b30 <pid_lock>
    800019c4:	97ba                	add	a5,a5,a4
    800019c6:	7b84                	ld	s1,48(a5)
  pop_off();
    800019c8:	fffff097          	auipc	ra,0xfffff
    800019cc:	25c080e7          	jalr	604(ra) # 80000c24 <pop_off>
  return p;
}
    800019d0:	8526                	mv	a0,s1
    800019d2:	60e2                	ld	ra,24(sp)
    800019d4:	6442                	ld	s0,16(sp)
    800019d6:	64a2                	ld	s1,8(sp)
    800019d8:	6105                	add	sp,sp,32
    800019da:	8082                	ret

00000000800019dc <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800019dc:	1141                	add	sp,sp,-16
    800019de:	e406                	sd	ra,8(sp)
    800019e0:	e022                	sd	s0,0(sp)
    800019e2:	0800                	add	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019e4:	00000097          	auipc	ra,0x0
    800019e8:	fc0080e7          	jalr	-64(ra) # 800019a4 <myproc>
    800019ec:	fffff097          	auipc	ra,0xfffff
    800019f0:	298080e7          	jalr	664(ra) # 80000c84 <release>

  if (first) {
    800019f4:	00007797          	auipc	a5,0x7
    800019f8:	e4c7a783          	lw	a5,-436(a5) # 80008840 <first.1>
    800019fc:	eb89                	bnez	a5,80001a0e <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    800019fe:	00001097          	auipc	ra,0x1
    80001a02:	c5c080e7          	jalr	-932(ra) # 8000265a <usertrapret>
}
    80001a06:	60a2                	ld	ra,8(sp)
    80001a08:	6402                	ld	s0,0(sp)
    80001a0a:	0141                	add	sp,sp,16
    80001a0c:	8082                	ret
    first = 0;
    80001a0e:	00007797          	auipc	a5,0x7
    80001a12:	e207a923          	sw	zero,-462(a5) # 80008840 <first.1>
    fsinit(ROOTDEV);
    80001a16:	4505                	li	a0,1
    80001a18:	00002097          	auipc	ra,0x2
    80001a1c:	990080e7          	jalr	-1648(ra) # 800033a8 <fsinit>
    80001a20:	bff9                	j	800019fe <forkret+0x22>

0000000080001a22 <allocpid>:
{
    80001a22:	1101                	add	sp,sp,-32
    80001a24:	ec06                	sd	ra,24(sp)
    80001a26:	e822                	sd	s0,16(sp)
    80001a28:	e426                	sd	s1,8(sp)
    80001a2a:	e04a                	sd	s2,0(sp)
    80001a2c:	1000                	add	s0,sp,32
  acquire(&pid_lock);
    80001a2e:	0000f917          	auipc	s2,0xf
    80001a32:	10290913          	add	s2,s2,258 # 80010b30 <pid_lock>
    80001a36:	854a                	mv	a0,s2
    80001a38:	fffff097          	auipc	ra,0xfffff
    80001a3c:	198080e7          	jalr	408(ra) # 80000bd0 <acquire>
  pid = nextpid;
    80001a40:	00007797          	auipc	a5,0x7
    80001a44:	e0478793          	add	a5,a5,-508 # 80008844 <nextpid>
    80001a48:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a4a:	0014871b          	addw	a4,s1,1
    80001a4e:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a50:	854a                	mv	a0,s2
    80001a52:	fffff097          	auipc	ra,0xfffff
    80001a56:	232080e7          	jalr	562(ra) # 80000c84 <release>
}
    80001a5a:	8526                	mv	a0,s1
    80001a5c:	60e2                	ld	ra,24(sp)
    80001a5e:	6442                	ld	s0,16(sp)
    80001a60:	64a2                	ld	s1,8(sp)
    80001a62:	6902                	ld	s2,0(sp)
    80001a64:	6105                	add	sp,sp,32
    80001a66:	8082                	ret

0000000080001a68 <proc_pagetable>:
{
    80001a68:	1101                	add	sp,sp,-32
    80001a6a:	ec06                	sd	ra,24(sp)
    80001a6c:	e822                	sd	s0,16(sp)
    80001a6e:	e426                	sd	s1,8(sp)
    80001a70:	e04a                	sd	s2,0(sp)
    80001a72:	1000                	add	s0,sp,32
    80001a74:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a76:	00000097          	auipc	ra,0x0
    80001a7a:	8aa080e7          	jalr	-1878(ra) # 80001320 <uvmcreate>
    80001a7e:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001a80:	c121                	beqz	a0,80001ac0 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a82:	4729                	li	a4,10
    80001a84:	00005697          	auipc	a3,0x5
    80001a88:	57c68693          	add	a3,a3,1404 # 80007000 <_trampoline>
    80001a8c:	6605                	lui	a2,0x1
    80001a8e:	040005b7          	lui	a1,0x4000
    80001a92:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001a94:	05b2                	sll	a1,a1,0xc
    80001a96:	fffff097          	auipc	ra,0xfffff
    80001a9a:	600080e7          	jalr	1536(ra) # 80001096 <mappages>
    80001a9e:	02054863          	bltz	a0,80001ace <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001aa2:	4719                	li	a4,6
    80001aa4:	05893683          	ld	a3,88(s2)
    80001aa8:	6605                	lui	a2,0x1
    80001aaa:	020005b7          	lui	a1,0x2000
    80001aae:	15fd                	add	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001ab0:	05b6                	sll	a1,a1,0xd
    80001ab2:	8526                	mv	a0,s1
    80001ab4:	fffff097          	auipc	ra,0xfffff
    80001ab8:	5e2080e7          	jalr	1506(ra) # 80001096 <mappages>
    80001abc:	02054163          	bltz	a0,80001ade <proc_pagetable+0x76>
}
    80001ac0:	8526                	mv	a0,s1
    80001ac2:	60e2                	ld	ra,24(sp)
    80001ac4:	6442                	ld	s0,16(sp)
    80001ac6:	64a2                	ld	s1,8(sp)
    80001ac8:	6902                	ld	s2,0(sp)
    80001aca:	6105                	add	sp,sp,32
    80001acc:	8082                	ret
    uvmfree(pagetable, 0);
    80001ace:	4581                	li	a1,0
    80001ad0:	8526                	mv	a0,s1
    80001ad2:	00000097          	auipc	ra,0x0
    80001ad6:	a54080e7          	jalr	-1452(ra) # 80001526 <uvmfree>
    return 0;
    80001ada:	4481                	li	s1,0
    80001adc:	b7d5                	j	80001ac0 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ade:	4681                	li	a3,0
    80001ae0:	4605                	li	a2,1
    80001ae2:	040005b7          	lui	a1,0x4000
    80001ae6:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001ae8:	05b2                	sll	a1,a1,0xc
    80001aea:	8526                	mv	a0,s1
    80001aec:	fffff097          	auipc	ra,0xfffff
    80001af0:	770080e7          	jalr	1904(ra) # 8000125c <uvmunmap>
    uvmfree(pagetable, 0);
    80001af4:	4581                	li	a1,0
    80001af6:	8526                	mv	a0,s1
    80001af8:	00000097          	auipc	ra,0x0
    80001afc:	a2e080e7          	jalr	-1490(ra) # 80001526 <uvmfree>
    return 0;
    80001b00:	4481                	li	s1,0
    80001b02:	bf7d                	j	80001ac0 <proc_pagetable+0x58>

0000000080001b04 <proc_freepagetable>:
{
    80001b04:	1101                	add	sp,sp,-32
    80001b06:	ec06                	sd	ra,24(sp)
    80001b08:	e822                	sd	s0,16(sp)
    80001b0a:	e426                	sd	s1,8(sp)
    80001b0c:	e04a                	sd	s2,0(sp)
    80001b0e:	1000                	add	s0,sp,32
    80001b10:	84aa                	mv	s1,a0
    80001b12:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b14:	4681                	li	a3,0
    80001b16:	4605                	li	a2,1
    80001b18:	040005b7          	lui	a1,0x4000
    80001b1c:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b1e:	05b2                	sll	a1,a1,0xc
    80001b20:	fffff097          	auipc	ra,0xfffff
    80001b24:	73c080e7          	jalr	1852(ra) # 8000125c <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b28:	4681                	li	a3,0
    80001b2a:	4605                	li	a2,1
    80001b2c:	020005b7          	lui	a1,0x2000
    80001b30:	15fd                	add	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b32:	05b6                	sll	a1,a1,0xd
    80001b34:	8526                	mv	a0,s1
    80001b36:	fffff097          	auipc	ra,0xfffff
    80001b3a:	726080e7          	jalr	1830(ra) # 8000125c <uvmunmap>
  uvmfree(pagetable, sz);
    80001b3e:	85ca                	mv	a1,s2
    80001b40:	8526                	mv	a0,s1
    80001b42:	00000097          	auipc	ra,0x0
    80001b46:	9e4080e7          	jalr	-1564(ra) # 80001526 <uvmfree>
}
    80001b4a:	60e2                	ld	ra,24(sp)
    80001b4c:	6442                	ld	s0,16(sp)
    80001b4e:	64a2                	ld	s1,8(sp)
    80001b50:	6902                	ld	s2,0(sp)
    80001b52:	6105                	add	sp,sp,32
    80001b54:	8082                	ret

0000000080001b56 <freeproc>:
{
    80001b56:	1101                	add	sp,sp,-32
    80001b58:	ec06                	sd	ra,24(sp)
    80001b5a:	e822                	sd	s0,16(sp)
    80001b5c:	e426                	sd	s1,8(sp)
    80001b5e:	1000                	add	s0,sp,32
    80001b60:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b62:	6d28                	ld	a0,88(a0)
    80001b64:	c509                	beqz	a0,80001b6e <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b66:	fffff097          	auipc	ra,0xfffff
    80001b6a:	e7c080e7          	jalr	-388(ra) # 800009e2 <kfree>
  p->trapframe = 0;
    80001b6e:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001b72:	68a8                	ld	a0,80(s1)
    80001b74:	c511                	beqz	a0,80001b80 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b76:	64ac                	ld	a1,72(s1)
    80001b78:	00000097          	auipc	ra,0x0
    80001b7c:	f8c080e7          	jalr	-116(ra) # 80001b04 <proc_freepagetable>
  p->pagetable = 0;
    80001b80:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b84:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b88:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b8c:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001b90:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001b94:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001b98:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001b9c:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001ba0:	0004ac23          	sw	zero,24(s1)
}
    80001ba4:	60e2                	ld	ra,24(sp)
    80001ba6:	6442                	ld	s0,16(sp)
    80001ba8:	64a2                	ld	s1,8(sp)
    80001baa:	6105                	add	sp,sp,32
    80001bac:	8082                	ret

0000000080001bae <allocproc>:
{
    80001bae:	1101                	add	sp,sp,-32
    80001bb0:	ec06                	sd	ra,24(sp)
    80001bb2:	e822                	sd	s0,16(sp)
    80001bb4:	e426                	sd	s1,8(sp)
    80001bb6:	e04a                	sd	s2,0(sp)
    80001bb8:	1000                	add	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bba:	0000f497          	auipc	s1,0xf
    80001bbe:	3a648493          	add	s1,s1,934 # 80010f60 <proc>
    80001bc2:	00015917          	auipc	s2,0x15
    80001bc6:	d9e90913          	add	s2,s2,-610 # 80016960 <tickslock>
    acquire(&p->lock);
    80001bca:	8526                	mv	a0,s1
    80001bcc:	fffff097          	auipc	ra,0xfffff
    80001bd0:	004080e7          	jalr	4(ra) # 80000bd0 <acquire>
    if(p->state == UNUSED) {
    80001bd4:	4c9c                	lw	a5,24(s1)
    80001bd6:	cf81                	beqz	a5,80001bee <allocproc+0x40>
      release(&p->lock);
    80001bd8:	8526                	mv	a0,s1
    80001bda:	fffff097          	auipc	ra,0xfffff
    80001bde:	0aa080e7          	jalr	170(ra) # 80000c84 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001be2:	16848493          	add	s1,s1,360
    80001be6:	ff2492e3          	bne	s1,s2,80001bca <allocproc+0x1c>
  return 0;
    80001bea:	4481                	li	s1,0
    80001bec:	a889                	j	80001c3e <allocproc+0x90>
  p->pid = allocpid();
    80001bee:	00000097          	auipc	ra,0x0
    80001bf2:	e34080e7          	jalr	-460(ra) # 80001a22 <allocpid>
    80001bf6:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001bf8:	4785                	li	a5,1
    80001bfa:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001bfc:	fffff097          	auipc	ra,0xfffff
    80001c00:	ee4080e7          	jalr	-284(ra) # 80000ae0 <kalloc>
    80001c04:	892a                	mv	s2,a0
    80001c06:	eca8                	sd	a0,88(s1)
    80001c08:	c131                	beqz	a0,80001c4c <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001c0a:	8526                	mv	a0,s1
    80001c0c:	00000097          	auipc	ra,0x0
    80001c10:	e5c080e7          	jalr	-420(ra) # 80001a68 <proc_pagetable>
    80001c14:	892a                	mv	s2,a0
    80001c16:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c18:	c531                	beqz	a0,80001c64 <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001c1a:	07000613          	li	a2,112
    80001c1e:	4581                	li	a1,0
    80001c20:	06048513          	add	a0,s1,96
    80001c24:	fffff097          	auipc	ra,0xfffff
    80001c28:	0a8080e7          	jalr	168(ra) # 80000ccc <memset>
  p->context.ra = (uint64)forkret;
    80001c2c:	00000797          	auipc	a5,0x0
    80001c30:	db078793          	add	a5,a5,-592 # 800019dc <forkret>
    80001c34:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c36:	60bc                	ld	a5,64(s1)
    80001c38:	6705                	lui	a4,0x1
    80001c3a:	97ba                	add	a5,a5,a4
    80001c3c:	f4bc                	sd	a5,104(s1)
}
    80001c3e:	8526                	mv	a0,s1
    80001c40:	60e2                	ld	ra,24(sp)
    80001c42:	6442                	ld	s0,16(sp)
    80001c44:	64a2                	ld	s1,8(sp)
    80001c46:	6902                	ld	s2,0(sp)
    80001c48:	6105                	add	sp,sp,32
    80001c4a:	8082                	ret
    freeproc(p);
    80001c4c:	8526                	mv	a0,s1
    80001c4e:	00000097          	auipc	ra,0x0
    80001c52:	f08080e7          	jalr	-248(ra) # 80001b56 <freeproc>
    release(&p->lock);
    80001c56:	8526                	mv	a0,s1
    80001c58:	fffff097          	auipc	ra,0xfffff
    80001c5c:	02c080e7          	jalr	44(ra) # 80000c84 <release>
    return 0;
    80001c60:	84ca                	mv	s1,s2
    80001c62:	bff1                	j	80001c3e <allocproc+0x90>
    freeproc(p);
    80001c64:	8526                	mv	a0,s1
    80001c66:	00000097          	auipc	ra,0x0
    80001c6a:	ef0080e7          	jalr	-272(ra) # 80001b56 <freeproc>
    release(&p->lock);
    80001c6e:	8526                	mv	a0,s1
    80001c70:	fffff097          	auipc	ra,0xfffff
    80001c74:	014080e7          	jalr	20(ra) # 80000c84 <release>
    return 0;
    80001c78:	84ca                	mv	s1,s2
    80001c7a:	b7d1                	j	80001c3e <allocproc+0x90>

0000000080001c7c <userinit>:
{
    80001c7c:	1101                	add	sp,sp,-32
    80001c7e:	ec06                	sd	ra,24(sp)
    80001c80:	e822                	sd	s0,16(sp)
    80001c82:	e426                	sd	s1,8(sp)
    80001c84:	1000                	add	s0,sp,32
  p = allocproc();
    80001c86:	00000097          	auipc	ra,0x0
    80001c8a:	f28080e7          	jalr	-216(ra) # 80001bae <allocproc>
    80001c8e:	84aa                	mv	s1,a0
  initproc = p;
    80001c90:	00007797          	auipc	a5,0x7
    80001c94:	c2a7b423          	sd	a0,-984(a5) # 800088b8 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001c98:	03400613          	li	a2,52
    80001c9c:	00007597          	auipc	a1,0x7
    80001ca0:	bb458593          	add	a1,a1,-1100 # 80008850 <initcode>
    80001ca4:	6928                	ld	a0,80(a0)
    80001ca6:	fffff097          	auipc	ra,0xfffff
    80001caa:	6a8080e7          	jalr	1704(ra) # 8000134e <uvmfirst>
  p->sz = PGSIZE;
    80001cae:	6785                	lui	a5,0x1
    80001cb0:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cb2:	6cb8                	ld	a4,88(s1)
    80001cb4:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cb8:	6cb8                	ld	a4,88(s1)
    80001cba:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cbc:	4641                	li	a2,16
    80001cbe:	00006597          	auipc	a1,0x6
    80001cc2:	54258593          	add	a1,a1,1346 # 80008200 <digits+0x1c0>
    80001cc6:	15848513          	add	a0,s1,344
    80001cca:	fffff097          	auipc	ra,0xfffff
    80001cce:	14a080e7          	jalr	330(ra) # 80000e14 <safestrcpy>
  p->cwd = namei("/");
    80001cd2:	00006517          	auipc	a0,0x6
    80001cd6:	53e50513          	add	a0,a0,1342 # 80008210 <digits+0x1d0>
    80001cda:	00002097          	auipc	ra,0x2
    80001cde:	0ec080e7          	jalr	236(ra) # 80003dc6 <namei>
    80001ce2:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001ce6:	478d                	li	a5,3
    80001ce8:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001cea:	8526                	mv	a0,s1
    80001cec:	fffff097          	auipc	ra,0xfffff
    80001cf0:	f98080e7          	jalr	-104(ra) # 80000c84 <release>
}
    80001cf4:	60e2                	ld	ra,24(sp)
    80001cf6:	6442                	ld	s0,16(sp)
    80001cf8:	64a2                	ld	s1,8(sp)
    80001cfa:	6105                	add	sp,sp,32
    80001cfc:	8082                	ret

0000000080001cfe <growproc>:
{
    80001cfe:	1101                	add	sp,sp,-32
    80001d00:	ec06                	sd	ra,24(sp)
    80001d02:	e822                	sd	s0,16(sp)
    80001d04:	e426                	sd	s1,8(sp)
    80001d06:	e04a                	sd	s2,0(sp)
    80001d08:	1000                	add	s0,sp,32
    80001d0a:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d0c:	00000097          	auipc	ra,0x0
    80001d10:	c98080e7          	jalr	-872(ra) # 800019a4 <myproc>
    80001d14:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d16:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001d18:	01204c63          	bgtz	s2,80001d30 <growproc+0x32>
  } else if(n < 0){
    80001d1c:	02094663          	bltz	s2,80001d48 <growproc+0x4a>
  p->sz = sz;
    80001d20:	e4ac                	sd	a1,72(s1)
  return 0;
    80001d22:	4501                	li	a0,0
}
    80001d24:	60e2                	ld	ra,24(sp)
    80001d26:	6442                	ld	s0,16(sp)
    80001d28:	64a2                	ld	s1,8(sp)
    80001d2a:	6902                	ld	s2,0(sp)
    80001d2c:	6105                	add	sp,sp,32
    80001d2e:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001d30:	4691                	li	a3,4
    80001d32:	00b90633          	add	a2,s2,a1
    80001d36:	6928                	ld	a0,80(a0)
    80001d38:	fffff097          	auipc	ra,0xfffff
    80001d3c:	6d0080e7          	jalr	1744(ra) # 80001408 <uvmalloc>
    80001d40:	85aa                	mv	a1,a0
    80001d42:	fd79                	bnez	a0,80001d20 <growproc+0x22>
      return -1;
    80001d44:	557d                	li	a0,-1
    80001d46:	bff9                	j	80001d24 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d48:	00b90633          	add	a2,s2,a1
    80001d4c:	6928                	ld	a0,80(a0)
    80001d4e:	fffff097          	auipc	ra,0xfffff
    80001d52:	672080e7          	jalr	1650(ra) # 800013c0 <uvmdealloc>
    80001d56:	85aa                	mv	a1,a0
    80001d58:	b7e1                	j	80001d20 <growproc+0x22>

0000000080001d5a <fork>:
{
    80001d5a:	7139                	add	sp,sp,-64
    80001d5c:	fc06                	sd	ra,56(sp)
    80001d5e:	f822                	sd	s0,48(sp)
    80001d60:	f426                	sd	s1,40(sp)
    80001d62:	f04a                	sd	s2,32(sp)
    80001d64:	ec4e                	sd	s3,24(sp)
    80001d66:	e852                	sd	s4,16(sp)
    80001d68:	e456                	sd	s5,8(sp)
    80001d6a:	0080                	add	s0,sp,64
  struct proc *p = myproc();
    80001d6c:	00000097          	auipc	ra,0x0
    80001d70:	c38080e7          	jalr	-968(ra) # 800019a4 <myproc>
    80001d74:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001d76:	00000097          	auipc	ra,0x0
    80001d7a:	e38080e7          	jalr	-456(ra) # 80001bae <allocproc>
    80001d7e:	10050c63          	beqz	a0,80001e96 <fork+0x13c>
    80001d82:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001d84:	048ab603          	ld	a2,72(s5)
    80001d88:	692c                	ld	a1,80(a0)
    80001d8a:	050ab503          	ld	a0,80(s5)
    80001d8e:	fffff097          	auipc	ra,0xfffff
    80001d92:	7d2080e7          	jalr	2002(ra) # 80001560 <uvmcopy>
    80001d96:	04054863          	bltz	a0,80001de6 <fork+0x8c>
  np->sz = p->sz;
    80001d9a:	048ab783          	ld	a5,72(s5)
    80001d9e:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001da2:	058ab683          	ld	a3,88(s5)
    80001da6:	87b6                	mv	a5,a3
    80001da8:	058a3703          	ld	a4,88(s4)
    80001dac:	12068693          	add	a3,a3,288
    80001db0:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001db4:	6788                	ld	a0,8(a5)
    80001db6:	6b8c                	ld	a1,16(a5)
    80001db8:	6f90                	ld	a2,24(a5)
    80001dba:	01073023          	sd	a6,0(a4)
    80001dbe:	e708                	sd	a0,8(a4)
    80001dc0:	eb0c                	sd	a1,16(a4)
    80001dc2:	ef10                	sd	a2,24(a4)
    80001dc4:	02078793          	add	a5,a5,32
    80001dc8:	02070713          	add	a4,a4,32
    80001dcc:	fed792e3          	bne	a5,a3,80001db0 <fork+0x56>
  np->trapframe->a0 = 0;
    80001dd0:	058a3783          	ld	a5,88(s4)
    80001dd4:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001dd8:	0d0a8493          	add	s1,s5,208
    80001ddc:	0d0a0913          	add	s2,s4,208
    80001de0:	150a8993          	add	s3,s5,336
    80001de4:	a00d                	j	80001e06 <fork+0xac>
    freeproc(np);
    80001de6:	8552                	mv	a0,s4
    80001de8:	00000097          	auipc	ra,0x0
    80001dec:	d6e080e7          	jalr	-658(ra) # 80001b56 <freeproc>
    release(&np->lock);
    80001df0:	8552                	mv	a0,s4
    80001df2:	fffff097          	auipc	ra,0xfffff
    80001df6:	e92080e7          	jalr	-366(ra) # 80000c84 <release>
    return -1;
    80001dfa:	597d                	li	s2,-1
    80001dfc:	a059                	j	80001e82 <fork+0x128>
  for(i = 0; i < NOFILE; i++)
    80001dfe:	04a1                	add	s1,s1,8
    80001e00:	0921                	add	s2,s2,8
    80001e02:	01348b63          	beq	s1,s3,80001e18 <fork+0xbe>
    if(p->ofile[i])
    80001e06:	6088                	ld	a0,0(s1)
    80001e08:	d97d                	beqz	a0,80001dfe <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e0a:	00002097          	auipc	ra,0x2
    80001e0e:	62e080e7          	jalr	1582(ra) # 80004438 <filedup>
    80001e12:	00a93023          	sd	a0,0(s2)
    80001e16:	b7e5                	j	80001dfe <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e18:	150ab503          	ld	a0,336(s5)
    80001e1c:	00001097          	auipc	ra,0x1
    80001e20:	7c6080e7          	jalr	1990(ra) # 800035e2 <idup>
    80001e24:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e28:	4641                	li	a2,16
    80001e2a:	158a8593          	add	a1,s5,344
    80001e2e:	158a0513          	add	a0,s4,344
    80001e32:	fffff097          	auipc	ra,0xfffff
    80001e36:	fe2080e7          	jalr	-30(ra) # 80000e14 <safestrcpy>
  pid = np->pid;
    80001e3a:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001e3e:	8552                	mv	a0,s4
    80001e40:	fffff097          	auipc	ra,0xfffff
    80001e44:	e44080e7          	jalr	-444(ra) # 80000c84 <release>
  acquire(&wait_lock);
    80001e48:	0000f497          	auipc	s1,0xf
    80001e4c:	d0048493          	add	s1,s1,-768 # 80010b48 <wait_lock>
    80001e50:	8526                	mv	a0,s1
    80001e52:	fffff097          	auipc	ra,0xfffff
    80001e56:	d7e080e7          	jalr	-642(ra) # 80000bd0 <acquire>
  np->parent = p;
    80001e5a:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001e5e:	8526                	mv	a0,s1
    80001e60:	fffff097          	auipc	ra,0xfffff
    80001e64:	e24080e7          	jalr	-476(ra) # 80000c84 <release>
  acquire(&np->lock);
    80001e68:	8552                	mv	a0,s4
    80001e6a:	fffff097          	auipc	ra,0xfffff
    80001e6e:	d66080e7          	jalr	-666(ra) # 80000bd0 <acquire>
  np->state = RUNNABLE;
    80001e72:	478d                	li	a5,3
    80001e74:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001e78:	8552                	mv	a0,s4
    80001e7a:	fffff097          	auipc	ra,0xfffff
    80001e7e:	e0a080e7          	jalr	-502(ra) # 80000c84 <release>
}
    80001e82:	854a                	mv	a0,s2
    80001e84:	70e2                	ld	ra,56(sp)
    80001e86:	7442                	ld	s0,48(sp)
    80001e88:	74a2                	ld	s1,40(sp)
    80001e8a:	7902                	ld	s2,32(sp)
    80001e8c:	69e2                	ld	s3,24(sp)
    80001e8e:	6a42                	ld	s4,16(sp)
    80001e90:	6aa2                	ld	s5,8(sp)
    80001e92:	6121                	add	sp,sp,64
    80001e94:	8082                	ret
    return -1;
    80001e96:	597d                	li	s2,-1
    80001e98:	b7ed                	j	80001e82 <fork+0x128>

0000000080001e9a <scheduler>:
{
    80001e9a:	7139                	add	sp,sp,-64
    80001e9c:	fc06                	sd	ra,56(sp)
    80001e9e:	f822                	sd	s0,48(sp)
    80001ea0:	f426                	sd	s1,40(sp)
    80001ea2:	f04a                	sd	s2,32(sp)
    80001ea4:	ec4e                	sd	s3,24(sp)
    80001ea6:	e852                	sd	s4,16(sp)
    80001ea8:	e456                	sd	s5,8(sp)
    80001eaa:	e05a                	sd	s6,0(sp)
    80001eac:	0080                	add	s0,sp,64
    80001eae:	8792                	mv	a5,tp
  int id = r_tp();
    80001eb0:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001eb2:	00779a93          	sll	s5,a5,0x7
    80001eb6:	0000f717          	auipc	a4,0xf
    80001eba:	c7a70713          	add	a4,a4,-902 # 80010b30 <pid_lock>
    80001ebe:	9756                	add	a4,a4,s5
    80001ec0:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001ec4:	0000f717          	auipc	a4,0xf
    80001ec8:	ca470713          	add	a4,a4,-860 # 80010b68 <cpus+0x8>
    80001ecc:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001ece:	498d                	li	s3,3
        p->state = RUNNING;
    80001ed0:	4b11                	li	s6,4
        c->proc = p;
    80001ed2:	079e                	sll	a5,a5,0x7
    80001ed4:	0000fa17          	auipc	s4,0xf
    80001ed8:	c5ca0a13          	add	s4,s4,-932 # 80010b30 <pid_lock>
    80001edc:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001ede:	00015917          	auipc	s2,0x15
    80001ee2:	a8290913          	add	s2,s2,-1406 # 80016960 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001ee6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001eea:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001eee:	10079073          	csrw	sstatus,a5
    80001ef2:	0000f497          	auipc	s1,0xf
    80001ef6:	06e48493          	add	s1,s1,110 # 80010f60 <proc>
    80001efa:	a811                	j	80001f0e <scheduler+0x74>
      release(&p->lock);
    80001efc:	8526                	mv	a0,s1
    80001efe:	fffff097          	auipc	ra,0xfffff
    80001f02:	d86080e7          	jalr	-634(ra) # 80000c84 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f06:	16848493          	add	s1,s1,360
    80001f0a:	fd248ee3          	beq	s1,s2,80001ee6 <scheduler+0x4c>
      acquire(&p->lock);
    80001f0e:	8526                	mv	a0,s1
    80001f10:	fffff097          	auipc	ra,0xfffff
    80001f14:	cc0080e7          	jalr	-832(ra) # 80000bd0 <acquire>
      if(p->state == RUNNABLE) {
    80001f18:	4c9c                	lw	a5,24(s1)
    80001f1a:	ff3791e3          	bne	a5,s3,80001efc <scheduler+0x62>
        p->state = RUNNING;
    80001f1e:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f22:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f26:	06048593          	add	a1,s1,96
    80001f2a:	8556                	mv	a0,s5
    80001f2c:	00000097          	auipc	ra,0x0
    80001f30:	684080e7          	jalr	1668(ra) # 800025b0 <swtch>
        c->proc = 0;
    80001f34:	020a3823          	sd	zero,48(s4)
    80001f38:	b7d1                	j	80001efc <scheduler+0x62>

0000000080001f3a <sched>:
{
    80001f3a:	7179                	add	sp,sp,-48
    80001f3c:	f406                	sd	ra,40(sp)
    80001f3e:	f022                	sd	s0,32(sp)
    80001f40:	ec26                	sd	s1,24(sp)
    80001f42:	e84a                	sd	s2,16(sp)
    80001f44:	e44e                	sd	s3,8(sp)
    80001f46:	1800                	add	s0,sp,48
  struct proc *p = myproc();
    80001f48:	00000097          	auipc	ra,0x0
    80001f4c:	a5c080e7          	jalr	-1444(ra) # 800019a4 <myproc>
    80001f50:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001f52:	fffff097          	auipc	ra,0xfffff
    80001f56:	c04080e7          	jalr	-1020(ra) # 80000b56 <holding>
    80001f5a:	c93d                	beqz	a0,80001fd0 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f5c:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001f5e:	2781                	sext.w	a5,a5
    80001f60:	079e                	sll	a5,a5,0x7
    80001f62:	0000f717          	auipc	a4,0xf
    80001f66:	bce70713          	add	a4,a4,-1074 # 80010b30 <pid_lock>
    80001f6a:	97ba                	add	a5,a5,a4
    80001f6c:	0a87a703          	lw	a4,168(a5)
    80001f70:	4785                	li	a5,1
    80001f72:	06f71763          	bne	a4,a5,80001fe0 <sched+0xa6>
  if(p->state == RUNNING)
    80001f76:	4c98                	lw	a4,24(s1)
    80001f78:	4791                	li	a5,4
    80001f7a:	06f70b63          	beq	a4,a5,80001ff0 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f7e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001f82:	8b89                	and	a5,a5,2
  if(intr_get())
    80001f84:	efb5                	bnez	a5,80002000 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f86:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001f88:	0000f917          	auipc	s2,0xf
    80001f8c:	ba890913          	add	s2,s2,-1112 # 80010b30 <pid_lock>
    80001f90:	2781                	sext.w	a5,a5
    80001f92:	079e                	sll	a5,a5,0x7
    80001f94:	97ca                	add	a5,a5,s2
    80001f96:	0ac7a983          	lw	s3,172(a5)
    80001f9a:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001f9c:	2781                	sext.w	a5,a5
    80001f9e:	079e                	sll	a5,a5,0x7
    80001fa0:	0000f597          	auipc	a1,0xf
    80001fa4:	bc858593          	add	a1,a1,-1080 # 80010b68 <cpus+0x8>
    80001fa8:	95be                	add	a1,a1,a5
    80001faa:	06048513          	add	a0,s1,96
    80001fae:	00000097          	auipc	ra,0x0
    80001fb2:	602080e7          	jalr	1538(ra) # 800025b0 <swtch>
    80001fb6:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001fb8:	2781                	sext.w	a5,a5
    80001fba:	079e                	sll	a5,a5,0x7
    80001fbc:	993e                	add	s2,s2,a5
    80001fbe:	0b392623          	sw	s3,172(s2)
}
    80001fc2:	70a2                	ld	ra,40(sp)
    80001fc4:	7402                	ld	s0,32(sp)
    80001fc6:	64e2                	ld	s1,24(sp)
    80001fc8:	6942                	ld	s2,16(sp)
    80001fca:	69a2                	ld	s3,8(sp)
    80001fcc:	6145                	add	sp,sp,48
    80001fce:	8082                	ret
    panic("sched p->lock");
    80001fd0:	00006517          	auipc	a0,0x6
    80001fd4:	24850513          	add	a0,a0,584 # 80008218 <digits+0x1d8>
    80001fd8:	ffffe097          	auipc	ra,0xffffe
    80001fdc:	562080e7          	jalr	1378(ra) # 8000053a <panic>
    panic("sched locks");
    80001fe0:	00006517          	auipc	a0,0x6
    80001fe4:	24850513          	add	a0,a0,584 # 80008228 <digits+0x1e8>
    80001fe8:	ffffe097          	auipc	ra,0xffffe
    80001fec:	552080e7          	jalr	1362(ra) # 8000053a <panic>
    panic("sched running");
    80001ff0:	00006517          	auipc	a0,0x6
    80001ff4:	24850513          	add	a0,a0,584 # 80008238 <digits+0x1f8>
    80001ff8:	ffffe097          	auipc	ra,0xffffe
    80001ffc:	542080e7          	jalr	1346(ra) # 8000053a <panic>
    panic("sched interruptible");
    80002000:	00006517          	auipc	a0,0x6
    80002004:	24850513          	add	a0,a0,584 # 80008248 <digits+0x208>
    80002008:	ffffe097          	auipc	ra,0xffffe
    8000200c:	532080e7          	jalr	1330(ra) # 8000053a <panic>

0000000080002010 <yield>:
{
    80002010:	1101                	add	sp,sp,-32
    80002012:	ec06                	sd	ra,24(sp)
    80002014:	e822                	sd	s0,16(sp)
    80002016:	e426                	sd	s1,8(sp)
    80002018:	1000                	add	s0,sp,32
  struct proc *p = myproc();
    8000201a:	00000097          	auipc	ra,0x0
    8000201e:	98a080e7          	jalr	-1654(ra) # 800019a4 <myproc>
    80002022:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002024:	fffff097          	auipc	ra,0xfffff
    80002028:	bac080e7          	jalr	-1108(ra) # 80000bd0 <acquire>
  p->state = RUNNABLE;
    8000202c:	478d                	li	a5,3
    8000202e:	cc9c                	sw	a5,24(s1)
  sched();
    80002030:	00000097          	auipc	ra,0x0
    80002034:	f0a080e7          	jalr	-246(ra) # 80001f3a <sched>
  release(&p->lock);
    80002038:	8526                	mv	a0,s1
    8000203a:	fffff097          	auipc	ra,0xfffff
    8000203e:	c4a080e7          	jalr	-950(ra) # 80000c84 <release>
}
    80002042:	60e2                	ld	ra,24(sp)
    80002044:	6442                	ld	s0,16(sp)
    80002046:	64a2                	ld	s1,8(sp)
    80002048:	6105                	add	sp,sp,32
    8000204a:	8082                	ret

000000008000204c <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    8000204c:	7179                	add	sp,sp,-48
    8000204e:	f406                	sd	ra,40(sp)
    80002050:	f022                	sd	s0,32(sp)
    80002052:	ec26                	sd	s1,24(sp)
    80002054:	e84a                	sd	s2,16(sp)
    80002056:	e44e                	sd	s3,8(sp)
    80002058:	1800                	add	s0,sp,48
    8000205a:	89aa                	mv	s3,a0
    8000205c:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000205e:	00000097          	auipc	ra,0x0
    80002062:	946080e7          	jalr	-1722(ra) # 800019a4 <myproc>
    80002066:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002068:	fffff097          	auipc	ra,0xfffff
    8000206c:	b68080e7          	jalr	-1176(ra) # 80000bd0 <acquire>
  release(lk);
    80002070:	854a                	mv	a0,s2
    80002072:	fffff097          	auipc	ra,0xfffff
    80002076:	c12080e7          	jalr	-1006(ra) # 80000c84 <release>

  // Go to sleep.
  p->chan = chan;
    8000207a:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    8000207e:	4789                	li	a5,2
    80002080:	cc9c                	sw	a5,24(s1)

  sched();
    80002082:	00000097          	auipc	ra,0x0
    80002086:	eb8080e7          	jalr	-328(ra) # 80001f3a <sched>

  // Tidy up.
  p->chan = 0;
    8000208a:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    8000208e:	8526                	mv	a0,s1
    80002090:	fffff097          	auipc	ra,0xfffff
    80002094:	bf4080e7          	jalr	-1036(ra) # 80000c84 <release>
  acquire(lk);
    80002098:	854a                	mv	a0,s2
    8000209a:	fffff097          	auipc	ra,0xfffff
    8000209e:	b36080e7          	jalr	-1226(ra) # 80000bd0 <acquire>
}
    800020a2:	70a2                	ld	ra,40(sp)
    800020a4:	7402                	ld	s0,32(sp)
    800020a6:	64e2                	ld	s1,24(sp)
    800020a8:	6942                	ld	s2,16(sp)
    800020aa:	69a2                	ld	s3,8(sp)
    800020ac:	6145                	add	sp,sp,48
    800020ae:	8082                	ret

00000000800020b0 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800020b0:	7139                	add	sp,sp,-64
    800020b2:	fc06                	sd	ra,56(sp)
    800020b4:	f822                	sd	s0,48(sp)
    800020b6:	f426                	sd	s1,40(sp)
    800020b8:	f04a                	sd	s2,32(sp)
    800020ba:	ec4e                	sd	s3,24(sp)
    800020bc:	e852                	sd	s4,16(sp)
    800020be:	e456                	sd	s5,8(sp)
    800020c0:	0080                	add	s0,sp,64
    800020c2:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800020c4:	0000f497          	auipc	s1,0xf
    800020c8:	e9c48493          	add	s1,s1,-356 # 80010f60 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800020cc:	4989                	li	s3,2
        p->state = RUNNABLE;
    800020ce:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800020d0:	00015917          	auipc	s2,0x15
    800020d4:	89090913          	add	s2,s2,-1904 # 80016960 <tickslock>
    800020d8:	a811                	j	800020ec <wakeup+0x3c>
      }
      release(&p->lock);
    800020da:	8526                	mv	a0,s1
    800020dc:	fffff097          	auipc	ra,0xfffff
    800020e0:	ba8080e7          	jalr	-1112(ra) # 80000c84 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800020e4:	16848493          	add	s1,s1,360
    800020e8:	03248663          	beq	s1,s2,80002114 <wakeup+0x64>
    if(p != myproc()){
    800020ec:	00000097          	auipc	ra,0x0
    800020f0:	8b8080e7          	jalr	-1864(ra) # 800019a4 <myproc>
    800020f4:	fea488e3          	beq	s1,a0,800020e4 <wakeup+0x34>
      acquire(&p->lock);
    800020f8:	8526                	mv	a0,s1
    800020fa:	fffff097          	auipc	ra,0xfffff
    800020fe:	ad6080e7          	jalr	-1322(ra) # 80000bd0 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002102:	4c9c                	lw	a5,24(s1)
    80002104:	fd379be3          	bne	a5,s3,800020da <wakeup+0x2a>
    80002108:	709c                	ld	a5,32(s1)
    8000210a:	fd4798e3          	bne	a5,s4,800020da <wakeup+0x2a>
        p->state = RUNNABLE;
    8000210e:	0154ac23          	sw	s5,24(s1)
    80002112:	b7e1                	j	800020da <wakeup+0x2a>
    }
  }
}
    80002114:	70e2                	ld	ra,56(sp)
    80002116:	7442                	ld	s0,48(sp)
    80002118:	74a2                	ld	s1,40(sp)
    8000211a:	7902                	ld	s2,32(sp)
    8000211c:	69e2                	ld	s3,24(sp)
    8000211e:	6a42                	ld	s4,16(sp)
    80002120:	6aa2                	ld	s5,8(sp)
    80002122:	6121                	add	sp,sp,64
    80002124:	8082                	ret

0000000080002126 <reparent>:
{
    80002126:	7179                	add	sp,sp,-48
    80002128:	f406                	sd	ra,40(sp)
    8000212a:	f022                	sd	s0,32(sp)
    8000212c:	ec26                	sd	s1,24(sp)
    8000212e:	e84a                	sd	s2,16(sp)
    80002130:	e44e                	sd	s3,8(sp)
    80002132:	e052                	sd	s4,0(sp)
    80002134:	1800                	add	s0,sp,48
    80002136:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002138:	0000f497          	auipc	s1,0xf
    8000213c:	e2848493          	add	s1,s1,-472 # 80010f60 <proc>
      pp->parent = initproc;
    80002140:	00006a17          	auipc	s4,0x6
    80002144:	778a0a13          	add	s4,s4,1912 # 800088b8 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002148:	00015997          	auipc	s3,0x15
    8000214c:	81898993          	add	s3,s3,-2024 # 80016960 <tickslock>
    80002150:	a029                	j	8000215a <reparent+0x34>
    80002152:	16848493          	add	s1,s1,360
    80002156:	01348d63          	beq	s1,s3,80002170 <reparent+0x4a>
    if(pp->parent == p){
    8000215a:	7c9c                	ld	a5,56(s1)
    8000215c:	ff279be3          	bne	a5,s2,80002152 <reparent+0x2c>
      pp->parent = initproc;
    80002160:	000a3503          	ld	a0,0(s4)
    80002164:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002166:	00000097          	auipc	ra,0x0
    8000216a:	f4a080e7          	jalr	-182(ra) # 800020b0 <wakeup>
    8000216e:	b7d5                	j	80002152 <reparent+0x2c>
}
    80002170:	70a2                	ld	ra,40(sp)
    80002172:	7402                	ld	s0,32(sp)
    80002174:	64e2                	ld	s1,24(sp)
    80002176:	6942                	ld	s2,16(sp)
    80002178:	69a2                	ld	s3,8(sp)
    8000217a:	6a02                	ld	s4,0(sp)
    8000217c:	6145                	add	sp,sp,48
    8000217e:	8082                	ret

0000000080002180 <exit>:
{
    80002180:	7179                	add	sp,sp,-48
    80002182:	f406                	sd	ra,40(sp)
    80002184:	f022                	sd	s0,32(sp)
    80002186:	ec26                	sd	s1,24(sp)
    80002188:	e84a                	sd	s2,16(sp)
    8000218a:	e44e                	sd	s3,8(sp)
    8000218c:	e052                	sd	s4,0(sp)
    8000218e:	1800                	add	s0,sp,48
    80002190:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002192:	00000097          	auipc	ra,0x0
    80002196:	812080e7          	jalr	-2030(ra) # 800019a4 <myproc>
    8000219a:	89aa                	mv	s3,a0
  if(p == initproc)
    8000219c:	00006797          	auipc	a5,0x6
    800021a0:	71c7b783          	ld	a5,1820(a5) # 800088b8 <initproc>
    800021a4:	0d050493          	add	s1,a0,208
    800021a8:	15050913          	add	s2,a0,336
    800021ac:	02a79363          	bne	a5,a0,800021d2 <exit+0x52>
    panic("init exiting");
    800021b0:	00006517          	auipc	a0,0x6
    800021b4:	0b050513          	add	a0,a0,176 # 80008260 <digits+0x220>
    800021b8:	ffffe097          	auipc	ra,0xffffe
    800021bc:	382080e7          	jalr	898(ra) # 8000053a <panic>
      fileclose(f);
    800021c0:	00002097          	auipc	ra,0x2
    800021c4:	2ca080e7          	jalr	714(ra) # 8000448a <fileclose>
      p->ofile[fd] = 0;
    800021c8:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800021cc:	04a1                	add	s1,s1,8
    800021ce:	01248563          	beq	s1,s2,800021d8 <exit+0x58>
    if(p->ofile[fd]){
    800021d2:	6088                	ld	a0,0(s1)
    800021d4:	f575                	bnez	a0,800021c0 <exit+0x40>
    800021d6:	bfdd                	j	800021cc <exit+0x4c>
  begin_op();
    800021d8:	00002097          	auipc	ra,0x2
    800021dc:	dee080e7          	jalr	-530(ra) # 80003fc6 <begin_op>
  iput(p->cwd);
    800021e0:	1509b503          	ld	a0,336(s3)
    800021e4:	00001097          	auipc	ra,0x1
    800021e8:	5f6080e7          	jalr	1526(ra) # 800037da <iput>
  end_op();
    800021ec:	00002097          	auipc	ra,0x2
    800021f0:	e54080e7          	jalr	-428(ra) # 80004040 <end_op>
  p->cwd = 0;
    800021f4:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800021f8:	0000f497          	auipc	s1,0xf
    800021fc:	95048493          	add	s1,s1,-1712 # 80010b48 <wait_lock>
    80002200:	8526                	mv	a0,s1
    80002202:	fffff097          	auipc	ra,0xfffff
    80002206:	9ce080e7          	jalr	-1586(ra) # 80000bd0 <acquire>
  reparent(p);
    8000220a:	854e                	mv	a0,s3
    8000220c:	00000097          	auipc	ra,0x0
    80002210:	f1a080e7          	jalr	-230(ra) # 80002126 <reparent>
  wakeup(p->parent);
    80002214:	0389b503          	ld	a0,56(s3)
    80002218:	00000097          	auipc	ra,0x0
    8000221c:	e98080e7          	jalr	-360(ra) # 800020b0 <wakeup>
  acquire(&p->lock);
    80002220:	854e                	mv	a0,s3
    80002222:	fffff097          	auipc	ra,0xfffff
    80002226:	9ae080e7          	jalr	-1618(ra) # 80000bd0 <acquire>
  p->xstate = status;
    8000222a:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    8000222e:	4795                	li	a5,5
    80002230:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002234:	8526                	mv	a0,s1
    80002236:	fffff097          	auipc	ra,0xfffff
    8000223a:	a4e080e7          	jalr	-1458(ra) # 80000c84 <release>
  sched();
    8000223e:	00000097          	auipc	ra,0x0
    80002242:	cfc080e7          	jalr	-772(ra) # 80001f3a <sched>
  panic("zombie exit");
    80002246:	00006517          	auipc	a0,0x6
    8000224a:	02a50513          	add	a0,a0,42 # 80008270 <digits+0x230>
    8000224e:	ffffe097          	auipc	ra,0xffffe
    80002252:	2ec080e7          	jalr	748(ra) # 8000053a <panic>

0000000080002256 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002256:	7179                	add	sp,sp,-48
    80002258:	f406                	sd	ra,40(sp)
    8000225a:	f022                	sd	s0,32(sp)
    8000225c:	ec26                	sd	s1,24(sp)
    8000225e:	e84a                	sd	s2,16(sp)
    80002260:	e44e                	sd	s3,8(sp)
    80002262:	1800                	add	s0,sp,48
    80002264:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002266:	0000f497          	auipc	s1,0xf
    8000226a:	cfa48493          	add	s1,s1,-774 # 80010f60 <proc>
    8000226e:	00014997          	auipc	s3,0x14
    80002272:	6f298993          	add	s3,s3,1778 # 80016960 <tickslock>
    acquire(&p->lock);
    80002276:	8526                	mv	a0,s1
    80002278:	fffff097          	auipc	ra,0xfffff
    8000227c:	958080e7          	jalr	-1704(ra) # 80000bd0 <acquire>
    if(p->pid == pid){
    80002280:	589c                	lw	a5,48(s1)
    80002282:	01278d63          	beq	a5,s2,8000229c <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002286:	8526                	mv	a0,s1
    80002288:	fffff097          	auipc	ra,0xfffff
    8000228c:	9fc080e7          	jalr	-1540(ra) # 80000c84 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002290:	16848493          	add	s1,s1,360
    80002294:	ff3491e3          	bne	s1,s3,80002276 <kill+0x20>
  }
  return -1;
    80002298:	557d                	li	a0,-1
    8000229a:	a829                	j	800022b4 <kill+0x5e>
      p->killed = 1;
    8000229c:	4785                	li	a5,1
    8000229e:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800022a0:	4c98                	lw	a4,24(s1)
    800022a2:	4789                	li	a5,2
    800022a4:	00f70f63          	beq	a4,a5,800022c2 <kill+0x6c>
      release(&p->lock);
    800022a8:	8526                	mv	a0,s1
    800022aa:	fffff097          	auipc	ra,0xfffff
    800022ae:	9da080e7          	jalr	-1574(ra) # 80000c84 <release>
      return 0;
    800022b2:	4501                	li	a0,0
}
    800022b4:	70a2                	ld	ra,40(sp)
    800022b6:	7402                	ld	s0,32(sp)
    800022b8:	64e2                	ld	s1,24(sp)
    800022ba:	6942                	ld	s2,16(sp)
    800022bc:	69a2                	ld	s3,8(sp)
    800022be:	6145                	add	sp,sp,48
    800022c0:	8082                	ret
        p->state = RUNNABLE;
    800022c2:	478d                	li	a5,3
    800022c4:	cc9c                	sw	a5,24(s1)
    800022c6:	b7cd                	j	800022a8 <kill+0x52>

00000000800022c8 <setkilled>:

void
setkilled(struct proc *p)
{
    800022c8:	1101                	add	sp,sp,-32
    800022ca:	ec06                	sd	ra,24(sp)
    800022cc:	e822                	sd	s0,16(sp)
    800022ce:	e426                	sd	s1,8(sp)
    800022d0:	1000                	add	s0,sp,32
    800022d2:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800022d4:	fffff097          	auipc	ra,0xfffff
    800022d8:	8fc080e7          	jalr	-1796(ra) # 80000bd0 <acquire>
  p->killed = 1;
    800022dc:	4785                	li	a5,1
    800022de:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    800022e0:	8526                	mv	a0,s1
    800022e2:	fffff097          	auipc	ra,0xfffff
    800022e6:	9a2080e7          	jalr	-1630(ra) # 80000c84 <release>
}
    800022ea:	60e2                	ld	ra,24(sp)
    800022ec:	6442                	ld	s0,16(sp)
    800022ee:	64a2                	ld	s1,8(sp)
    800022f0:	6105                	add	sp,sp,32
    800022f2:	8082                	ret

00000000800022f4 <killed>:

int
killed(struct proc *p)
{
    800022f4:	1101                	add	sp,sp,-32
    800022f6:	ec06                	sd	ra,24(sp)
    800022f8:	e822                	sd	s0,16(sp)
    800022fa:	e426                	sd	s1,8(sp)
    800022fc:	e04a                	sd	s2,0(sp)
    800022fe:	1000                	add	s0,sp,32
    80002300:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    80002302:	fffff097          	auipc	ra,0xfffff
    80002306:	8ce080e7          	jalr	-1842(ra) # 80000bd0 <acquire>
  k = p->killed;
    8000230a:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    8000230e:	8526                	mv	a0,s1
    80002310:	fffff097          	auipc	ra,0xfffff
    80002314:	974080e7          	jalr	-1676(ra) # 80000c84 <release>
  return k;
}
    80002318:	854a                	mv	a0,s2
    8000231a:	60e2                	ld	ra,24(sp)
    8000231c:	6442                	ld	s0,16(sp)
    8000231e:	64a2                	ld	s1,8(sp)
    80002320:	6902                	ld	s2,0(sp)
    80002322:	6105                	add	sp,sp,32
    80002324:	8082                	ret

0000000080002326 <wait>:
{
    80002326:	715d                	add	sp,sp,-80
    80002328:	e486                	sd	ra,72(sp)
    8000232a:	e0a2                	sd	s0,64(sp)
    8000232c:	fc26                	sd	s1,56(sp)
    8000232e:	f84a                	sd	s2,48(sp)
    80002330:	f44e                	sd	s3,40(sp)
    80002332:	f052                	sd	s4,32(sp)
    80002334:	ec56                	sd	s5,24(sp)
    80002336:	e85a                	sd	s6,16(sp)
    80002338:	e45e                	sd	s7,8(sp)
    8000233a:	e062                	sd	s8,0(sp)
    8000233c:	0880                	add	s0,sp,80
    8000233e:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002340:	fffff097          	auipc	ra,0xfffff
    80002344:	664080e7          	jalr	1636(ra) # 800019a4 <myproc>
    80002348:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000234a:	0000e517          	auipc	a0,0xe
    8000234e:	7fe50513          	add	a0,a0,2046 # 80010b48 <wait_lock>
    80002352:	fffff097          	auipc	ra,0xfffff
    80002356:	87e080e7          	jalr	-1922(ra) # 80000bd0 <acquire>
    havekids = 0;
    8000235a:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    8000235c:	4a15                	li	s4,5
        havekids = 1;
    8000235e:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002360:	00014997          	auipc	s3,0x14
    80002364:	60098993          	add	s3,s3,1536 # 80016960 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002368:	0000ec17          	auipc	s8,0xe
    8000236c:	7e0c0c13          	add	s8,s8,2016 # 80010b48 <wait_lock>
    80002370:	a0d1                	j	80002434 <wait+0x10e>
          pid = pp->pid;
    80002372:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002376:	000b0e63          	beqz	s6,80002392 <wait+0x6c>
    8000237a:	4691                	li	a3,4
    8000237c:	02c48613          	add	a2,s1,44
    80002380:	85da                	mv	a1,s6
    80002382:	05093503          	ld	a0,80(s2)
    80002386:	fffff097          	auipc	ra,0xfffff
    8000238a:	2de080e7          	jalr	734(ra) # 80001664 <copyout>
    8000238e:	04054163          	bltz	a0,800023d0 <wait+0xaa>
          freeproc(pp);
    80002392:	8526                	mv	a0,s1
    80002394:	fffff097          	auipc	ra,0xfffff
    80002398:	7c2080e7          	jalr	1986(ra) # 80001b56 <freeproc>
          release(&pp->lock);
    8000239c:	8526                	mv	a0,s1
    8000239e:	fffff097          	auipc	ra,0xfffff
    800023a2:	8e6080e7          	jalr	-1818(ra) # 80000c84 <release>
          release(&wait_lock);
    800023a6:	0000e517          	auipc	a0,0xe
    800023aa:	7a250513          	add	a0,a0,1954 # 80010b48 <wait_lock>
    800023ae:	fffff097          	auipc	ra,0xfffff
    800023b2:	8d6080e7          	jalr	-1834(ra) # 80000c84 <release>
}
    800023b6:	854e                	mv	a0,s3
    800023b8:	60a6                	ld	ra,72(sp)
    800023ba:	6406                	ld	s0,64(sp)
    800023bc:	74e2                	ld	s1,56(sp)
    800023be:	7942                	ld	s2,48(sp)
    800023c0:	79a2                	ld	s3,40(sp)
    800023c2:	7a02                	ld	s4,32(sp)
    800023c4:	6ae2                	ld	s5,24(sp)
    800023c6:	6b42                	ld	s6,16(sp)
    800023c8:	6ba2                	ld	s7,8(sp)
    800023ca:	6c02                	ld	s8,0(sp)
    800023cc:	6161                	add	sp,sp,80
    800023ce:	8082                	ret
            release(&pp->lock);
    800023d0:	8526                	mv	a0,s1
    800023d2:	fffff097          	auipc	ra,0xfffff
    800023d6:	8b2080e7          	jalr	-1870(ra) # 80000c84 <release>
            release(&wait_lock);
    800023da:	0000e517          	auipc	a0,0xe
    800023de:	76e50513          	add	a0,a0,1902 # 80010b48 <wait_lock>
    800023e2:	fffff097          	auipc	ra,0xfffff
    800023e6:	8a2080e7          	jalr	-1886(ra) # 80000c84 <release>
            return -1;
    800023ea:	59fd                	li	s3,-1
    800023ec:	b7e9                	j	800023b6 <wait+0x90>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800023ee:	16848493          	add	s1,s1,360
    800023f2:	03348463          	beq	s1,s3,8000241a <wait+0xf4>
      if(pp->parent == p){
    800023f6:	7c9c                	ld	a5,56(s1)
    800023f8:	ff279be3          	bne	a5,s2,800023ee <wait+0xc8>
        acquire(&pp->lock);
    800023fc:	8526                	mv	a0,s1
    800023fe:	ffffe097          	auipc	ra,0xffffe
    80002402:	7d2080e7          	jalr	2002(ra) # 80000bd0 <acquire>
        if(pp->state == ZOMBIE){
    80002406:	4c9c                	lw	a5,24(s1)
    80002408:	f74785e3          	beq	a5,s4,80002372 <wait+0x4c>
        release(&pp->lock);
    8000240c:	8526                	mv	a0,s1
    8000240e:	fffff097          	auipc	ra,0xfffff
    80002412:	876080e7          	jalr	-1930(ra) # 80000c84 <release>
        havekids = 1;
    80002416:	8756                	mv	a4,s5
    80002418:	bfd9                	j	800023ee <wait+0xc8>
    if(!havekids || killed(p)){
    8000241a:	c31d                	beqz	a4,80002440 <wait+0x11a>
    8000241c:	854a                	mv	a0,s2
    8000241e:	00000097          	auipc	ra,0x0
    80002422:	ed6080e7          	jalr	-298(ra) # 800022f4 <killed>
    80002426:	ed09                	bnez	a0,80002440 <wait+0x11a>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002428:	85e2                	mv	a1,s8
    8000242a:	854a                	mv	a0,s2
    8000242c:	00000097          	auipc	ra,0x0
    80002430:	c20080e7          	jalr	-992(ra) # 8000204c <sleep>
    havekids = 0;
    80002434:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002436:	0000f497          	auipc	s1,0xf
    8000243a:	b2a48493          	add	s1,s1,-1238 # 80010f60 <proc>
    8000243e:	bf65                	j	800023f6 <wait+0xd0>
      release(&wait_lock);
    80002440:	0000e517          	auipc	a0,0xe
    80002444:	70850513          	add	a0,a0,1800 # 80010b48 <wait_lock>
    80002448:	fffff097          	auipc	ra,0xfffff
    8000244c:	83c080e7          	jalr	-1988(ra) # 80000c84 <release>
      return -1;
    80002450:	59fd                	li	s3,-1
    80002452:	b795                	j	800023b6 <wait+0x90>

0000000080002454 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002454:	7179                	add	sp,sp,-48
    80002456:	f406                	sd	ra,40(sp)
    80002458:	f022                	sd	s0,32(sp)
    8000245a:	ec26                	sd	s1,24(sp)
    8000245c:	e84a                	sd	s2,16(sp)
    8000245e:	e44e                	sd	s3,8(sp)
    80002460:	e052                	sd	s4,0(sp)
    80002462:	1800                	add	s0,sp,48
    80002464:	84aa                	mv	s1,a0
    80002466:	892e                	mv	s2,a1
    80002468:	89b2                	mv	s3,a2
    8000246a:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000246c:	fffff097          	auipc	ra,0xfffff
    80002470:	538080e7          	jalr	1336(ra) # 800019a4 <myproc>
  if(user_dst){
    80002474:	c08d                	beqz	s1,80002496 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002476:	86d2                	mv	a3,s4
    80002478:	864e                	mv	a2,s3
    8000247a:	85ca                	mv	a1,s2
    8000247c:	6928                	ld	a0,80(a0)
    8000247e:	fffff097          	auipc	ra,0xfffff
    80002482:	1e6080e7          	jalr	486(ra) # 80001664 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002486:	70a2                	ld	ra,40(sp)
    80002488:	7402                	ld	s0,32(sp)
    8000248a:	64e2                	ld	s1,24(sp)
    8000248c:	6942                	ld	s2,16(sp)
    8000248e:	69a2                	ld	s3,8(sp)
    80002490:	6a02                	ld	s4,0(sp)
    80002492:	6145                	add	sp,sp,48
    80002494:	8082                	ret
    memmove((char *)dst, src, len);
    80002496:	000a061b          	sext.w	a2,s4
    8000249a:	85ce                	mv	a1,s3
    8000249c:	854a                	mv	a0,s2
    8000249e:	fffff097          	auipc	ra,0xfffff
    800024a2:	88a080e7          	jalr	-1910(ra) # 80000d28 <memmove>
    return 0;
    800024a6:	8526                	mv	a0,s1
    800024a8:	bff9                	j	80002486 <either_copyout+0x32>

00000000800024aa <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800024aa:	7179                	add	sp,sp,-48
    800024ac:	f406                	sd	ra,40(sp)
    800024ae:	f022                	sd	s0,32(sp)
    800024b0:	ec26                	sd	s1,24(sp)
    800024b2:	e84a                	sd	s2,16(sp)
    800024b4:	e44e                	sd	s3,8(sp)
    800024b6:	e052                	sd	s4,0(sp)
    800024b8:	1800                	add	s0,sp,48
    800024ba:	892a                	mv	s2,a0
    800024bc:	84ae                	mv	s1,a1
    800024be:	89b2                	mv	s3,a2
    800024c0:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024c2:	fffff097          	auipc	ra,0xfffff
    800024c6:	4e2080e7          	jalr	1250(ra) # 800019a4 <myproc>
  if(user_src){
    800024ca:	c08d                	beqz	s1,800024ec <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800024cc:	86d2                	mv	a3,s4
    800024ce:	864e                	mv	a2,s3
    800024d0:	85ca                	mv	a1,s2
    800024d2:	6928                	ld	a0,80(a0)
    800024d4:	fffff097          	auipc	ra,0xfffff
    800024d8:	21c080e7          	jalr	540(ra) # 800016f0 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800024dc:	70a2                	ld	ra,40(sp)
    800024de:	7402                	ld	s0,32(sp)
    800024e0:	64e2                	ld	s1,24(sp)
    800024e2:	6942                	ld	s2,16(sp)
    800024e4:	69a2                	ld	s3,8(sp)
    800024e6:	6a02                	ld	s4,0(sp)
    800024e8:	6145                	add	sp,sp,48
    800024ea:	8082                	ret
    memmove(dst, (char*)src, len);
    800024ec:	000a061b          	sext.w	a2,s4
    800024f0:	85ce                	mv	a1,s3
    800024f2:	854a                	mv	a0,s2
    800024f4:	fffff097          	auipc	ra,0xfffff
    800024f8:	834080e7          	jalr	-1996(ra) # 80000d28 <memmove>
    return 0;
    800024fc:	8526                	mv	a0,s1
    800024fe:	bff9                	j	800024dc <either_copyin+0x32>

0000000080002500 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002500:	715d                	add	sp,sp,-80
    80002502:	e486                	sd	ra,72(sp)
    80002504:	e0a2                	sd	s0,64(sp)
    80002506:	fc26                	sd	s1,56(sp)
    80002508:	f84a                	sd	s2,48(sp)
    8000250a:	f44e                	sd	s3,40(sp)
    8000250c:	f052                	sd	s4,32(sp)
    8000250e:	ec56                	sd	s5,24(sp)
    80002510:	e85a                	sd	s6,16(sp)
    80002512:	e45e                	sd	s7,8(sp)
    80002514:	0880                	add	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002516:	00006517          	auipc	a0,0x6
    8000251a:	bb250513          	add	a0,a0,-1102 # 800080c8 <digits+0x88>
    8000251e:	ffffe097          	auipc	ra,0xffffe
    80002522:	066080e7          	jalr	102(ra) # 80000584 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002526:	0000f497          	auipc	s1,0xf
    8000252a:	b9248493          	add	s1,s1,-1134 # 800110b8 <proc+0x158>
    8000252e:	00014917          	auipc	s2,0x14
    80002532:	58a90913          	add	s2,s2,1418 # 80016ab8 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002536:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002538:	00006997          	auipc	s3,0x6
    8000253c:	d4898993          	add	s3,s3,-696 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    80002540:	00006a97          	auipc	s5,0x6
    80002544:	d48a8a93          	add	s5,s5,-696 # 80008288 <digits+0x248>
    printf("\n");
    80002548:	00006a17          	auipc	s4,0x6
    8000254c:	b80a0a13          	add	s4,s4,-1152 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002550:	00006b97          	auipc	s7,0x6
    80002554:	d78b8b93          	add	s7,s7,-648 # 800082c8 <states.0>
    80002558:	a00d                	j	8000257a <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    8000255a:	ed86a583          	lw	a1,-296(a3)
    8000255e:	8556                	mv	a0,s5
    80002560:	ffffe097          	auipc	ra,0xffffe
    80002564:	024080e7          	jalr	36(ra) # 80000584 <printf>
    printf("\n");
    80002568:	8552                	mv	a0,s4
    8000256a:	ffffe097          	auipc	ra,0xffffe
    8000256e:	01a080e7          	jalr	26(ra) # 80000584 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002572:	16848493          	add	s1,s1,360
    80002576:	03248263          	beq	s1,s2,8000259a <procdump+0x9a>
    if(p->state == UNUSED)
    8000257a:	86a6                	mv	a3,s1
    8000257c:	ec04a783          	lw	a5,-320(s1)
    80002580:	dbed                	beqz	a5,80002572 <procdump+0x72>
      state = "???";
    80002582:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002584:	fcfb6be3          	bltu	s6,a5,8000255a <procdump+0x5a>
    80002588:	02079713          	sll	a4,a5,0x20
    8000258c:	01d75793          	srl	a5,a4,0x1d
    80002590:	97de                	add	a5,a5,s7
    80002592:	6390                	ld	a2,0(a5)
    80002594:	f279                	bnez	a2,8000255a <procdump+0x5a>
      state = "???";
    80002596:	864e                	mv	a2,s3
    80002598:	b7c9                	j	8000255a <procdump+0x5a>
  }
}
    8000259a:	60a6                	ld	ra,72(sp)
    8000259c:	6406                	ld	s0,64(sp)
    8000259e:	74e2                	ld	s1,56(sp)
    800025a0:	7942                	ld	s2,48(sp)
    800025a2:	79a2                	ld	s3,40(sp)
    800025a4:	7a02                	ld	s4,32(sp)
    800025a6:	6ae2                	ld	s5,24(sp)
    800025a8:	6b42                	ld	s6,16(sp)
    800025aa:	6ba2                	ld	s7,8(sp)
    800025ac:	6161                	add	sp,sp,80
    800025ae:	8082                	ret

00000000800025b0 <swtch>:
    800025b0:	00153023          	sd	ra,0(a0)
    800025b4:	00253423          	sd	sp,8(a0)
    800025b8:	e900                	sd	s0,16(a0)
    800025ba:	ed04                	sd	s1,24(a0)
    800025bc:	03253023          	sd	s2,32(a0)
    800025c0:	03353423          	sd	s3,40(a0)
    800025c4:	03453823          	sd	s4,48(a0)
    800025c8:	03553c23          	sd	s5,56(a0)
    800025cc:	05653023          	sd	s6,64(a0)
    800025d0:	05753423          	sd	s7,72(a0)
    800025d4:	05853823          	sd	s8,80(a0)
    800025d8:	05953c23          	sd	s9,88(a0)
    800025dc:	07a53023          	sd	s10,96(a0)
    800025e0:	07b53423          	sd	s11,104(a0)
    800025e4:	0005b083          	ld	ra,0(a1)
    800025e8:	0085b103          	ld	sp,8(a1)
    800025ec:	6980                	ld	s0,16(a1)
    800025ee:	6d84                	ld	s1,24(a1)
    800025f0:	0205b903          	ld	s2,32(a1)
    800025f4:	0285b983          	ld	s3,40(a1)
    800025f8:	0305ba03          	ld	s4,48(a1)
    800025fc:	0385ba83          	ld	s5,56(a1)
    80002600:	0405bb03          	ld	s6,64(a1)
    80002604:	0485bb83          	ld	s7,72(a1)
    80002608:	0505bc03          	ld	s8,80(a1)
    8000260c:	0585bc83          	ld	s9,88(a1)
    80002610:	0605bd03          	ld	s10,96(a1)
    80002614:	0685bd83          	ld	s11,104(a1)
    80002618:	8082                	ret

000000008000261a <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000261a:	1141                	add	sp,sp,-16
    8000261c:	e406                	sd	ra,8(sp)
    8000261e:	e022                	sd	s0,0(sp)
    80002620:	0800                	add	s0,sp,16
  initlock(&tickslock, "time");
    80002622:	00006597          	auipc	a1,0x6
    80002626:	cd658593          	add	a1,a1,-810 # 800082f8 <states.0+0x30>
    8000262a:	00014517          	auipc	a0,0x14
    8000262e:	33650513          	add	a0,a0,822 # 80016960 <tickslock>
    80002632:	ffffe097          	auipc	ra,0xffffe
    80002636:	50e080e7          	jalr	1294(ra) # 80000b40 <initlock>
}
    8000263a:	60a2                	ld	ra,8(sp)
    8000263c:	6402                	ld	s0,0(sp)
    8000263e:	0141                	add	sp,sp,16
    80002640:	8082                	ret

0000000080002642 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002642:	1141                	add	sp,sp,-16
    80002644:	e422                	sd	s0,8(sp)
    80002646:	0800                	add	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002648:	00003797          	auipc	a5,0x3
    8000264c:	46878793          	add	a5,a5,1128 # 80005ab0 <kernelvec>
    80002650:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002654:	6422                	ld	s0,8(sp)
    80002656:	0141                	add	sp,sp,16
    80002658:	8082                	ret

000000008000265a <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    8000265a:	1141                	add	sp,sp,-16
    8000265c:	e406                	sd	ra,8(sp)
    8000265e:	e022                	sd	s0,0(sp)
    80002660:	0800                	add	s0,sp,16
  struct proc *p = myproc();
    80002662:	fffff097          	auipc	ra,0xfffff
    80002666:	342080e7          	jalr	834(ra) # 800019a4 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000266a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000266e:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002670:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002674:	00005697          	auipc	a3,0x5
    80002678:	98c68693          	add	a3,a3,-1652 # 80007000 <_trampoline>
    8000267c:	00005717          	auipc	a4,0x5
    80002680:	98470713          	add	a4,a4,-1660 # 80007000 <_trampoline>
    80002684:	8f15                	sub	a4,a4,a3
    80002686:	040007b7          	lui	a5,0x4000
    8000268a:	17fd                	add	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    8000268c:	07b2                	sll	a5,a5,0xc
    8000268e:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002690:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002694:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002696:	18002673          	csrr	a2,satp
    8000269a:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000269c:	6d30                	ld	a2,88(a0)
    8000269e:	6138                	ld	a4,64(a0)
    800026a0:	6585                	lui	a1,0x1
    800026a2:	972e                	add	a4,a4,a1
    800026a4:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800026a6:	6d38                	ld	a4,88(a0)
    800026a8:	00000617          	auipc	a2,0x0
    800026ac:	13460613          	add	a2,a2,308 # 800027dc <usertrap>
    800026b0:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800026b2:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800026b4:	8612                	mv	a2,tp
    800026b6:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026b8:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800026bc:	eff77713          	and	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800026c0:	02076713          	or	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026c4:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800026c8:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800026ca:	6f18                	ld	a4,24(a4)
    800026cc:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800026d0:	6928                	ld	a0,80(a0)
    800026d2:	8131                	srl	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    800026d4:	00005717          	auipc	a4,0x5
    800026d8:	9c870713          	add	a4,a4,-1592 # 8000709c <userret>
    800026dc:	8f15                	sub	a4,a4,a3
    800026de:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    800026e0:	577d                	li	a4,-1
    800026e2:	177e                	sll	a4,a4,0x3f
    800026e4:	8d59                	or	a0,a0,a4
    800026e6:	9782                	jalr	a5
}
    800026e8:	60a2                	ld	ra,8(sp)
    800026ea:	6402                	ld	s0,0(sp)
    800026ec:	0141                	add	sp,sp,16
    800026ee:	8082                	ret

00000000800026f0 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800026f0:	1101                	add	sp,sp,-32
    800026f2:	ec06                	sd	ra,24(sp)
    800026f4:	e822                	sd	s0,16(sp)
    800026f6:	e426                	sd	s1,8(sp)
    800026f8:	1000                	add	s0,sp,32
  acquire(&tickslock);
    800026fa:	00014497          	auipc	s1,0x14
    800026fe:	26648493          	add	s1,s1,614 # 80016960 <tickslock>
    80002702:	8526                	mv	a0,s1
    80002704:	ffffe097          	auipc	ra,0xffffe
    80002708:	4cc080e7          	jalr	1228(ra) # 80000bd0 <acquire>
  ticks++;
    8000270c:	00006517          	auipc	a0,0x6
    80002710:	1b450513          	add	a0,a0,436 # 800088c0 <ticks>
    80002714:	411c                	lw	a5,0(a0)
    80002716:	2785                	addw	a5,a5,1
    80002718:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    8000271a:	00000097          	auipc	ra,0x0
    8000271e:	996080e7          	jalr	-1642(ra) # 800020b0 <wakeup>
  release(&tickslock);
    80002722:	8526                	mv	a0,s1
    80002724:	ffffe097          	auipc	ra,0xffffe
    80002728:	560080e7          	jalr	1376(ra) # 80000c84 <release>
}
    8000272c:	60e2                	ld	ra,24(sp)
    8000272e:	6442                	ld	s0,16(sp)
    80002730:	64a2                	ld	s1,8(sp)
    80002732:	6105                	add	sp,sp,32
    80002734:	8082                	ret

0000000080002736 <devintr>:
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002736:	142027f3          	csrr	a5,scause
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    8000273a:	4501                	li	a0,0
  if((scause & 0x8000000000000000L) &&
    8000273c:	0807df63          	bgez	a5,800027da <devintr+0xa4>
{
    80002740:	1101                	add	sp,sp,-32
    80002742:	ec06                	sd	ra,24(sp)
    80002744:	e822                	sd	s0,16(sp)
    80002746:	e426                	sd	s1,8(sp)
    80002748:	1000                	add	s0,sp,32
     (scause & 0xff) == 9){
    8000274a:	0ff7f713          	zext.b	a4,a5
  if((scause & 0x8000000000000000L) &&
    8000274e:	46a5                	li	a3,9
    80002750:	00d70d63          	beq	a4,a3,8000276a <devintr+0x34>
  } else if(scause == 0x8000000000000001L){
    80002754:	577d                	li	a4,-1
    80002756:	177e                	sll	a4,a4,0x3f
    80002758:	0705                	add	a4,a4,1
    return 0;
    8000275a:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    8000275c:	04e78e63          	beq	a5,a4,800027b8 <devintr+0x82>
  }
}
    80002760:	60e2                	ld	ra,24(sp)
    80002762:	6442                	ld	s0,16(sp)
    80002764:	64a2                	ld	s1,8(sp)
    80002766:	6105                	add	sp,sp,32
    80002768:	8082                	ret
    int irq = plic_claim();
    8000276a:	00003097          	auipc	ra,0x3
    8000276e:	44e080e7          	jalr	1102(ra) # 80005bb8 <plic_claim>
    80002772:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002774:	47a9                	li	a5,10
    80002776:	02f50763          	beq	a0,a5,800027a4 <devintr+0x6e>
    } else if(irq == VIRTIO0_IRQ){
    8000277a:	4785                	li	a5,1
    8000277c:	02f50963          	beq	a0,a5,800027ae <devintr+0x78>
    return 1;
    80002780:	4505                	li	a0,1
    } else if(irq){
    80002782:	dcf9                	beqz	s1,80002760 <devintr+0x2a>
      printf("unexpected interrupt irq=%d\n", irq);
    80002784:	85a6                	mv	a1,s1
    80002786:	00006517          	auipc	a0,0x6
    8000278a:	b7a50513          	add	a0,a0,-1158 # 80008300 <states.0+0x38>
    8000278e:	ffffe097          	auipc	ra,0xffffe
    80002792:	df6080e7          	jalr	-522(ra) # 80000584 <printf>
      plic_complete(irq);
    80002796:	8526                	mv	a0,s1
    80002798:	00003097          	auipc	ra,0x3
    8000279c:	444080e7          	jalr	1092(ra) # 80005bdc <plic_complete>
    return 1;
    800027a0:	4505                	li	a0,1
    800027a2:	bf7d                	j	80002760 <devintr+0x2a>
      uartintr();
    800027a4:	ffffe097          	auipc	ra,0xffffe
    800027a8:	1ee080e7          	jalr	494(ra) # 80000992 <uartintr>
    if(irq)
    800027ac:	b7ed                	j	80002796 <devintr+0x60>
      virtio_disk_intr();
    800027ae:	00004097          	auipc	ra,0x4
    800027b2:	8f4080e7          	jalr	-1804(ra) # 800060a2 <virtio_disk_intr>
    if(irq)
    800027b6:	b7c5                	j	80002796 <devintr+0x60>
    if(cpuid() == 0){
    800027b8:	fffff097          	auipc	ra,0xfffff
    800027bc:	1c0080e7          	jalr	448(ra) # 80001978 <cpuid>
    800027c0:	c901                	beqz	a0,800027d0 <devintr+0x9a>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800027c2:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800027c6:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800027c8:	14479073          	csrw	sip,a5
    return 2;
    800027cc:	4509                	li	a0,2
    800027ce:	bf49                	j	80002760 <devintr+0x2a>
      clockintr();
    800027d0:	00000097          	auipc	ra,0x0
    800027d4:	f20080e7          	jalr	-224(ra) # 800026f0 <clockintr>
    800027d8:	b7ed                	j	800027c2 <devintr+0x8c>
}
    800027da:	8082                	ret

00000000800027dc <usertrap>:
{
    800027dc:	1101                	add	sp,sp,-32
    800027de:	ec06                	sd	ra,24(sp)
    800027e0:	e822                	sd	s0,16(sp)
    800027e2:	e426                	sd	s1,8(sp)
    800027e4:	e04a                	sd	s2,0(sp)
    800027e6:	1000                	add	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027e8:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800027ec:	1007f793          	and	a5,a5,256
    800027f0:	e3b1                	bnez	a5,80002834 <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800027f2:	00003797          	auipc	a5,0x3
    800027f6:	2be78793          	add	a5,a5,702 # 80005ab0 <kernelvec>
    800027fa:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800027fe:	fffff097          	auipc	ra,0xfffff
    80002802:	1a6080e7          	jalr	422(ra) # 800019a4 <myproc>
    80002806:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002808:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000280a:	14102773          	csrr	a4,sepc
    8000280e:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002810:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002814:	47a1                	li	a5,8
    80002816:	02f70763          	beq	a4,a5,80002844 <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    8000281a:	00000097          	auipc	ra,0x0
    8000281e:	f1c080e7          	jalr	-228(ra) # 80002736 <devintr>
    80002822:	892a                	mv	s2,a0
    80002824:	c151                	beqz	a0,800028a8 <usertrap+0xcc>
  if(killed(p))
    80002826:	8526                	mv	a0,s1
    80002828:	00000097          	auipc	ra,0x0
    8000282c:	acc080e7          	jalr	-1332(ra) # 800022f4 <killed>
    80002830:	c929                	beqz	a0,80002882 <usertrap+0xa6>
    80002832:	a099                	j	80002878 <usertrap+0x9c>
    panic("usertrap: not from user mode");
    80002834:	00006517          	auipc	a0,0x6
    80002838:	aec50513          	add	a0,a0,-1300 # 80008320 <states.0+0x58>
    8000283c:	ffffe097          	auipc	ra,0xffffe
    80002840:	cfe080e7          	jalr	-770(ra) # 8000053a <panic>
    if(killed(p))
    80002844:	00000097          	auipc	ra,0x0
    80002848:	ab0080e7          	jalr	-1360(ra) # 800022f4 <killed>
    8000284c:	e921                	bnez	a0,8000289c <usertrap+0xc0>
    p->trapframe->epc += 4;
    8000284e:	6cb8                	ld	a4,88(s1)
    80002850:	6f1c                	ld	a5,24(a4)
    80002852:	0791                	add	a5,a5,4
    80002854:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002856:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000285a:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000285e:	10079073          	csrw	sstatus,a5
    syscall();
    80002862:	00000097          	auipc	ra,0x0
    80002866:	2d4080e7          	jalr	724(ra) # 80002b36 <syscall>
  if(killed(p))
    8000286a:	8526                	mv	a0,s1
    8000286c:	00000097          	auipc	ra,0x0
    80002870:	a88080e7          	jalr	-1400(ra) # 800022f4 <killed>
    80002874:	c911                	beqz	a0,80002888 <usertrap+0xac>
    80002876:	4901                	li	s2,0
    exit(-1);
    80002878:	557d                	li	a0,-1
    8000287a:	00000097          	auipc	ra,0x0
    8000287e:	906080e7          	jalr	-1786(ra) # 80002180 <exit>
  if(which_dev == 2)
    80002882:	4789                	li	a5,2
    80002884:	04f90f63          	beq	s2,a5,800028e2 <usertrap+0x106>
  usertrapret();
    80002888:	00000097          	auipc	ra,0x0
    8000288c:	dd2080e7          	jalr	-558(ra) # 8000265a <usertrapret>
}
    80002890:	60e2                	ld	ra,24(sp)
    80002892:	6442                	ld	s0,16(sp)
    80002894:	64a2                	ld	s1,8(sp)
    80002896:	6902                	ld	s2,0(sp)
    80002898:	6105                	add	sp,sp,32
    8000289a:	8082                	ret
      exit(-1);
    8000289c:	557d                	li	a0,-1
    8000289e:	00000097          	auipc	ra,0x0
    800028a2:	8e2080e7          	jalr	-1822(ra) # 80002180 <exit>
    800028a6:	b765                	j	8000284e <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028a8:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800028ac:	5890                	lw	a2,48(s1)
    800028ae:	00006517          	auipc	a0,0x6
    800028b2:	a9250513          	add	a0,a0,-1390 # 80008340 <states.0+0x78>
    800028b6:	ffffe097          	auipc	ra,0xffffe
    800028ba:	cce080e7          	jalr	-818(ra) # 80000584 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028be:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800028c2:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800028c6:	00006517          	auipc	a0,0x6
    800028ca:	aaa50513          	add	a0,a0,-1366 # 80008370 <states.0+0xa8>
    800028ce:	ffffe097          	auipc	ra,0xffffe
    800028d2:	cb6080e7          	jalr	-842(ra) # 80000584 <printf>
    setkilled(p);
    800028d6:	8526                	mv	a0,s1
    800028d8:	00000097          	auipc	ra,0x0
    800028dc:	9f0080e7          	jalr	-1552(ra) # 800022c8 <setkilled>
    800028e0:	b769                	j	8000286a <usertrap+0x8e>
    yield();
    800028e2:	fffff097          	auipc	ra,0xfffff
    800028e6:	72e080e7          	jalr	1838(ra) # 80002010 <yield>
    800028ea:	bf79                	j	80002888 <usertrap+0xac>

00000000800028ec <kerneltrap>:
{
    800028ec:	7179                	add	sp,sp,-48
    800028ee:	f406                	sd	ra,40(sp)
    800028f0:	f022                	sd	s0,32(sp)
    800028f2:	ec26                	sd	s1,24(sp)
    800028f4:	e84a                	sd	s2,16(sp)
    800028f6:	e44e                	sd	s3,8(sp)
    800028f8:	1800                	add	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028fa:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028fe:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002902:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002906:	1004f793          	and	a5,s1,256
    8000290a:	cb85                	beqz	a5,8000293a <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000290c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002910:	8b89                	and	a5,a5,2
  if(intr_get() != 0)
    80002912:	ef85                	bnez	a5,8000294a <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002914:	00000097          	auipc	ra,0x0
    80002918:	e22080e7          	jalr	-478(ra) # 80002736 <devintr>
    8000291c:	cd1d                	beqz	a0,8000295a <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    8000291e:	4789                	li	a5,2
    80002920:	06f50a63          	beq	a0,a5,80002994 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002924:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002928:	10049073          	csrw	sstatus,s1
}
    8000292c:	70a2                	ld	ra,40(sp)
    8000292e:	7402                	ld	s0,32(sp)
    80002930:	64e2                	ld	s1,24(sp)
    80002932:	6942                	ld	s2,16(sp)
    80002934:	69a2                	ld	s3,8(sp)
    80002936:	6145                	add	sp,sp,48
    80002938:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    8000293a:	00006517          	auipc	a0,0x6
    8000293e:	a5650513          	add	a0,a0,-1450 # 80008390 <states.0+0xc8>
    80002942:	ffffe097          	auipc	ra,0xffffe
    80002946:	bf8080e7          	jalr	-1032(ra) # 8000053a <panic>
    panic("kerneltrap: interrupts enabled");
    8000294a:	00006517          	auipc	a0,0x6
    8000294e:	a6e50513          	add	a0,a0,-1426 # 800083b8 <states.0+0xf0>
    80002952:	ffffe097          	auipc	ra,0xffffe
    80002956:	be8080e7          	jalr	-1048(ra) # 8000053a <panic>
    printf("scause %p\n", scause);
    8000295a:	85ce                	mv	a1,s3
    8000295c:	00006517          	auipc	a0,0x6
    80002960:	a7c50513          	add	a0,a0,-1412 # 800083d8 <states.0+0x110>
    80002964:	ffffe097          	auipc	ra,0xffffe
    80002968:	c20080e7          	jalr	-992(ra) # 80000584 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000296c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002970:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002974:	00006517          	auipc	a0,0x6
    80002978:	a7450513          	add	a0,a0,-1420 # 800083e8 <states.0+0x120>
    8000297c:	ffffe097          	auipc	ra,0xffffe
    80002980:	c08080e7          	jalr	-1016(ra) # 80000584 <printf>
    panic("kerneltrap");
    80002984:	00006517          	auipc	a0,0x6
    80002988:	a7c50513          	add	a0,a0,-1412 # 80008400 <states.0+0x138>
    8000298c:	ffffe097          	auipc	ra,0xffffe
    80002990:	bae080e7          	jalr	-1106(ra) # 8000053a <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002994:	fffff097          	auipc	ra,0xfffff
    80002998:	010080e7          	jalr	16(ra) # 800019a4 <myproc>
    8000299c:	d541                	beqz	a0,80002924 <kerneltrap+0x38>
    8000299e:	fffff097          	auipc	ra,0xfffff
    800029a2:	006080e7          	jalr	6(ra) # 800019a4 <myproc>
    800029a6:	4d18                	lw	a4,24(a0)
    800029a8:	4791                	li	a5,4
    800029aa:	f6f71de3          	bne	a4,a5,80002924 <kerneltrap+0x38>
    yield();
    800029ae:	fffff097          	auipc	ra,0xfffff
    800029b2:	662080e7          	jalr	1634(ra) # 80002010 <yield>
    800029b6:	b7bd                	j	80002924 <kerneltrap+0x38>

00000000800029b8 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    800029b8:	1101                	add	sp,sp,-32
    800029ba:	ec06                	sd	ra,24(sp)
    800029bc:	e822                	sd	s0,16(sp)
    800029be:	e426                	sd	s1,8(sp)
    800029c0:	1000                	add	s0,sp,32
    800029c2:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800029c4:	fffff097          	auipc	ra,0xfffff
    800029c8:	fe0080e7          	jalr	-32(ra) # 800019a4 <myproc>
  switch (n) {
    800029cc:	4795                	li	a5,5
    800029ce:	0497e163          	bltu	a5,s1,80002a10 <argraw+0x58>
    800029d2:	048a                	sll	s1,s1,0x2
    800029d4:	00006717          	auipc	a4,0x6
    800029d8:	a6470713          	add	a4,a4,-1436 # 80008438 <states.0+0x170>
    800029dc:	94ba                	add	s1,s1,a4
    800029de:	409c                	lw	a5,0(s1)
    800029e0:	97ba                	add	a5,a5,a4
    800029e2:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    800029e4:	6d3c                	ld	a5,88(a0)
    800029e6:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    800029e8:	60e2                	ld	ra,24(sp)
    800029ea:	6442                	ld	s0,16(sp)
    800029ec:	64a2                	ld	s1,8(sp)
    800029ee:	6105                	add	sp,sp,32
    800029f0:	8082                	ret
    return p->trapframe->a1;
    800029f2:	6d3c                	ld	a5,88(a0)
    800029f4:	7fa8                	ld	a0,120(a5)
    800029f6:	bfcd                	j	800029e8 <argraw+0x30>
    return p->trapframe->a2;
    800029f8:	6d3c                	ld	a5,88(a0)
    800029fa:	63c8                	ld	a0,128(a5)
    800029fc:	b7f5                	j	800029e8 <argraw+0x30>
    return p->trapframe->a3;
    800029fe:	6d3c                	ld	a5,88(a0)
    80002a00:	67c8                	ld	a0,136(a5)
    80002a02:	b7dd                	j	800029e8 <argraw+0x30>
    return p->trapframe->a4;
    80002a04:	6d3c                	ld	a5,88(a0)
    80002a06:	6bc8                	ld	a0,144(a5)
    80002a08:	b7c5                	j	800029e8 <argraw+0x30>
    return p->trapframe->a5;
    80002a0a:	6d3c                	ld	a5,88(a0)
    80002a0c:	6fc8                	ld	a0,152(a5)
    80002a0e:	bfe9                	j	800029e8 <argraw+0x30>
  panic("argraw");
    80002a10:	00006517          	auipc	a0,0x6
    80002a14:	a0050513          	add	a0,a0,-1536 # 80008410 <states.0+0x148>
    80002a18:	ffffe097          	auipc	ra,0xffffe
    80002a1c:	b22080e7          	jalr	-1246(ra) # 8000053a <panic>

0000000080002a20 <fetchaddr>:
{
    80002a20:	1101                	add	sp,sp,-32
    80002a22:	ec06                	sd	ra,24(sp)
    80002a24:	e822                	sd	s0,16(sp)
    80002a26:	e426                	sd	s1,8(sp)
    80002a28:	e04a                	sd	s2,0(sp)
    80002a2a:	1000                	add	s0,sp,32
    80002a2c:	84aa                	mv	s1,a0
    80002a2e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002a30:	fffff097          	auipc	ra,0xfffff
    80002a34:	f74080e7          	jalr	-140(ra) # 800019a4 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002a38:	653c                	ld	a5,72(a0)
    80002a3a:	02f4f863          	bgeu	s1,a5,80002a6a <fetchaddr+0x4a>
    80002a3e:	00848713          	add	a4,s1,8
    80002a42:	02e7e663          	bltu	a5,a4,80002a6e <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002a46:	46a1                	li	a3,8
    80002a48:	8626                	mv	a2,s1
    80002a4a:	85ca                	mv	a1,s2
    80002a4c:	6928                	ld	a0,80(a0)
    80002a4e:	fffff097          	auipc	ra,0xfffff
    80002a52:	ca2080e7          	jalr	-862(ra) # 800016f0 <copyin>
    80002a56:	00a03533          	snez	a0,a0
    80002a5a:	40a00533          	neg	a0,a0
}
    80002a5e:	60e2                	ld	ra,24(sp)
    80002a60:	6442                	ld	s0,16(sp)
    80002a62:	64a2                	ld	s1,8(sp)
    80002a64:	6902                	ld	s2,0(sp)
    80002a66:	6105                	add	sp,sp,32
    80002a68:	8082                	ret
    return -1;
    80002a6a:	557d                	li	a0,-1
    80002a6c:	bfcd                	j	80002a5e <fetchaddr+0x3e>
    80002a6e:	557d                	li	a0,-1
    80002a70:	b7fd                	j	80002a5e <fetchaddr+0x3e>

0000000080002a72 <fetchstr>:
{
    80002a72:	7179                	add	sp,sp,-48
    80002a74:	f406                	sd	ra,40(sp)
    80002a76:	f022                	sd	s0,32(sp)
    80002a78:	ec26                	sd	s1,24(sp)
    80002a7a:	e84a                	sd	s2,16(sp)
    80002a7c:	e44e                	sd	s3,8(sp)
    80002a7e:	1800                	add	s0,sp,48
    80002a80:	892a                	mv	s2,a0
    80002a82:	84ae                	mv	s1,a1
    80002a84:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002a86:	fffff097          	auipc	ra,0xfffff
    80002a8a:	f1e080e7          	jalr	-226(ra) # 800019a4 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002a8e:	86ce                	mv	a3,s3
    80002a90:	864a                	mv	a2,s2
    80002a92:	85a6                	mv	a1,s1
    80002a94:	6928                	ld	a0,80(a0)
    80002a96:	fffff097          	auipc	ra,0xfffff
    80002a9a:	ce8080e7          	jalr	-792(ra) # 8000177e <copyinstr>
    80002a9e:	00054e63          	bltz	a0,80002aba <fetchstr+0x48>
  return strlen(buf);
    80002aa2:	8526                	mv	a0,s1
    80002aa4:	ffffe097          	auipc	ra,0xffffe
    80002aa8:	3a2080e7          	jalr	930(ra) # 80000e46 <strlen>
}
    80002aac:	70a2                	ld	ra,40(sp)
    80002aae:	7402                	ld	s0,32(sp)
    80002ab0:	64e2                	ld	s1,24(sp)
    80002ab2:	6942                	ld	s2,16(sp)
    80002ab4:	69a2                	ld	s3,8(sp)
    80002ab6:	6145                	add	sp,sp,48
    80002ab8:	8082                	ret
    return -1;
    80002aba:	557d                	li	a0,-1
    80002abc:	bfc5                	j	80002aac <fetchstr+0x3a>

0000000080002abe <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002abe:	1101                	add	sp,sp,-32
    80002ac0:	ec06                	sd	ra,24(sp)
    80002ac2:	e822                	sd	s0,16(sp)
    80002ac4:	e426                	sd	s1,8(sp)
    80002ac6:	1000                	add	s0,sp,32
    80002ac8:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002aca:	00000097          	auipc	ra,0x0
    80002ace:	eee080e7          	jalr	-274(ra) # 800029b8 <argraw>
    80002ad2:	c088                	sw	a0,0(s1)
}
    80002ad4:	60e2                	ld	ra,24(sp)
    80002ad6:	6442                	ld	s0,16(sp)
    80002ad8:	64a2                	ld	s1,8(sp)
    80002ada:	6105                	add	sp,sp,32
    80002adc:	8082                	ret

0000000080002ade <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002ade:	1101                	add	sp,sp,-32
    80002ae0:	ec06                	sd	ra,24(sp)
    80002ae2:	e822                	sd	s0,16(sp)
    80002ae4:	e426                	sd	s1,8(sp)
    80002ae6:	1000                	add	s0,sp,32
    80002ae8:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002aea:	00000097          	auipc	ra,0x0
    80002aee:	ece080e7          	jalr	-306(ra) # 800029b8 <argraw>
    80002af2:	e088                	sd	a0,0(s1)
}
    80002af4:	60e2                	ld	ra,24(sp)
    80002af6:	6442                	ld	s0,16(sp)
    80002af8:	64a2                	ld	s1,8(sp)
    80002afa:	6105                	add	sp,sp,32
    80002afc:	8082                	ret

0000000080002afe <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002afe:	7179                	add	sp,sp,-48
    80002b00:	f406                	sd	ra,40(sp)
    80002b02:	f022                	sd	s0,32(sp)
    80002b04:	ec26                	sd	s1,24(sp)
    80002b06:	e84a                	sd	s2,16(sp)
    80002b08:	1800                	add	s0,sp,48
    80002b0a:	84ae                	mv	s1,a1
    80002b0c:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002b0e:	fd840593          	add	a1,s0,-40
    80002b12:	00000097          	auipc	ra,0x0
    80002b16:	fcc080e7          	jalr	-52(ra) # 80002ade <argaddr>
  return fetchstr(addr, buf, max);
    80002b1a:	864a                	mv	a2,s2
    80002b1c:	85a6                	mv	a1,s1
    80002b1e:	fd843503          	ld	a0,-40(s0)
    80002b22:	00000097          	auipc	ra,0x0
    80002b26:	f50080e7          	jalr	-176(ra) # 80002a72 <fetchstr>
}
    80002b2a:	70a2                	ld	ra,40(sp)
    80002b2c:	7402                	ld	s0,32(sp)
    80002b2e:	64e2                	ld	s1,24(sp)
    80002b30:	6942                	ld	s2,16(sp)
    80002b32:	6145                	add	sp,sp,48
    80002b34:	8082                	ret

0000000080002b36 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002b36:	1101                	add	sp,sp,-32
    80002b38:	ec06                	sd	ra,24(sp)
    80002b3a:	e822                	sd	s0,16(sp)
    80002b3c:	e426                	sd	s1,8(sp)
    80002b3e:	e04a                	sd	s2,0(sp)
    80002b40:	1000                	add	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002b42:	fffff097          	auipc	ra,0xfffff
    80002b46:	e62080e7          	jalr	-414(ra) # 800019a4 <myproc>
    80002b4a:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002b4c:	05853903          	ld	s2,88(a0)
    80002b50:	0a893783          	ld	a5,168(s2)
    80002b54:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002b58:	37fd                	addw	a5,a5,-1
    80002b5a:	4751                	li	a4,20
    80002b5c:	00f76f63          	bltu	a4,a5,80002b7a <syscall+0x44>
    80002b60:	00369713          	sll	a4,a3,0x3
    80002b64:	00006797          	auipc	a5,0x6
    80002b68:	8ec78793          	add	a5,a5,-1812 # 80008450 <syscalls>
    80002b6c:	97ba                	add	a5,a5,a4
    80002b6e:	639c                	ld	a5,0(a5)
    80002b70:	c789                	beqz	a5,80002b7a <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002b72:	9782                	jalr	a5
    80002b74:	06a93823          	sd	a0,112(s2)
    80002b78:	a839                	j	80002b96 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002b7a:	15848613          	add	a2,s1,344
    80002b7e:	588c                	lw	a1,48(s1)
    80002b80:	00006517          	auipc	a0,0x6
    80002b84:	89850513          	add	a0,a0,-1896 # 80008418 <states.0+0x150>
    80002b88:	ffffe097          	auipc	ra,0xffffe
    80002b8c:	9fc080e7          	jalr	-1540(ra) # 80000584 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002b90:	6cbc                	ld	a5,88(s1)
    80002b92:	577d                	li	a4,-1
    80002b94:	fbb8                	sd	a4,112(a5)
  }
}
    80002b96:	60e2                	ld	ra,24(sp)
    80002b98:	6442                	ld	s0,16(sp)
    80002b9a:	64a2                	ld	s1,8(sp)
    80002b9c:	6902                	ld	s2,0(sp)
    80002b9e:	6105                	add	sp,sp,32
    80002ba0:	8082                	ret

0000000080002ba2 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002ba2:	1101                	add	sp,sp,-32
    80002ba4:	ec06                	sd	ra,24(sp)
    80002ba6:	e822                	sd	s0,16(sp)
    80002ba8:	1000                	add	s0,sp,32
  int n;
  argint(0, &n);
    80002baa:	fec40593          	add	a1,s0,-20
    80002bae:	4501                	li	a0,0
    80002bb0:	00000097          	auipc	ra,0x0
    80002bb4:	f0e080e7          	jalr	-242(ra) # 80002abe <argint>
  exit(n);
    80002bb8:	fec42503          	lw	a0,-20(s0)
    80002bbc:	fffff097          	auipc	ra,0xfffff
    80002bc0:	5c4080e7          	jalr	1476(ra) # 80002180 <exit>
  return 0;  // not reached
}
    80002bc4:	4501                	li	a0,0
    80002bc6:	60e2                	ld	ra,24(sp)
    80002bc8:	6442                	ld	s0,16(sp)
    80002bca:	6105                	add	sp,sp,32
    80002bcc:	8082                	ret

0000000080002bce <sys_getpid>:

uint64
sys_getpid(void)
{
    80002bce:	1141                	add	sp,sp,-16
    80002bd0:	e406                	sd	ra,8(sp)
    80002bd2:	e022                	sd	s0,0(sp)
    80002bd4:	0800                	add	s0,sp,16
  return myproc()->pid;
    80002bd6:	fffff097          	auipc	ra,0xfffff
    80002bda:	dce080e7          	jalr	-562(ra) # 800019a4 <myproc>
}
    80002bde:	5908                	lw	a0,48(a0)
    80002be0:	60a2                	ld	ra,8(sp)
    80002be2:	6402                	ld	s0,0(sp)
    80002be4:	0141                	add	sp,sp,16
    80002be6:	8082                	ret

0000000080002be8 <sys_fork>:

uint64
sys_fork(void)
{
    80002be8:	1141                	add	sp,sp,-16
    80002bea:	e406                	sd	ra,8(sp)
    80002bec:	e022                	sd	s0,0(sp)
    80002bee:	0800                	add	s0,sp,16
  return fork();
    80002bf0:	fffff097          	auipc	ra,0xfffff
    80002bf4:	16a080e7          	jalr	362(ra) # 80001d5a <fork>
}
    80002bf8:	60a2                	ld	ra,8(sp)
    80002bfa:	6402                	ld	s0,0(sp)
    80002bfc:	0141                	add	sp,sp,16
    80002bfe:	8082                	ret

0000000080002c00 <sys_wait>:

uint64
sys_wait(void)
{
    80002c00:	1101                	add	sp,sp,-32
    80002c02:	ec06                	sd	ra,24(sp)
    80002c04:	e822                	sd	s0,16(sp)
    80002c06:	1000                	add	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002c08:	fe840593          	add	a1,s0,-24
    80002c0c:	4501                	li	a0,0
    80002c0e:	00000097          	auipc	ra,0x0
    80002c12:	ed0080e7          	jalr	-304(ra) # 80002ade <argaddr>
  return wait(p);
    80002c16:	fe843503          	ld	a0,-24(s0)
    80002c1a:	fffff097          	auipc	ra,0xfffff
    80002c1e:	70c080e7          	jalr	1804(ra) # 80002326 <wait>
}
    80002c22:	60e2                	ld	ra,24(sp)
    80002c24:	6442                	ld	s0,16(sp)
    80002c26:	6105                	add	sp,sp,32
    80002c28:	8082                	ret

0000000080002c2a <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002c2a:	7179                	add	sp,sp,-48
    80002c2c:	f406                	sd	ra,40(sp)
    80002c2e:	f022                	sd	s0,32(sp)
    80002c30:	ec26                	sd	s1,24(sp)
    80002c32:	1800                	add	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002c34:	fdc40593          	add	a1,s0,-36
    80002c38:	4501                	li	a0,0
    80002c3a:	00000097          	auipc	ra,0x0
    80002c3e:	e84080e7          	jalr	-380(ra) # 80002abe <argint>
  addr = myproc()->sz;
    80002c42:	fffff097          	auipc	ra,0xfffff
    80002c46:	d62080e7          	jalr	-670(ra) # 800019a4 <myproc>
    80002c4a:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    80002c4c:	fdc42503          	lw	a0,-36(s0)
    80002c50:	fffff097          	auipc	ra,0xfffff
    80002c54:	0ae080e7          	jalr	174(ra) # 80001cfe <growproc>
    80002c58:	00054863          	bltz	a0,80002c68 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002c5c:	8526                	mv	a0,s1
    80002c5e:	70a2                	ld	ra,40(sp)
    80002c60:	7402                	ld	s0,32(sp)
    80002c62:	64e2                	ld	s1,24(sp)
    80002c64:	6145                	add	sp,sp,48
    80002c66:	8082                	ret
    return -1;
    80002c68:	54fd                	li	s1,-1
    80002c6a:	bfcd                	j	80002c5c <sys_sbrk+0x32>

0000000080002c6c <sys_sleep>:

uint64
sys_sleep(void)
{
    80002c6c:	7139                	add	sp,sp,-64
    80002c6e:	fc06                	sd	ra,56(sp)
    80002c70:	f822                	sd	s0,48(sp)
    80002c72:	f426                	sd	s1,40(sp)
    80002c74:	f04a                	sd	s2,32(sp)
    80002c76:	ec4e                	sd	s3,24(sp)
    80002c78:	0080                	add	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002c7a:	fcc40593          	add	a1,s0,-52
    80002c7e:	4501                	li	a0,0
    80002c80:	00000097          	auipc	ra,0x0
    80002c84:	e3e080e7          	jalr	-450(ra) # 80002abe <argint>
  acquire(&tickslock);
    80002c88:	00014517          	auipc	a0,0x14
    80002c8c:	cd850513          	add	a0,a0,-808 # 80016960 <tickslock>
    80002c90:	ffffe097          	auipc	ra,0xffffe
    80002c94:	f40080e7          	jalr	-192(ra) # 80000bd0 <acquire>
  ticks0 = ticks;
    80002c98:	00006917          	auipc	s2,0x6
    80002c9c:	c2892903          	lw	s2,-984(s2) # 800088c0 <ticks>
  while(ticks - ticks0 < n){
    80002ca0:	fcc42783          	lw	a5,-52(s0)
    80002ca4:	cf9d                	beqz	a5,80002ce2 <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002ca6:	00014997          	auipc	s3,0x14
    80002caa:	cba98993          	add	s3,s3,-838 # 80016960 <tickslock>
    80002cae:	00006497          	auipc	s1,0x6
    80002cb2:	c1248493          	add	s1,s1,-1006 # 800088c0 <ticks>
    if(killed(myproc())){
    80002cb6:	fffff097          	auipc	ra,0xfffff
    80002cba:	cee080e7          	jalr	-786(ra) # 800019a4 <myproc>
    80002cbe:	fffff097          	auipc	ra,0xfffff
    80002cc2:	636080e7          	jalr	1590(ra) # 800022f4 <killed>
    80002cc6:	ed15                	bnez	a0,80002d02 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002cc8:	85ce                	mv	a1,s3
    80002cca:	8526                	mv	a0,s1
    80002ccc:	fffff097          	auipc	ra,0xfffff
    80002cd0:	380080e7          	jalr	896(ra) # 8000204c <sleep>
  while(ticks - ticks0 < n){
    80002cd4:	409c                	lw	a5,0(s1)
    80002cd6:	412787bb          	subw	a5,a5,s2
    80002cda:	fcc42703          	lw	a4,-52(s0)
    80002cde:	fce7ece3          	bltu	a5,a4,80002cb6 <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002ce2:	00014517          	auipc	a0,0x14
    80002ce6:	c7e50513          	add	a0,a0,-898 # 80016960 <tickslock>
    80002cea:	ffffe097          	auipc	ra,0xffffe
    80002cee:	f9a080e7          	jalr	-102(ra) # 80000c84 <release>
  return 0;
    80002cf2:	4501                	li	a0,0
}
    80002cf4:	70e2                	ld	ra,56(sp)
    80002cf6:	7442                	ld	s0,48(sp)
    80002cf8:	74a2                	ld	s1,40(sp)
    80002cfa:	7902                	ld	s2,32(sp)
    80002cfc:	69e2                	ld	s3,24(sp)
    80002cfe:	6121                	add	sp,sp,64
    80002d00:	8082                	ret
      release(&tickslock);
    80002d02:	00014517          	auipc	a0,0x14
    80002d06:	c5e50513          	add	a0,a0,-930 # 80016960 <tickslock>
    80002d0a:	ffffe097          	auipc	ra,0xffffe
    80002d0e:	f7a080e7          	jalr	-134(ra) # 80000c84 <release>
      return -1;
    80002d12:	557d                	li	a0,-1
    80002d14:	b7c5                	j	80002cf4 <sys_sleep+0x88>

0000000080002d16 <sys_kill>:

uint64
sys_kill(void)
{
    80002d16:	1101                	add	sp,sp,-32
    80002d18:	ec06                	sd	ra,24(sp)
    80002d1a:	e822                	sd	s0,16(sp)
    80002d1c:	1000                	add	s0,sp,32
  int pid;

  argint(0, &pid);
    80002d1e:	fec40593          	add	a1,s0,-20
    80002d22:	4501                	li	a0,0
    80002d24:	00000097          	auipc	ra,0x0
    80002d28:	d9a080e7          	jalr	-614(ra) # 80002abe <argint>
  return kill(pid);
    80002d2c:	fec42503          	lw	a0,-20(s0)
    80002d30:	fffff097          	auipc	ra,0xfffff
    80002d34:	526080e7          	jalr	1318(ra) # 80002256 <kill>
}
    80002d38:	60e2                	ld	ra,24(sp)
    80002d3a:	6442                	ld	s0,16(sp)
    80002d3c:	6105                	add	sp,sp,32
    80002d3e:	8082                	ret

0000000080002d40 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002d40:	1101                	add	sp,sp,-32
    80002d42:	ec06                	sd	ra,24(sp)
    80002d44:	e822                	sd	s0,16(sp)
    80002d46:	e426                	sd	s1,8(sp)
    80002d48:	1000                	add	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002d4a:	00014517          	auipc	a0,0x14
    80002d4e:	c1650513          	add	a0,a0,-1002 # 80016960 <tickslock>
    80002d52:	ffffe097          	auipc	ra,0xffffe
    80002d56:	e7e080e7          	jalr	-386(ra) # 80000bd0 <acquire>
  xticks = ticks;
    80002d5a:	00006497          	auipc	s1,0x6
    80002d5e:	b664a483          	lw	s1,-1178(s1) # 800088c0 <ticks>
  release(&tickslock);
    80002d62:	00014517          	auipc	a0,0x14
    80002d66:	bfe50513          	add	a0,a0,-1026 # 80016960 <tickslock>
    80002d6a:	ffffe097          	auipc	ra,0xffffe
    80002d6e:	f1a080e7          	jalr	-230(ra) # 80000c84 <release>
  return xticks;
}
    80002d72:	02049513          	sll	a0,s1,0x20
    80002d76:	9101                	srl	a0,a0,0x20
    80002d78:	60e2                	ld	ra,24(sp)
    80002d7a:	6442                	ld	s0,16(sp)
    80002d7c:	64a2                	ld	s1,8(sp)
    80002d7e:	6105                	add	sp,sp,32
    80002d80:	8082                	ret

0000000080002d82 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002d82:	7179                	add	sp,sp,-48
    80002d84:	f406                	sd	ra,40(sp)
    80002d86:	f022                	sd	s0,32(sp)
    80002d88:	ec26                	sd	s1,24(sp)
    80002d8a:	e84a                	sd	s2,16(sp)
    80002d8c:	e44e                	sd	s3,8(sp)
    80002d8e:	e052                	sd	s4,0(sp)
    80002d90:	1800                	add	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002d92:	00005597          	auipc	a1,0x5
    80002d96:	76e58593          	add	a1,a1,1902 # 80008500 <syscalls+0xb0>
    80002d9a:	00014517          	auipc	a0,0x14
    80002d9e:	bde50513          	add	a0,a0,-1058 # 80016978 <bcache>
    80002da2:	ffffe097          	auipc	ra,0xffffe
    80002da6:	d9e080e7          	jalr	-610(ra) # 80000b40 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002daa:	0001c797          	auipc	a5,0x1c
    80002dae:	bce78793          	add	a5,a5,-1074 # 8001e978 <bcache+0x8000>
    80002db2:	0001c717          	auipc	a4,0x1c
    80002db6:	e2e70713          	add	a4,a4,-466 # 8001ebe0 <bcache+0x8268>
    80002dba:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002dbe:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002dc2:	00014497          	auipc	s1,0x14
    80002dc6:	bce48493          	add	s1,s1,-1074 # 80016990 <bcache+0x18>
    b->next = bcache.head.next;
    80002dca:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002dcc:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002dce:	00005a17          	auipc	s4,0x5
    80002dd2:	73aa0a13          	add	s4,s4,1850 # 80008508 <syscalls+0xb8>
    b->next = bcache.head.next;
    80002dd6:	2b893783          	ld	a5,696(s2)
    80002dda:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002ddc:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002de0:	85d2                	mv	a1,s4
    80002de2:	01048513          	add	a0,s1,16
    80002de6:	00001097          	auipc	ra,0x1
    80002dea:	496080e7          	jalr	1174(ra) # 8000427c <initsleeplock>
    bcache.head.next->prev = b;
    80002dee:	2b893783          	ld	a5,696(s2)
    80002df2:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002df4:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002df8:	45848493          	add	s1,s1,1112
    80002dfc:	fd349de3          	bne	s1,s3,80002dd6 <binit+0x54>
  }
}
    80002e00:	70a2                	ld	ra,40(sp)
    80002e02:	7402                	ld	s0,32(sp)
    80002e04:	64e2                	ld	s1,24(sp)
    80002e06:	6942                	ld	s2,16(sp)
    80002e08:	69a2                	ld	s3,8(sp)
    80002e0a:	6a02                	ld	s4,0(sp)
    80002e0c:	6145                	add	sp,sp,48
    80002e0e:	8082                	ret

0000000080002e10 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002e10:	7179                	add	sp,sp,-48
    80002e12:	f406                	sd	ra,40(sp)
    80002e14:	f022                	sd	s0,32(sp)
    80002e16:	ec26                	sd	s1,24(sp)
    80002e18:	e84a                	sd	s2,16(sp)
    80002e1a:	e44e                	sd	s3,8(sp)
    80002e1c:	1800                	add	s0,sp,48
    80002e1e:	892a                	mv	s2,a0
    80002e20:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002e22:	00014517          	auipc	a0,0x14
    80002e26:	b5650513          	add	a0,a0,-1194 # 80016978 <bcache>
    80002e2a:	ffffe097          	auipc	ra,0xffffe
    80002e2e:	da6080e7          	jalr	-602(ra) # 80000bd0 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002e32:	0001c497          	auipc	s1,0x1c
    80002e36:	dfe4b483          	ld	s1,-514(s1) # 8001ec30 <bcache+0x82b8>
    80002e3a:	0001c797          	auipc	a5,0x1c
    80002e3e:	da678793          	add	a5,a5,-602 # 8001ebe0 <bcache+0x8268>
    80002e42:	02f48f63          	beq	s1,a5,80002e80 <bread+0x70>
    80002e46:	873e                	mv	a4,a5
    80002e48:	a021                	j	80002e50 <bread+0x40>
    80002e4a:	68a4                	ld	s1,80(s1)
    80002e4c:	02e48a63          	beq	s1,a4,80002e80 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002e50:	449c                	lw	a5,8(s1)
    80002e52:	ff279ce3          	bne	a5,s2,80002e4a <bread+0x3a>
    80002e56:	44dc                	lw	a5,12(s1)
    80002e58:	ff3799e3          	bne	a5,s3,80002e4a <bread+0x3a>
      b->refcnt++;
    80002e5c:	40bc                	lw	a5,64(s1)
    80002e5e:	2785                	addw	a5,a5,1
    80002e60:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002e62:	00014517          	auipc	a0,0x14
    80002e66:	b1650513          	add	a0,a0,-1258 # 80016978 <bcache>
    80002e6a:	ffffe097          	auipc	ra,0xffffe
    80002e6e:	e1a080e7          	jalr	-486(ra) # 80000c84 <release>
      acquiresleep(&b->lock);
    80002e72:	01048513          	add	a0,s1,16
    80002e76:	00001097          	auipc	ra,0x1
    80002e7a:	440080e7          	jalr	1088(ra) # 800042b6 <acquiresleep>
      return b;
    80002e7e:	a8b9                	j	80002edc <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002e80:	0001c497          	auipc	s1,0x1c
    80002e84:	da84b483          	ld	s1,-600(s1) # 8001ec28 <bcache+0x82b0>
    80002e88:	0001c797          	auipc	a5,0x1c
    80002e8c:	d5878793          	add	a5,a5,-680 # 8001ebe0 <bcache+0x8268>
    80002e90:	00f48863          	beq	s1,a5,80002ea0 <bread+0x90>
    80002e94:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002e96:	40bc                	lw	a5,64(s1)
    80002e98:	cf81                	beqz	a5,80002eb0 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002e9a:	64a4                	ld	s1,72(s1)
    80002e9c:	fee49de3          	bne	s1,a4,80002e96 <bread+0x86>
  panic("bget: no buffers");
    80002ea0:	00005517          	auipc	a0,0x5
    80002ea4:	67050513          	add	a0,a0,1648 # 80008510 <syscalls+0xc0>
    80002ea8:	ffffd097          	auipc	ra,0xffffd
    80002eac:	692080e7          	jalr	1682(ra) # 8000053a <panic>
      b->dev = dev;
    80002eb0:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80002eb4:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80002eb8:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002ebc:	4785                	li	a5,1
    80002ebe:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002ec0:	00014517          	auipc	a0,0x14
    80002ec4:	ab850513          	add	a0,a0,-1352 # 80016978 <bcache>
    80002ec8:	ffffe097          	auipc	ra,0xffffe
    80002ecc:	dbc080e7          	jalr	-580(ra) # 80000c84 <release>
      acquiresleep(&b->lock);
    80002ed0:	01048513          	add	a0,s1,16
    80002ed4:	00001097          	auipc	ra,0x1
    80002ed8:	3e2080e7          	jalr	994(ra) # 800042b6 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002edc:	409c                	lw	a5,0(s1)
    80002ede:	cb89                	beqz	a5,80002ef0 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002ee0:	8526                	mv	a0,s1
    80002ee2:	70a2                	ld	ra,40(sp)
    80002ee4:	7402                	ld	s0,32(sp)
    80002ee6:	64e2                	ld	s1,24(sp)
    80002ee8:	6942                	ld	s2,16(sp)
    80002eea:	69a2                	ld	s3,8(sp)
    80002eec:	6145                	add	sp,sp,48
    80002eee:	8082                	ret
    virtio_disk_rw(b, 0);
    80002ef0:	4581                	li	a1,0
    80002ef2:	8526                	mv	a0,s1
    80002ef4:	00003097          	auipc	ra,0x3
    80002ef8:	f7e080e7          	jalr	-130(ra) # 80005e72 <virtio_disk_rw>
    b->valid = 1;
    80002efc:	4785                	li	a5,1
    80002efe:	c09c                	sw	a5,0(s1)
  return b;
    80002f00:	b7c5                	j	80002ee0 <bread+0xd0>

0000000080002f02 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002f02:	1101                	add	sp,sp,-32
    80002f04:	ec06                	sd	ra,24(sp)
    80002f06:	e822                	sd	s0,16(sp)
    80002f08:	e426                	sd	s1,8(sp)
    80002f0a:	1000                	add	s0,sp,32
    80002f0c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002f0e:	0541                	add	a0,a0,16
    80002f10:	00001097          	auipc	ra,0x1
    80002f14:	440080e7          	jalr	1088(ra) # 80004350 <holdingsleep>
    80002f18:	cd01                	beqz	a0,80002f30 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80002f1a:	4585                	li	a1,1
    80002f1c:	8526                	mv	a0,s1
    80002f1e:	00003097          	auipc	ra,0x3
    80002f22:	f54080e7          	jalr	-172(ra) # 80005e72 <virtio_disk_rw>
}
    80002f26:	60e2                	ld	ra,24(sp)
    80002f28:	6442                	ld	s0,16(sp)
    80002f2a:	64a2                	ld	s1,8(sp)
    80002f2c:	6105                	add	sp,sp,32
    80002f2e:	8082                	ret
    panic("bwrite");
    80002f30:	00005517          	auipc	a0,0x5
    80002f34:	5f850513          	add	a0,a0,1528 # 80008528 <syscalls+0xd8>
    80002f38:	ffffd097          	auipc	ra,0xffffd
    80002f3c:	602080e7          	jalr	1538(ra) # 8000053a <panic>

0000000080002f40 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80002f40:	1101                	add	sp,sp,-32
    80002f42:	ec06                	sd	ra,24(sp)
    80002f44:	e822                	sd	s0,16(sp)
    80002f46:	e426                	sd	s1,8(sp)
    80002f48:	e04a                	sd	s2,0(sp)
    80002f4a:	1000                	add	s0,sp,32
    80002f4c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002f4e:	01050913          	add	s2,a0,16
    80002f52:	854a                	mv	a0,s2
    80002f54:	00001097          	auipc	ra,0x1
    80002f58:	3fc080e7          	jalr	1020(ra) # 80004350 <holdingsleep>
    80002f5c:	c925                	beqz	a0,80002fcc <brelse+0x8c>
    panic("brelse");

  releasesleep(&b->lock);
    80002f5e:	854a                	mv	a0,s2
    80002f60:	00001097          	auipc	ra,0x1
    80002f64:	3ac080e7          	jalr	940(ra) # 8000430c <releasesleep>

  acquire(&bcache.lock);
    80002f68:	00014517          	auipc	a0,0x14
    80002f6c:	a1050513          	add	a0,a0,-1520 # 80016978 <bcache>
    80002f70:	ffffe097          	auipc	ra,0xffffe
    80002f74:	c60080e7          	jalr	-928(ra) # 80000bd0 <acquire>
  b->refcnt--;
    80002f78:	40bc                	lw	a5,64(s1)
    80002f7a:	37fd                	addw	a5,a5,-1
    80002f7c:	0007871b          	sext.w	a4,a5
    80002f80:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80002f82:	e71d                	bnez	a4,80002fb0 <brelse+0x70>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80002f84:	68b8                	ld	a4,80(s1)
    80002f86:	64bc                	ld	a5,72(s1)
    80002f88:	e73c                	sd	a5,72(a4)
    b->prev->next = b->next;
    80002f8a:	68b8                	ld	a4,80(s1)
    80002f8c:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80002f8e:	0001c797          	auipc	a5,0x1c
    80002f92:	9ea78793          	add	a5,a5,-1558 # 8001e978 <bcache+0x8000>
    80002f96:	2b87b703          	ld	a4,696(a5)
    80002f9a:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80002f9c:	0001c717          	auipc	a4,0x1c
    80002fa0:	c4470713          	add	a4,a4,-956 # 8001ebe0 <bcache+0x8268>
    80002fa4:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80002fa6:	2b87b703          	ld	a4,696(a5)
    80002faa:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80002fac:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80002fb0:	00014517          	auipc	a0,0x14
    80002fb4:	9c850513          	add	a0,a0,-1592 # 80016978 <bcache>
    80002fb8:	ffffe097          	auipc	ra,0xffffe
    80002fbc:	ccc080e7          	jalr	-820(ra) # 80000c84 <release>
}
    80002fc0:	60e2                	ld	ra,24(sp)
    80002fc2:	6442                	ld	s0,16(sp)
    80002fc4:	64a2                	ld	s1,8(sp)
    80002fc6:	6902                	ld	s2,0(sp)
    80002fc8:	6105                	add	sp,sp,32
    80002fca:	8082                	ret
    panic("brelse");
    80002fcc:	00005517          	auipc	a0,0x5
    80002fd0:	56450513          	add	a0,a0,1380 # 80008530 <syscalls+0xe0>
    80002fd4:	ffffd097          	auipc	ra,0xffffd
    80002fd8:	566080e7          	jalr	1382(ra) # 8000053a <panic>

0000000080002fdc <bpin>:

void
bpin(struct buf *b) {
    80002fdc:	1101                	add	sp,sp,-32
    80002fde:	ec06                	sd	ra,24(sp)
    80002fe0:	e822                	sd	s0,16(sp)
    80002fe2:	e426                	sd	s1,8(sp)
    80002fe4:	1000                	add	s0,sp,32
    80002fe6:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80002fe8:	00014517          	auipc	a0,0x14
    80002fec:	99050513          	add	a0,a0,-1648 # 80016978 <bcache>
    80002ff0:	ffffe097          	auipc	ra,0xffffe
    80002ff4:	be0080e7          	jalr	-1056(ra) # 80000bd0 <acquire>
  b->refcnt++;
    80002ff8:	40bc                	lw	a5,64(s1)
    80002ffa:	2785                	addw	a5,a5,1
    80002ffc:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80002ffe:	00014517          	auipc	a0,0x14
    80003002:	97a50513          	add	a0,a0,-1670 # 80016978 <bcache>
    80003006:	ffffe097          	auipc	ra,0xffffe
    8000300a:	c7e080e7          	jalr	-898(ra) # 80000c84 <release>
}
    8000300e:	60e2                	ld	ra,24(sp)
    80003010:	6442                	ld	s0,16(sp)
    80003012:	64a2                	ld	s1,8(sp)
    80003014:	6105                	add	sp,sp,32
    80003016:	8082                	ret

0000000080003018 <bunpin>:

void
bunpin(struct buf *b) {
    80003018:	1101                	add	sp,sp,-32
    8000301a:	ec06                	sd	ra,24(sp)
    8000301c:	e822                	sd	s0,16(sp)
    8000301e:	e426                	sd	s1,8(sp)
    80003020:	1000                	add	s0,sp,32
    80003022:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003024:	00014517          	auipc	a0,0x14
    80003028:	95450513          	add	a0,a0,-1708 # 80016978 <bcache>
    8000302c:	ffffe097          	auipc	ra,0xffffe
    80003030:	ba4080e7          	jalr	-1116(ra) # 80000bd0 <acquire>
  b->refcnt--;
    80003034:	40bc                	lw	a5,64(s1)
    80003036:	37fd                	addw	a5,a5,-1
    80003038:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000303a:	00014517          	auipc	a0,0x14
    8000303e:	93e50513          	add	a0,a0,-1730 # 80016978 <bcache>
    80003042:	ffffe097          	auipc	ra,0xffffe
    80003046:	c42080e7          	jalr	-958(ra) # 80000c84 <release>
}
    8000304a:	60e2                	ld	ra,24(sp)
    8000304c:	6442                	ld	s0,16(sp)
    8000304e:	64a2                	ld	s1,8(sp)
    80003050:	6105                	add	sp,sp,32
    80003052:	8082                	ret

0000000080003054 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003054:	1101                	add	sp,sp,-32
    80003056:	ec06                	sd	ra,24(sp)
    80003058:	e822                	sd	s0,16(sp)
    8000305a:	e426                	sd	s1,8(sp)
    8000305c:	e04a                	sd	s2,0(sp)
    8000305e:	1000                	add	s0,sp,32
    80003060:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003062:	00d5d59b          	srlw	a1,a1,0xd
    80003066:	0001c797          	auipc	a5,0x1c
    8000306a:	fee7a783          	lw	a5,-18(a5) # 8001f054 <sb+0x1c>
    8000306e:	9dbd                	addw	a1,a1,a5
    80003070:	00000097          	auipc	ra,0x0
    80003074:	da0080e7          	jalr	-608(ra) # 80002e10 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003078:	0074f713          	and	a4,s1,7
    8000307c:	4785                	li	a5,1
    8000307e:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003082:	14ce                	sll	s1,s1,0x33
    80003084:	90d9                	srl	s1,s1,0x36
    80003086:	00950733          	add	a4,a0,s1
    8000308a:	05874703          	lbu	a4,88(a4)
    8000308e:	00e7f6b3          	and	a3,a5,a4
    80003092:	c69d                	beqz	a3,800030c0 <bfree+0x6c>
    80003094:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003096:	94aa                	add	s1,s1,a0
    80003098:	fff7c793          	not	a5,a5
    8000309c:	8f7d                	and	a4,a4,a5
    8000309e:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    800030a2:	00001097          	auipc	ra,0x1
    800030a6:	0f6080e7          	jalr	246(ra) # 80004198 <log_write>
  brelse(bp);
    800030aa:	854a                	mv	a0,s2
    800030ac:	00000097          	auipc	ra,0x0
    800030b0:	e94080e7          	jalr	-364(ra) # 80002f40 <brelse>
}
    800030b4:	60e2                	ld	ra,24(sp)
    800030b6:	6442                	ld	s0,16(sp)
    800030b8:	64a2                	ld	s1,8(sp)
    800030ba:	6902                	ld	s2,0(sp)
    800030bc:	6105                	add	sp,sp,32
    800030be:	8082                	ret
    panic("freeing free block");
    800030c0:	00005517          	auipc	a0,0x5
    800030c4:	47850513          	add	a0,a0,1144 # 80008538 <syscalls+0xe8>
    800030c8:	ffffd097          	auipc	ra,0xffffd
    800030cc:	472080e7          	jalr	1138(ra) # 8000053a <panic>

00000000800030d0 <balloc>:
{
    800030d0:	711d                	add	sp,sp,-96
    800030d2:	ec86                	sd	ra,88(sp)
    800030d4:	e8a2                	sd	s0,80(sp)
    800030d6:	e4a6                	sd	s1,72(sp)
    800030d8:	e0ca                	sd	s2,64(sp)
    800030da:	fc4e                	sd	s3,56(sp)
    800030dc:	f852                	sd	s4,48(sp)
    800030de:	f456                	sd	s5,40(sp)
    800030e0:	f05a                	sd	s6,32(sp)
    800030e2:	ec5e                	sd	s7,24(sp)
    800030e4:	e862                	sd	s8,16(sp)
    800030e6:	e466                	sd	s9,8(sp)
    800030e8:	1080                	add	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800030ea:	0001c797          	auipc	a5,0x1c
    800030ee:	f527a783          	lw	a5,-174(a5) # 8001f03c <sb+0x4>
    800030f2:	cff5                	beqz	a5,800031ee <balloc+0x11e>
    800030f4:	8baa                	mv	s7,a0
    800030f6:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800030f8:	0001cb17          	auipc	s6,0x1c
    800030fc:	f40b0b13          	add	s6,s6,-192 # 8001f038 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003100:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003102:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003104:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003106:	6c89                	lui	s9,0x2
    80003108:	a061                	j	80003190 <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000310a:	97ca                	add	a5,a5,s2
    8000310c:	8e55                	or	a2,a2,a3
    8000310e:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80003112:	854a                	mv	a0,s2
    80003114:	00001097          	auipc	ra,0x1
    80003118:	084080e7          	jalr	132(ra) # 80004198 <log_write>
        brelse(bp);
    8000311c:	854a                	mv	a0,s2
    8000311e:	00000097          	auipc	ra,0x0
    80003122:	e22080e7          	jalr	-478(ra) # 80002f40 <brelse>
  bp = bread(dev, bno);
    80003126:	85a6                	mv	a1,s1
    80003128:	855e                	mv	a0,s7
    8000312a:	00000097          	auipc	ra,0x0
    8000312e:	ce6080e7          	jalr	-794(ra) # 80002e10 <bread>
    80003132:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003134:	40000613          	li	a2,1024
    80003138:	4581                	li	a1,0
    8000313a:	05850513          	add	a0,a0,88
    8000313e:	ffffe097          	auipc	ra,0xffffe
    80003142:	b8e080e7          	jalr	-1138(ra) # 80000ccc <memset>
  log_write(bp);
    80003146:	854a                	mv	a0,s2
    80003148:	00001097          	auipc	ra,0x1
    8000314c:	050080e7          	jalr	80(ra) # 80004198 <log_write>
  brelse(bp);
    80003150:	854a                	mv	a0,s2
    80003152:	00000097          	auipc	ra,0x0
    80003156:	dee080e7          	jalr	-530(ra) # 80002f40 <brelse>
}
    8000315a:	8526                	mv	a0,s1
    8000315c:	60e6                	ld	ra,88(sp)
    8000315e:	6446                	ld	s0,80(sp)
    80003160:	64a6                	ld	s1,72(sp)
    80003162:	6906                	ld	s2,64(sp)
    80003164:	79e2                	ld	s3,56(sp)
    80003166:	7a42                	ld	s4,48(sp)
    80003168:	7aa2                	ld	s5,40(sp)
    8000316a:	7b02                	ld	s6,32(sp)
    8000316c:	6be2                	ld	s7,24(sp)
    8000316e:	6c42                	ld	s8,16(sp)
    80003170:	6ca2                	ld	s9,8(sp)
    80003172:	6125                	add	sp,sp,96
    80003174:	8082                	ret
    brelse(bp);
    80003176:	854a                	mv	a0,s2
    80003178:	00000097          	auipc	ra,0x0
    8000317c:	dc8080e7          	jalr	-568(ra) # 80002f40 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003180:	015c87bb          	addw	a5,s9,s5
    80003184:	00078a9b          	sext.w	s5,a5
    80003188:	004b2703          	lw	a4,4(s6)
    8000318c:	06eaf163          	bgeu	s5,a4,800031ee <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    80003190:	41fad79b          	sraw	a5,s5,0x1f
    80003194:	0137d79b          	srlw	a5,a5,0x13
    80003198:	015787bb          	addw	a5,a5,s5
    8000319c:	40d7d79b          	sraw	a5,a5,0xd
    800031a0:	01cb2583          	lw	a1,28(s6)
    800031a4:	9dbd                	addw	a1,a1,a5
    800031a6:	855e                	mv	a0,s7
    800031a8:	00000097          	auipc	ra,0x0
    800031ac:	c68080e7          	jalr	-920(ra) # 80002e10 <bread>
    800031b0:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800031b2:	004b2503          	lw	a0,4(s6)
    800031b6:	000a849b          	sext.w	s1,s5
    800031ba:	8762                	mv	a4,s8
    800031bc:	faa4fde3          	bgeu	s1,a0,80003176 <balloc+0xa6>
      m = 1 << (bi % 8);
    800031c0:	00777693          	and	a3,a4,7
    800031c4:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800031c8:	41f7579b          	sraw	a5,a4,0x1f
    800031cc:	01d7d79b          	srlw	a5,a5,0x1d
    800031d0:	9fb9                	addw	a5,a5,a4
    800031d2:	4037d79b          	sraw	a5,a5,0x3
    800031d6:	00f90633          	add	a2,s2,a5
    800031da:	05864603          	lbu	a2,88(a2)
    800031de:	00c6f5b3          	and	a1,a3,a2
    800031e2:	d585                	beqz	a1,8000310a <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800031e4:	2705                	addw	a4,a4,1
    800031e6:	2485                	addw	s1,s1,1
    800031e8:	fd471ae3          	bne	a4,s4,800031bc <balloc+0xec>
    800031ec:	b769                	j	80003176 <balloc+0xa6>
  printf("balloc: out of blocks\n");
    800031ee:	00005517          	auipc	a0,0x5
    800031f2:	36250513          	add	a0,a0,866 # 80008550 <syscalls+0x100>
    800031f6:	ffffd097          	auipc	ra,0xffffd
    800031fa:	38e080e7          	jalr	910(ra) # 80000584 <printf>
  return 0;
    800031fe:	4481                	li	s1,0
    80003200:	bfa9                	j	8000315a <balloc+0x8a>

0000000080003202 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003202:	7179                	add	sp,sp,-48
    80003204:	f406                	sd	ra,40(sp)
    80003206:	f022                	sd	s0,32(sp)
    80003208:	ec26                	sd	s1,24(sp)
    8000320a:	e84a                	sd	s2,16(sp)
    8000320c:	e44e                	sd	s3,8(sp)
    8000320e:	e052                	sd	s4,0(sp)
    80003210:	1800                	add	s0,sp,48
    80003212:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003214:	47ad                	li	a5,11
    80003216:	02b7e863          	bltu	a5,a1,80003246 <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    8000321a:	02059793          	sll	a5,a1,0x20
    8000321e:	01e7d593          	srl	a1,a5,0x1e
    80003222:	00b504b3          	add	s1,a0,a1
    80003226:	0504a903          	lw	s2,80(s1)
    8000322a:	06091e63          	bnez	s2,800032a6 <bmap+0xa4>
      addr = balloc(ip->dev);
    8000322e:	4108                	lw	a0,0(a0)
    80003230:	00000097          	auipc	ra,0x0
    80003234:	ea0080e7          	jalr	-352(ra) # 800030d0 <balloc>
    80003238:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000323c:	06090563          	beqz	s2,800032a6 <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    80003240:	0524a823          	sw	s2,80(s1)
    80003244:	a08d                	j	800032a6 <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003246:	ff45849b          	addw	s1,a1,-12
    8000324a:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000324e:	0ff00793          	li	a5,255
    80003252:	08e7e563          	bltu	a5,a4,800032dc <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003256:	08052903          	lw	s2,128(a0)
    8000325a:	00091d63          	bnez	s2,80003274 <bmap+0x72>
      addr = balloc(ip->dev);
    8000325e:	4108                	lw	a0,0(a0)
    80003260:	00000097          	auipc	ra,0x0
    80003264:	e70080e7          	jalr	-400(ra) # 800030d0 <balloc>
    80003268:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000326c:	02090d63          	beqz	s2,800032a6 <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003270:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003274:	85ca                	mv	a1,s2
    80003276:	0009a503          	lw	a0,0(s3)
    8000327a:	00000097          	auipc	ra,0x0
    8000327e:	b96080e7          	jalr	-1130(ra) # 80002e10 <bread>
    80003282:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003284:	05850793          	add	a5,a0,88
    if((addr = a[bn]) == 0){
    80003288:	02049713          	sll	a4,s1,0x20
    8000328c:	01e75593          	srl	a1,a4,0x1e
    80003290:	00b784b3          	add	s1,a5,a1
    80003294:	0004a903          	lw	s2,0(s1)
    80003298:	02090063          	beqz	s2,800032b8 <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    8000329c:	8552                	mv	a0,s4
    8000329e:	00000097          	auipc	ra,0x0
    800032a2:	ca2080e7          	jalr	-862(ra) # 80002f40 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800032a6:	854a                	mv	a0,s2
    800032a8:	70a2                	ld	ra,40(sp)
    800032aa:	7402                	ld	s0,32(sp)
    800032ac:	64e2                	ld	s1,24(sp)
    800032ae:	6942                	ld	s2,16(sp)
    800032b0:	69a2                	ld	s3,8(sp)
    800032b2:	6a02                	ld	s4,0(sp)
    800032b4:	6145                	add	sp,sp,48
    800032b6:	8082                	ret
      addr = balloc(ip->dev);
    800032b8:	0009a503          	lw	a0,0(s3)
    800032bc:	00000097          	auipc	ra,0x0
    800032c0:	e14080e7          	jalr	-492(ra) # 800030d0 <balloc>
    800032c4:	0005091b          	sext.w	s2,a0
      if(addr){
    800032c8:	fc090ae3          	beqz	s2,8000329c <bmap+0x9a>
        a[bn] = addr;
    800032cc:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    800032d0:	8552                	mv	a0,s4
    800032d2:	00001097          	auipc	ra,0x1
    800032d6:	ec6080e7          	jalr	-314(ra) # 80004198 <log_write>
    800032da:	b7c9                	j	8000329c <bmap+0x9a>
  panic("bmap: out of range");
    800032dc:	00005517          	auipc	a0,0x5
    800032e0:	28c50513          	add	a0,a0,652 # 80008568 <syscalls+0x118>
    800032e4:	ffffd097          	auipc	ra,0xffffd
    800032e8:	256080e7          	jalr	598(ra) # 8000053a <panic>

00000000800032ec <iget>:
{
    800032ec:	7179                	add	sp,sp,-48
    800032ee:	f406                	sd	ra,40(sp)
    800032f0:	f022                	sd	s0,32(sp)
    800032f2:	ec26                	sd	s1,24(sp)
    800032f4:	e84a                	sd	s2,16(sp)
    800032f6:	e44e                	sd	s3,8(sp)
    800032f8:	e052                	sd	s4,0(sp)
    800032fa:	1800                	add	s0,sp,48
    800032fc:	89aa                	mv	s3,a0
    800032fe:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003300:	0001c517          	auipc	a0,0x1c
    80003304:	d5850513          	add	a0,a0,-680 # 8001f058 <itable>
    80003308:	ffffe097          	auipc	ra,0xffffe
    8000330c:	8c8080e7          	jalr	-1848(ra) # 80000bd0 <acquire>
  empty = 0;
    80003310:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003312:	0001c497          	auipc	s1,0x1c
    80003316:	d5e48493          	add	s1,s1,-674 # 8001f070 <itable+0x18>
    8000331a:	0001d697          	auipc	a3,0x1d
    8000331e:	7e668693          	add	a3,a3,2022 # 80020b00 <log>
    80003322:	a039                	j	80003330 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003324:	02090b63          	beqz	s2,8000335a <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003328:	08848493          	add	s1,s1,136
    8000332c:	02d48a63          	beq	s1,a3,80003360 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003330:	449c                	lw	a5,8(s1)
    80003332:	fef059e3          	blez	a5,80003324 <iget+0x38>
    80003336:	4098                	lw	a4,0(s1)
    80003338:	ff3716e3          	bne	a4,s3,80003324 <iget+0x38>
    8000333c:	40d8                	lw	a4,4(s1)
    8000333e:	ff4713e3          	bne	a4,s4,80003324 <iget+0x38>
      ip->ref++;
    80003342:	2785                	addw	a5,a5,1
    80003344:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003346:	0001c517          	auipc	a0,0x1c
    8000334a:	d1250513          	add	a0,a0,-750 # 8001f058 <itable>
    8000334e:	ffffe097          	auipc	ra,0xffffe
    80003352:	936080e7          	jalr	-1738(ra) # 80000c84 <release>
      return ip;
    80003356:	8926                	mv	s2,s1
    80003358:	a03d                	j	80003386 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000335a:	f7f9                	bnez	a5,80003328 <iget+0x3c>
    8000335c:	8926                	mv	s2,s1
    8000335e:	b7e9                	j	80003328 <iget+0x3c>
  if(empty == 0)
    80003360:	02090c63          	beqz	s2,80003398 <iget+0xac>
  ip->dev = dev;
    80003364:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003368:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000336c:	4785                	li	a5,1
    8000336e:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003372:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003376:	0001c517          	auipc	a0,0x1c
    8000337a:	ce250513          	add	a0,a0,-798 # 8001f058 <itable>
    8000337e:	ffffe097          	auipc	ra,0xffffe
    80003382:	906080e7          	jalr	-1786(ra) # 80000c84 <release>
}
    80003386:	854a                	mv	a0,s2
    80003388:	70a2                	ld	ra,40(sp)
    8000338a:	7402                	ld	s0,32(sp)
    8000338c:	64e2                	ld	s1,24(sp)
    8000338e:	6942                	ld	s2,16(sp)
    80003390:	69a2                	ld	s3,8(sp)
    80003392:	6a02                	ld	s4,0(sp)
    80003394:	6145                	add	sp,sp,48
    80003396:	8082                	ret
    panic("iget: no inodes");
    80003398:	00005517          	auipc	a0,0x5
    8000339c:	1e850513          	add	a0,a0,488 # 80008580 <syscalls+0x130>
    800033a0:	ffffd097          	auipc	ra,0xffffd
    800033a4:	19a080e7          	jalr	410(ra) # 8000053a <panic>

00000000800033a8 <fsinit>:
fsinit(int dev) {
    800033a8:	7179                	add	sp,sp,-48
    800033aa:	f406                	sd	ra,40(sp)
    800033ac:	f022                	sd	s0,32(sp)
    800033ae:	ec26                	sd	s1,24(sp)
    800033b0:	e84a                	sd	s2,16(sp)
    800033b2:	e44e                	sd	s3,8(sp)
    800033b4:	1800                	add	s0,sp,48
    800033b6:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800033b8:	4585                	li	a1,1
    800033ba:	00000097          	auipc	ra,0x0
    800033be:	a56080e7          	jalr	-1450(ra) # 80002e10 <bread>
    800033c2:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800033c4:	0001c997          	auipc	s3,0x1c
    800033c8:	c7498993          	add	s3,s3,-908 # 8001f038 <sb>
    800033cc:	02000613          	li	a2,32
    800033d0:	05850593          	add	a1,a0,88
    800033d4:	854e                	mv	a0,s3
    800033d6:	ffffe097          	auipc	ra,0xffffe
    800033da:	952080e7          	jalr	-1710(ra) # 80000d28 <memmove>
  brelse(bp);
    800033de:	8526                	mv	a0,s1
    800033e0:	00000097          	auipc	ra,0x0
    800033e4:	b60080e7          	jalr	-1184(ra) # 80002f40 <brelse>
  if(sb.magic != FSMAGIC)
    800033e8:	0009a703          	lw	a4,0(s3)
    800033ec:	102037b7          	lui	a5,0x10203
    800033f0:	04078793          	add	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800033f4:	02f71263          	bne	a4,a5,80003418 <fsinit+0x70>
  initlog(dev, &sb);
    800033f8:	0001c597          	auipc	a1,0x1c
    800033fc:	c4058593          	add	a1,a1,-960 # 8001f038 <sb>
    80003400:	854a                	mv	a0,s2
    80003402:	00001097          	auipc	ra,0x1
    80003406:	b2c080e7          	jalr	-1236(ra) # 80003f2e <initlog>
}
    8000340a:	70a2                	ld	ra,40(sp)
    8000340c:	7402                	ld	s0,32(sp)
    8000340e:	64e2                	ld	s1,24(sp)
    80003410:	6942                	ld	s2,16(sp)
    80003412:	69a2                	ld	s3,8(sp)
    80003414:	6145                	add	sp,sp,48
    80003416:	8082                	ret
    panic("invalid file system");
    80003418:	00005517          	auipc	a0,0x5
    8000341c:	17850513          	add	a0,a0,376 # 80008590 <syscalls+0x140>
    80003420:	ffffd097          	auipc	ra,0xffffd
    80003424:	11a080e7          	jalr	282(ra) # 8000053a <panic>

0000000080003428 <iinit>:
{
    80003428:	7179                	add	sp,sp,-48
    8000342a:	f406                	sd	ra,40(sp)
    8000342c:	f022                	sd	s0,32(sp)
    8000342e:	ec26                	sd	s1,24(sp)
    80003430:	e84a                	sd	s2,16(sp)
    80003432:	e44e                	sd	s3,8(sp)
    80003434:	1800                	add	s0,sp,48
  initlock(&itable.lock, "itable");
    80003436:	00005597          	auipc	a1,0x5
    8000343a:	17258593          	add	a1,a1,370 # 800085a8 <syscalls+0x158>
    8000343e:	0001c517          	auipc	a0,0x1c
    80003442:	c1a50513          	add	a0,a0,-998 # 8001f058 <itable>
    80003446:	ffffd097          	auipc	ra,0xffffd
    8000344a:	6fa080e7          	jalr	1786(ra) # 80000b40 <initlock>
  for(i = 0; i < NINODE; i++) {
    8000344e:	0001c497          	auipc	s1,0x1c
    80003452:	c3248493          	add	s1,s1,-974 # 8001f080 <itable+0x28>
    80003456:	0001d997          	auipc	s3,0x1d
    8000345a:	6ba98993          	add	s3,s3,1722 # 80020b10 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    8000345e:	00005917          	auipc	s2,0x5
    80003462:	15290913          	add	s2,s2,338 # 800085b0 <syscalls+0x160>
    80003466:	85ca                	mv	a1,s2
    80003468:	8526                	mv	a0,s1
    8000346a:	00001097          	auipc	ra,0x1
    8000346e:	e12080e7          	jalr	-494(ra) # 8000427c <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003472:	08848493          	add	s1,s1,136
    80003476:	ff3498e3          	bne	s1,s3,80003466 <iinit+0x3e>
}
    8000347a:	70a2                	ld	ra,40(sp)
    8000347c:	7402                	ld	s0,32(sp)
    8000347e:	64e2                	ld	s1,24(sp)
    80003480:	6942                	ld	s2,16(sp)
    80003482:	69a2                	ld	s3,8(sp)
    80003484:	6145                	add	sp,sp,48
    80003486:	8082                	ret

0000000080003488 <ialloc>:
{
    80003488:	7139                	add	sp,sp,-64
    8000348a:	fc06                	sd	ra,56(sp)
    8000348c:	f822                	sd	s0,48(sp)
    8000348e:	f426                	sd	s1,40(sp)
    80003490:	f04a                	sd	s2,32(sp)
    80003492:	ec4e                	sd	s3,24(sp)
    80003494:	e852                	sd	s4,16(sp)
    80003496:	e456                	sd	s5,8(sp)
    80003498:	e05a                	sd	s6,0(sp)
    8000349a:	0080                	add	s0,sp,64
  for(inum = 1; inum < sb.ninodes; inum++){
    8000349c:	0001c717          	auipc	a4,0x1c
    800034a0:	ba872703          	lw	a4,-1112(a4) # 8001f044 <sb+0xc>
    800034a4:	4785                	li	a5,1
    800034a6:	04e7f863          	bgeu	a5,a4,800034f6 <ialloc+0x6e>
    800034aa:	8aaa                	mv	s5,a0
    800034ac:	8b2e                	mv	s6,a1
    800034ae:	4905                	li	s2,1
    bp = bread(dev, IBLOCK(inum, sb));
    800034b0:	0001ca17          	auipc	s4,0x1c
    800034b4:	b88a0a13          	add	s4,s4,-1144 # 8001f038 <sb>
    800034b8:	00495593          	srl	a1,s2,0x4
    800034bc:	018a2783          	lw	a5,24(s4)
    800034c0:	9dbd                	addw	a1,a1,a5
    800034c2:	8556                	mv	a0,s5
    800034c4:	00000097          	auipc	ra,0x0
    800034c8:	94c080e7          	jalr	-1716(ra) # 80002e10 <bread>
    800034cc:	84aa                	mv	s1,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800034ce:	05850993          	add	s3,a0,88
    800034d2:	00f97793          	and	a5,s2,15
    800034d6:	079a                	sll	a5,a5,0x6
    800034d8:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800034da:	00099783          	lh	a5,0(s3)
    800034de:	cf9d                	beqz	a5,8000351c <ialloc+0x94>
    brelse(bp);
    800034e0:	00000097          	auipc	ra,0x0
    800034e4:	a60080e7          	jalr	-1440(ra) # 80002f40 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800034e8:	0905                	add	s2,s2,1
    800034ea:	00ca2703          	lw	a4,12(s4)
    800034ee:	0009079b          	sext.w	a5,s2
    800034f2:	fce7e3e3          	bltu	a5,a4,800034b8 <ialloc+0x30>
  printf("ialloc: no inodes\n");
    800034f6:	00005517          	auipc	a0,0x5
    800034fa:	0c250513          	add	a0,a0,194 # 800085b8 <syscalls+0x168>
    800034fe:	ffffd097          	auipc	ra,0xffffd
    80003502:	086080e7          	jalr	134(ra) # 80000584 <printf>
  return 0;
    80003506:	4501                	li	a0,0
}
    80003508:	70e2                	ld	ra,56(sp)
    8000350a:	7442                	ld	s0,48(sp)
    8000350c:	74a2                	ld	s1,40(sp)
    8000350e:	7902                	ld	s2,32(sp)
    80003510:	69e2                	ld	s3,24(sp)
    80003512:	6a42                	ld	s4,16(sp)
    80003514:	6aa2                	ld	s5,8(sp)
    80003516:	6b02                	ld	s6,0(sp)
    80003518:	6121                	add	sp,sp,64
    8000351a:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    8000351c:	04000613          	li	a2,64
    80003520:	4581                	li	a1,0
    80003522:	854e                	mv	a0,s3
    80003524:	ffffd097          	auipc	ra,0xffffd
    80003528:	7a8080e7          	jalr	1960(ra) # 80000ccc <memset>
      dip->type = type;
    8000352c:	01699023          	sh	s6,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003530:	8526                	mv	a0,s1
    80003532:	00001097          	auipc	ra,0x1
    80003536:	c66080e7          	jalr	-922(ra) # 80004198 <log_write>
      brelse(bp);
    8000353a:	8526                	mv	a0,s1
    8000353c:	00000097          	auipc	ra,0x0
    80003540:	a04080e7          	jalr	-1532(ra) # 80002f40 <brelse>
      return iget(dev, inum);
    80003544:	0009059b          	sext.w	a1,s2
    80003548:	8556                	mv	a0,s5
    8000354a:	00000097          	auipc	ra,0x0
    8000354e:	da2080e7          	jalr	-606(ra) # 800032ec <iget>
    80003552:	bf5d                	j	80003508 <ialloc+0x80>

0000000080003554 <iupdate>:
{
    80003554:	1101                	add	sp,sp,-32
    80003556:	ec06                	sd	ra,24(sp)
    80003558:	e822                	sd	s0,16(sp)
    8000355a:	e426                	sd	s1,8(sp)
    8000355c:	e04a                	sd	s2,0(sp)
    8000355e:	1000                	add	s0,sp,32
    80003560:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003562:	415c                	lw	a5,4(a0)
    80003564:	0047d79b          	srlw	a5,a5,0x4
    80003568:	0001c597          	auipc	a1,0x1c
    8000356c:	ae85a583          	lw	a1,-1304(a1) # 8001f050 <sb+0x18>
    80003570:	9dbd                	addw	a1,a1,a5
    80003572:	4108                	lw	a0,0(a0)
    80003574:	00000097          	auipc	ra,0x0
    80003578:	89c080e7          	jalr	-1892(ra) # 80002e10 <bread>
    8000357c:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000357e:	05850793          	add	a5,a0,88
    80003582:	40d8                	lw	a4,4(s1)
    80003584:	8b3d                	and	a4,a4,15
    80003586:	071a                	sll	a4,a4,0x6
    80003588:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    8000358a:	04449703          	lh	a4,68(s1)
    8000358e:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003592:	04649703          	lh	a4,70(s1)
    80003596:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    8000359a:	04849703          	lh	a4,72(s1)
    8000359e:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    800035a2:	04a49703          	lh	a4,74(s1)
    800035a6:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    800035aa:	44f8                	lw	a4,76(s1)
    800035ac:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800035ae:	03400613          	li	a2,52
    800035b2:	05048593          	add	a1,s1,80
    800035b6:	00c78513          	add	a0,a5,12
    800035ba:	ffffd097          	auipc	ra,0xffffd
    800035be:	76e080e7          	jalr	1902(ra) # 80000d28 <memmove>
  log_write(bp);
    800035c2:	854a                	mv	a0,s2
    800035c4:	00001097          	auipc	ra,0x1
    800035c8:	bd4080e7          	jalr	-1068(ra) # 80004198 <log_write>
  brelse(bp);
    800035cc:	854a                	mv	a0,s2
    800035ce:	00000097          	auipc	ra,0x0
    800035d2:	972080e7          	jalr	-1678(ra) # 80002f40 <brelse>
}
    800035d6:	60e2                	ld	ra,24(sp)
    800035d8:	6442                	ld	s0,16(sp)
    800035da:	64a2                	ld	s1,8(sp)
    800035dc:	6902                	ld	s2,0(sp)
    800035de:	6105                	add	sp,sp,32
    800035e0:	8082                	ret

00000000800035e2 <idup>:
{
    800035e2:	1101                	add	sp,sp,-32
    800035e4:	ec06                	sd	ra,24(sp)
    800035e6:	e822                	sd	s0,16(sp)
    800035e8:	e426                	sd	s1,8(sp)
    800035ea:	1000                	add	s0,sp,32
    800035ec:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800035ee:	0001c517          	auipc	a0,0x1c
    800035f2:	a6a50513          	add	a0,a0,-1430 # 8001f058 <itable>
    800035f6:	ffffd097          	auipc	ra,0xffffd
    800035fa:	5da080e7          	jalr	1498(ra) # 80000bd0 <acquire>
  ip->ref++;
    800035fe:	449c                	lw	a5,8(s1)
    80003600:	2785                	addw	a5,a5,1
    80003602:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003604:	0001c517          	auipc	a0,0x1c
    80003608:	a5450513          	add	a0,a0,-1452 # 8001f058 <itable>
    8000360c:	ffffd097          	auipc	ra,0xffffd
    80003610:	678080e7          	jalr	1656(ra) # 80000c84 <release>
}
    80003614:	8526                	mv	a0,s1
    80003616:	60e2                	ld	ra,24(sp)
    80003618:	6442                	ld	s0,16(sp)
    8000361a:	64a2                	ld	s1,8(sp)
    8000361c:	6105                	add	sp,sp,32
    8000361e:	8082                	ret

0000000080003620 <ilock>:
{
    80003620:	1101                	add	sp,sp,-32
    80003622:	ec06                	sd	ra,24(sp)
    80003624:	e822                	sd	s0,16(sp)
    80003626:	e426                	sd	s1,8(sp)
    80003628:	e04a                	sd	s2,0(sp)
    8000362a:	1000                	add	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000362c:	c115                	beqz	a0,80003650 <ilock+0x30>
    8000362e:	84aa                	mv	s1,a0
    80003630:	451c                	lw	a5,8(a0)
    80003632:	00f05f63          	blez	a5,80003650 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003636:	0541                	add	a0,a0,16
    80003638:	00001097          	auipc	ra,0x1
    8000363c:	c7e080e7          	jalr	-898(ra) # 800042b6 <acquiresleep>
  if(ip->valid == 0){
    80003640:	40bc                	lw	a5,64(s1)
    80003642:	cf99                	beqz	a5,80003660 <ilock+0x40>
}
    80003644:	60e2                	ld	ra,24(sp)
    80003646:	6442                	ld	s0,16(sp)
    80003648:	64a2                	ld	s1,8(sp)
    8000364a:	6902                	ld	s2,0(sp)
    8000364c:	6105                	add	sp,sp,32
    8000364e:	8082                	ret
    panic("ilock");
    80003650:	00005517          	auipc	a0,0x5
    80003654:	f8050513          	add	a0,a0,-128 # 800085d0 <syscalls+0x180>
    80003658:	ffffd097          	auipc	ra,0xffffd
    8000365c:	ee2080e7          	jalr	-286(ra) # 8000053a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003660:	40dc                	lw	a5,4(s1)
    80003662:	0047d79b          	srlw	a5,a5,0x4
    80003666:	0001c597          	auipc	a1,0x1c
    8000366a:	9ea5a583          	lw	a1,-1558(a1) # 8001f050 <sb+0x18>
    8000366e:	9dbd                	addw	a1,a1,a5
    80003670:	4088                	lw	a0,0(s1)
    80003672:	fffff097          	auipc	ra,0xfffff
    80003676:	79e080e7          	jalr	1950(ra) # 80002e10 <bread>
    8000367a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000367c:	05850593          	add	a1,a0,88
    80003680:	40dc                	lw	a5,4(s1)
    80003682:	8bbd                	and	a5,a5,15
    80003684:	079a                	sll	a5,a5,0x6
    80003686:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003688:	00059783          	lh	a5,0(a1)
    8000368c:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003690:	00259783          	lh	a5,2(a1)
    80003694:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003698:	00459783          	lh	a5,4(a1)
    8000369c:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800036a0:	00659783          	lh	a5,6(a1)
    800036a4:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800036a8:	459c                	lw	a5,8(a1)
    800036aa:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800036ac:	03400613          	li	a2,52
    800036b0:	05b1                	add	a1,a1,12
    800036b2:	05048513          	add	a0,s1,80
    800036b6:	ffffd097          	auipc	ra,0xffffd
    800036ba:	672080e7          	jalr	1650(ra) # 80000d28 <memmove>
    brelse(bp);
    800036be:	854a                	mv	a0,s2
    800036c0:	00000097          	auipc	ra,0x0
    800036c4:	880080e7          	jalr	-1920(ra) # 80002f40 <brelse>
    ip->valid = 1;
    800036c8:	4785                	li	a5,1
    800036ca:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800036cc:	04449783          	lh	a5,68(s1)
    800036d0:	fbb5                	bnez	a5,80003644 <ilock+0x24>
      panic("ilock: no type");
    800036d2:	00005517          	auipc	a0,0x5
    800036d6:	f0650513          	add	a0,a0,-250 # 800085d8 <syscalls+0x188>
    800036da:	ffffd097          	auipc	ra,0xffffd
    800036de:	e60080e7          	jalr	-416(ra) # 8000053a <panic>

00000000800036e2 <iunlock>:
{
    800036e2:	1101                	add	sp,sp,-32
    800036e4:	ec06                	sd	ra,24(sp)
    800036e6:	e822                	sd	s0,16(sp)
    800036e8:	e426                	sd	s1,8(sp)
    800036ea:	e04a                	sd	s2,0(sp)
    800036ec:	1000                	add	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800036ee:	c905                	beqz	a0,8000371e <iunlock+0x3c>
    800036f0:	84aa                	mv	s1,a0
    800036f2:	01050913          	add	s2,a0,16
    800036f6:	854a                	mv	a0,s2
    800036f8:	00001097          	auipc	ra,0x1
    800036fc:	c58080e7          	jalr	-936(ra) # 80004350 <holdingsleep>
    80003700:	cd19                	beqz	a0,8000371e <iunlock+0x3c>
    80003702:	449c                	lw	a5,8(s1)
    80003704:	00f05d63          	blez	a5,8000371e <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003708:	854a                	mv	a0,s2
    8000370a:	00001097          	auipc	ra,0x1
    8000370e:	c02080e7          	jalr	-1022(ra) # 8000430c <releasesleep>
}
    80003712:	60e2                	ld	ra,24(sp)
    80003714:	6442                	ld	s0,16(sp)
    80003716:	64a2                	ld	s1,8(sp)
    80003718:	6902                	ld	s2,0(sp)
    8000371a:	6105                	add	sp,sp,32
    8000371c:	8082                	ret
    panic("iunlock");
    8000371e:	00005517          	auipc	a0,0x5
    80003722:	eca50513          	add	a0,a0,-310 # 800085e8 <syscalls+0x198>
    80003726:	ffffd097          	auipc	ra,0xffffd
    8000372a:	e14080e7          	jalr	-492(ra) # 8000053a <panic>

000000008000372e <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    8000372e:	7179                	add	sp,sp,-48
    80003730:	f406                	sd	ra,40(sp)
    80003732:	f022                	sd	s0,32(sp)
    80003734:	ec26                	sd	s1,24(sp)
    80003736:	e84a                	sd	s2,16(sp)
    80003738:	e44e                	sd	s3,8(sp)
    8000373a:	e052                	sd	s4,0(sp)
    8000373c:	1800                	add	s0,sp,48
    8000373e:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003740:	05050493          	add	s1,a0,80
    80003744:	08050913          	add	s2,a0,128
    80003748:	a021                	j	80003750 <itrunc+0x22>
    8000374a:	0491                	add	s1,s1,4
    8000374c:	01248d63          	beq	s1,s2,80003766 <itrunc+0x38>
    if(ip->addrs[i]){
    80003750:	408c                	lw	a1,0(s1)
    80003752:	dde5                	beqz	a1,8000374a <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003754:	0009a503          	lw	a0,0(s3)
    80003758:	00000097          	auipc	ra,0x0
    8000375c:	8fc080e7          	jalr	-1796(ra) # 80003054 <bfree>
      ip->addrs[i] = 0;
    80003760:	0004a023          	sw	zero,0(s1)
    80003764:	b7dd                	j	8000374a <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003766:	0809a583          	lw	a1,128(s3)
    8000376a:	e185                	bnez	a1,8000378a <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    8000376c:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003770:	854e                	mv	a0,s3
    80003772:	00000097          	auipc	ra,0x0
    80003776:	de2080e7          	jalr	-542(ra) # 80003554 <iupdate>
}
    8000377a:	70a2                	ld	ra,40(sp)
    8000377c:	7402                	ld	s0,32(sp)
    8000377e:	64e2                	ld	s1,24(sp)
    80003780:	6942                	ld	s2,16(sp)
    80003782:	69a2                	ld	s3,8(sp)
    80003784:	6a02                	ld	s4,0(sp)
    80003786:	6145                	add	sp,sp,48
    80003788:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    8000378a:	0009a503          	lw	a0,0(s3)
    8000378e:	fffff097          	auipc	ra,0xfffff
    80003792:	682080e7          	jalr	1666(ra) # 80002e10 <bread>
    80003796:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003798:	05850493          	add	s1,a0,88
    8000379c:	45850913          	add	s2,a0,1112
    800037a0:	a021                	j	800037a8 <itrunc+0x7a>
    800037a2:	0491                	add	s1,s1,4
    800037a4:	01248b63          	beq	s1,s2,800037ba <itrunc+0x8c>
      if(a[j])
    800037a8:	408c                	lw	a1,0(s1)
    800037aa:	dde5                	beqz	a1,800037a2 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    800037ac:	0009a503          	lw	a0,0(s3)
    800037b0:	00000097          	auipc	ra,0x0
    800037b4:	8a4080e7          	jalr	-1884(ra) # 80003054 <bfree>
    800037b8:	b7ed                	j	800037a2 <itrunc+0x74>
    brelse(bp);
    800037ba:	8552                	mv	a0,s4
    800037bc:	fffff097          	auipc	ra,0xfffff
    800037c0:	784080e7          	jalr	1924(ra) # 80002f40 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800037c4:	0809a583          	lw	a1,128(s3)
    800037c8:	0009a503          	lw	a0,0(s3)
    800037cc:	00000097          	auipc	ra,0x0
    800037d0:	888080e7          	jalr	-1912(ra) # 80003054 <bfree>
    ip->addrs[NDIRECT] = 0;
    800037d4:	0809a023          	sw	zero,128(s3)
    800037d8:	bf51                	j	8000376c <itrunc+0x3e>

00000000800037da <iput>:
{
    800037da:	1101                	add	sp,sp,-32
    800037dc:	ec06                	sd	ra,24(sp)
    800037de:	e822                	sd	s0,16(sp)
    800037e0:	e426                	sd	s1,8(sp)
    800037e2:	e04a                	sd	s2,0(sp)
    800037e4:	1000                	add	s0,sp,32
    800037e6:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800037e8:	0001c517          	auipc	a0,0x1c
    800037ec:	87050513          	add	a0,a0,-1936 # 8001f058 <itable>
    800037f0:	ffffd097          	auipc	ra,0xffffd
    800037f4:	3e0080e7          	jalr	992(ra) # 80000bd0 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800037f8:	4498                	lw	a4,8(s1)
    800037fa:	4785                	li	a5,1
    800037fc:	02f70363          	beq	a4,a5,80003822 <iput+0x48>
  ip->ref--;
    80003800:	449c                	lw	a5,8(s1)
    80003802:	37fd                	addw	a5,a5,-1
    80003804:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003806:	0001c517          	auipc	a0,0x1c
    8000380a:	85250513          	add	a0,a0,-1966 # 8001f058 <itable>
    8000380e:	ffffd097          	auipc	ra,0xffffd
    80003812:	476080e7          	jalr	1142(ra) # 80000c84 <release>
}
    80003816:	60e2                	ld	ra,24(sp)
    80003818:	6442                	ld	s0,16(sp)
    8000381a:	64a2                	ld	s1,8(sp)
    8000381c:	6902                	ld	s2,0(sp)
    8000381e:	6105                	add	sp,sp,32
    80003820:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003822:	40bc                	lw	a5,64(s1)
    80003824:	dff1                	beqz	a5,80003800 <iput+0x26>
    80003826:	04a49783          	lh	a5,74(s1)
    8000382a:	fbf9                	bnez	a5,80003800 <iput+0x26>
    acquiresleep(&ip->lock);
    8000382c:	01048913          	add	s2,s1,16
    80003830:	854a                	mv	a0,s2
    80003832:	00001097          	auipc	ra,0x1
    80003836:	a84080e7          	jalr	-1404(ra) # 800042b6 <acquiresleep>
    release(&itable.lock);
    8000383a:	0001c517          	auipc	a0,0x1c
    8000383e:	81e50513          	add	a0,a0,-2018 # 8001f058 <itable>
    80003842:	ffffd097          	auipc	ra,0xffffd
    80003846:	442080e7          	jalr	1090(ra) # 80000c84 <release>
    itrunc(ip);
    8000384a:	8526                	mv	a0,s1
    8000384c:	00000097          	auipc	ra,0x0
    80003850:	ee2080e7          	jalr	-286(ra) # 8000372e <itrunc>
    ip->type = 0;
    80003854:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003858:	8526                	mv	a0,s1
    8000385a:	00000097          	auipc	ra,0x0
    8000385e:	cfa080e7          	jalr	-774(ra) # 80003554 <iupdate>
    ip->valid = 0;
    80003862:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003866:	854a                	mv	a0,s2
    80003868:	00001097          	auipc	ra,0x1
    8000386c:	aa4080e7          	jalr	-1372(ra) # 8000430c <releasesleep>
    acquire(&itable.lock);
    80003870:	0001b517          	auipc	a0,0x1b
    80003874:	7e850513          	add	a0,a0,2024 # 8001f058 <itable>
    80003878:	ffffd097          	auipc	ra,0xffffd
    8000387c:	358080e7          	jalr	856(ra) # 80000bd0 <acquire>
    80003880:	b741                	j	80003800 <iput+0x26>

0000000080003882 <iunlockput>:
{
    80003882:	1101                	add	sp,sp,-32
    80003884:	ec06                	sd	ra,24(sp)
    80003886:	e822                	sd	s0,16(sp)
    80003888:	e426                	sd	s1,8(sp)
    8000388a:	1000                	add	s0,sp,32
    8000388c:	84aa                	mv	s1,a0
  iunlock(ip);
    8000388e:	00000097          	auipc	ra,0x0
    80003892:	e54080e7          	jalr	-428(ra) # 800036e2 <iunlock>
  iput(ip);
    80003896:	8526                	mv	a0,s1
    80003898:	00000097          	auipc	ra,0x0
    8000389c:	f42080e7          	jalr	-190(ra) # 800037da <iput>
}
    800038a0:	60e2                	ld	ra,24(sp)
    800038a2:	6442                	ld	s0,16(sp)
    800038a4:	64a2                	ld	s1,8(sp)
    800038a6:	6105                	add	sp,sp,32
    800038a8:	8082                	ret

00000000800038aa <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800038aa:	1141                	add	sp,sp,-16
    800038ac:	e422                	sd	s0,8(sp)
    800038ae:	0800                	add	s0,sp,16
  st->dev = ip->dev;
    800038b0:	411c                	lw	a5,0(a0)
    800038b2:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800038b4:	415c                	lw	a5,4(a0)
    800038b6:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800038b8:	04451783          	lh	a5,68(a0)
    800038bc:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800038c0:	04a51783          	lh	a5,74(a0)
    800038c4:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800038c8:	04c56783          	lwu	a5,76(a0)
    800038cc:	e99c                	sd	a5,16(a1)
}
    800038ce:	6422                	ld	s0,8(sp)
    800038d0:	0141                	add	sp,sp,16
    800038d2:	8082                	ret

00000000800038d4 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800038d4:	457c                	lw	a5,76(a0)
    800038d6:	0ed7e963          	bltu	a5,a3,800039c8 <readi+0xf4>
{
    800038da:	7159                	add	sp,sp,-112
    800038dc:	f486                	sd	ra,104(sp)
    800038de:	f0a2                	sd	s0,96(sp)
    800038e0:	eca6                	sd	s1,88(sp)
    800038e2:	e8ca                	sd	s2,80(sp)
    800038e4:	e4ce                	sd	s3,72(sp)
    800038e6:	e0d2                	sd	s4,64(sp)
    800038e8:	fc56                	sd	s5,56(sp)
    800038ea:	f85a                	sd	s6,48(sp)
    800038ec:	f45e                	sd	s7,40(sp)
    800038ee:	f062                	sd	s8,32(sp)
    800038f0:	ec66                	sd	s9,24(sp)
    800038f2:	e86a                	sd	s10,16(sp)
    800038f4:	e46e                	sd	s11,8(sp)
    800038f6:	1880                	add	s0,sp,112
    800038f8:	8b2a                	mv	s6,a0
    800038fa:	8bae                	mv	s7,a1
    800038fc:	8a32                	mv	s4,a2
    800038fe:	84b6                	mv	s1,a3
    80003900:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003902:	9f35                	addw	a4,a4,a3
    return 0;
    80003904:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003906:	0ad76063          	bltu	a4,a3,800039a6 <readi+0xd2>
  if(off + n > ip->size)
    8000390a:	00e7f463          	bgeu	a5,a4,80003912 <readi+0x3e>
    n = ip->size - off;
    8000390e:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003912:	0a0a8963          	beqz	s5,800039c4 <readi+0xf0>
    80003916:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003918:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    8000391c:	5c7d                	li	s8,-1
    8000391e:	a82d                	j	80003958 <readi+0x84>
    80003920:	020d1d93          	sll	s11,s10,0x20
    80003924:	020ddd93          	srl	s11,s11,0x20
    80003928:	05890613          	add	a2,s2,88
    8000392c:	86ee                	mv	a3,s11
    8000392e:	963a                	add	a2,a2,a4
    80003930:	85d2                	mv	a1,s4
    80003932:	855e                	mv	a0,s7
    80003934:	fffff097          	auipc	ra,0xfffff
    80003938:	b20080e7          	jalr	-1248(ra) # 80002454 <either_copyout>
    8000393c:	05850d63          	beq	a0,s8,80003996 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003940:	854a                	mv	a0,s2
    80003942:	fffff097          	auipc	ra,0xfffff
    80003946:	5fe080e7          	jalr	1534(ra) # 80002f40 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000394a:	013d09bb          	addw	s3,s10,s3
    8000394e:	009d04bb          	addw	s1,s10,s1
    80003952:	9a6e                	add	s4,s4,s11
    80003954:	0559f763          	bgeu	s3,s5,800039a2 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003958:	00a4d59b          	srlw	a1,s1,0xa
    8000395c:	855a                	mv	a0,s6
    8000395e:	00000097          	auipc	ra,0x0
    80003962:	8a4080e7          	jalr	-1884(ra) # 80003202 <bmap>
    80003966:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    8000396a:	cd85                	beqz	a1,800039a2 <readi+0xce>
    bp = bread(ip->dev, addr);
    8000396c:	000b2503          	lw	a0,0(s6)
    80003970:	fffff097          	auipc	ra,0xfffff
    80003974:	4a0080e7          	jalr	1184(ra) # 80002e10 <bread>
    80003978:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000397a:	3ff4f713          	and	a4,s1,1023
    8000397e:	40ec87bb          	subw	a5,s9,a4
    80003982:	413a86bb          	subw	a3,s5,s3
    80003986:	8d3e                	mv	s10,a5
    80003988:	2781                	sext.w	a5,a5
    8000398a:	0006861b          	sext.w	a2,a3
    8000398e:	f8f679e3          	bgeu	a2,a5,80003920 <readi+0x4c>
    80003992:	8d36                	mv	s10,a3
    80003994:	b771                	j	80003920 <readi+0x4c>
      brelse(bp);
    80003996:	854a                	mv	a0,s2
    80003998:	fffff097          	auipc	ra,0xfffff
    8000399c:	5a8080e7          	jalr	1448(ra) # 80002f40 <brelse>
      tot = -1;
    800039a0:	59fd                	li	s3,-1
  }
  return tot;
    800039a2:	0009851b          	sext.w	a0,s3
}
    800039a6:	70a6                	ld	ra,104(sp)
    800039a8:	7406                	ld	s0,96(sp)
    800039aa:	64e6                	ld	s1,88(sp)
    800039ac:	6946                	ld	s2,80(sp)
    800039ae:	69a6                	ld	s3,72(sp)
    800039b0:	6a06                	ld	s4,64(sp)
    800039b2:	7ae2                	ld	s5,56(sp)
    800039b4:	7b42                	ld	s6,48(sp)
    800039b6:	7ba2                	ld	s7,40(sp)
    800039b8:	7c02                	ld	s8,32(sp)
    800039ba:	6ce2                	ld	s9,24(sp)
    800039bc:	6d42                	ld	s10,16(sp)
    800039be:	6da2                	ld	s11,8(sp)
    800039c0:	6165                	add	sp,sp,112
    800039c2:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800039c4:	89d6                	mv	s3,s5
    800039c6:	bff1                	j	800039a2 <readi+0xce>
    return 0;
    800039c8:	4501                	li	a0,0
}
    800039ca:	8082                	ret

00000000800039cc <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800039cc:	457c                	lw	a5,76(a0)
    800039ce:	10d7e863          	bltu	a5,a3,80003ade <writei+0x112>
{
    800039d2:	7159                	add	sp,sp,-112
    800039d4:	f486                	sd	ra,104(sp)
    800039d6:	f0a2                	sd	s0,96(sp)
    800039d8:	eca6                	sd	s1,88(sp)
    800039da:	e8ca                	sd	s2,80(sp)
    800039dc:	e4ce                	sd	s3,72(sp)
    800039de:	e0d2                	sd	s4,64(sp)
    800039e0:	fc56                	sd	s5,56(sp)
    800039e2:	f85a                	sd	s6,48(sp)
    800039e4:	f45e                	sd	s7,40(sp)
    800039e6:	f062                	sd	s8,32(sp)
    800039e8:	ec66                	sd	s9,24(sp)
    800039ea:	e86a                	sd	s10,16(sp)
    800039ec:	e46e                	sd	s11,8(sp)
    800039ee:	1880                	add	s0,sp,112
    800039f0:	8aaa                	mv	s5,a0
    800039f2:	8bae                	mv	s7,a1
    800039f4:	8a32                	mv	s4,a2
    800039f6:	8936                	mv	s2,a3
    800039f8:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800039fa:	00e687bb          	addw	a5,a3,a4
    800039fe:	0ed7e263          	bltu	a5,a3,80003ae2 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003a02:	00043737          	lui	a4,0x43
    80003a06:	0ef76063          	bltu	a4,a5,80003ae6 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003a0a:	0c0b0863          	beqz	s6,80003ada <writei+0x10e>
    80003a0e:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a10:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003a14:	5c7d                	li	s8,-1
    80003a16:	a091                	j	80003a5a <writei+0x8e>
    80003a18:	020d1d93          	sll	s11,s10,0x20
    80003a1c:	020ddd93          	srl	s11,s11,0x20
    80003a20:	05848513          	add	a0,s1,88
    80003a24:	86ee                	mv	a3,s11
    80003a26:	8652                	mv	a2,s4
    80003a28:	85de                	mv	a1,s7
    80003a2a:	953a                	add	a0,a0,a4
    80003a2c:	fffff097          	auipc	ra,0xfffff
    80003a30:	a7e080e7          	jalr	-1410(ra) # 800024aa <either_copyin>
    80003a34:	07850263          	beq	a0,s8,80003a98 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003a38:	8526                	mv	a0,s1
    80003a3a:	00000097          	auipc	ra,0x0
    80003a3e:	75e080e7          	jalr	1886(ra) # 80004198 <log_write>
    brelse(bp);
    80003a42:	8526                	mv	a0,s1
    80003a44:	fffff097          	auipc	ra,0xfffff
    80003a48:	4fc080e7          	jalr	1276(ra) # 80002f40 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003a4c:	013d09bb          	addw	s3,s10,s3
    80003a50:	012d093b          	addw	s2,s10,s2
    80003a54:	9a6e                	add	s4,s4,s11
    80003a56:	0569f663          	bgeu	s3,s6,80003aa2 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003a5a:	00a9559b          	srlw	a1,s2,0xa
    80003a5e:	8556                	mv	a0,s5
    80003a60:	fffff097          	auipc	ra,0xfffff
    80003a64:	7a2080e7          	jalr	1954(ra) # 80003202 <bmap>
    80003a68:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003a6c:	c99d                	beqz	a1,80003aa2 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003a6e:	000aa503          	lw	a0,0(s5)
    80003a72:	fffff097          	auipc	ra,0xfffff
    80003a76:	39e080e7          	jalr	926(ra) # 80002e10 <bread>
    80003a7a:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a7c:	3ff97713          	and	a4,s2,1023
    80003a80:	40ec87bb          	subw	a5,s9,a4
    80003a84:	413b06bb          	subw	a3,s6,s3
    80003a88:	8d3e                	mv	s10,a5
    80003a8a:	2781                	sext.w	a5,a5
    80003a8c:	0006861b          	sext.w	a2,a3
    80003a90:	f8f674e3          	bgeu	a2,a5,80003a18 <writei+0x4c>
    80003a94:	8d36                	mv	s10,a3
    80003a96:	b749                	j	80003a18 <writei+0x4c>
      brelse(bp);
    80003a98:	8526                	mv	a0,s1
    80003a9a:	fffff097          	auipc	ra,0xfffff
    80003a9e:	4a6080e7          	jalr	1190(ra) # 80002f40 <brelse>
  }

  if(off > ip->size)
    80003aa2:	04caa783          	lw	a5,76(s5)
    80003aa6:	0127f463          	bgeu	a5,s2,80003aae <writei+0xe2>
    ip->size = off;
    80003aaa:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003aae:	8556                	mv	a0,s5
    80003ab0:	00000097          	auipc	ra,0x0
    80003ab4:	aa4080e7          	jalr	-1372(ra) # 80003554 <iupdate>

  return tot;
    80003ab8:	0009851b          	sext.w	a0,s3
}
    80003abc:	70a6                	ld	ra,104(sp)
    80003abe:	7406                	ld	s0,96(sp)
    80003ac0:	64e6                	ld	s1,88(sp)
    80003ac2:	6946                	ld	s2,80(sp)
    80003ac4:	69a6                	ld	s3,72(sp)
    80003ac6:	6a06                	ld	s4,64(sp)
    80003ac8:	7ae2                	ld	s5,56(sp)
    80003aca:	7b42                	ld	s6,48(sp)
    80003acc:	7ba2                	ld	s7,40(sp)
    80003ace:	7c02                	ld	s8,32(sp)
    80003ad0:	6ce2                	ld	s9,24(sp)
    80003ad2:	6d42                	ld	s10,16(sp)
    80003ad4:	6da2                	ld	s11,8(sp)
    80003ad6:	6165                	add	sp,sp,112
    80003ad8:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ada:	89da                	mv	s3,s6
    80003adc:	bfc9                	j	80003aae <writei+0xe2>
    return -1;
    80003ade:	557d                	li	a0,-1
}
    80003ae0:	8082                	ret
    return -1;
    80003ae2:	557d                	li	a0,-1
    80003ae4:	bfe1                	j	80003abc <writei+0xf0>
    return -1;
    80003ae6:	557d                	li	a0,-1
    80003ae8:	bfd1                	j	80003abc <writei+0xf0>

0000000080003aea <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003aea:	1141                	add	sp,sp,-16
    80003aec:	e406                	sd	ra,8(sp)
    80003aee:	e022                	sd	s0,0(sp)
    80003af0:	0800                	add	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003af2:	4639                	li	a2,14
    80003af4:	ffffd097          	auipc	ra,0xffffd
    80003af8:	2a8080e7          	jalr	680(ra) # 80000d9c <strncmp>
}
    80003afc:	60a2                	ld	ra,8(sp)
    80003afe:	6402                	ld	s0,0(sp)
    80003b00:	0141                	add	sp,sp,16
    80003b02:	8082                	ret

0000000080003b04 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003b04:	7139                	add	sp,sp,-64
    80003b06:	fc06                	sd	ra,56(sp)
    80003b08:	f822                	sd	s0,48(sp)
    80003b0a:	f426                	sd	s1,40(sp)
    80003b0c:	f04a                	sd	s2,32(sp)
    80003b0e:	ec4e                	sd	s3,24(sp)
    80003b10:	e852                	sd	s4,16(sp)
    80003b12:	0080                	add	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003b14:	04451703          	lh	a4,68(a0)
    80003b18:	4785                	li	a5,1
    80003b1a:	00f71a63          	bne	a4,a5,80003b2e <dirlookup+0x2a>
    80003b1e:	892a                	mv	s2,a0
    80003b20:	89ae                	mv	s3,a1
    80003b22:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b24:	457c                	lw	a5,76(a0)
    80003b26:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003b28:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b2a:	e79d                	bnez	a5,80003b58 <dirlookup+0x54>
    80003b2c:	a8a5                	j	80003ba4 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003b2e:	00005517          	auipc	a0,0x5
    80003b32:	ac250513          	add	a0,a0,-1342 # 800085f0 <syscalls+0x1a0>
    80003b36:	ffffd097          	auipc	ra,0xffffd
    80003b3a:	a04080e7          	jalr	-1532(ra) # 8000053a <panic>
      panic("dirlookup read");
    80003b3e:	00005517          	auipc	a0,0x5
    80003b42:	aca50513          	add	a0,a0,-1334 # 80008608 <syscalls+0x1b8>
    80003b46:	ffffd097          	auipc	ra,0xffffd
    80003b4a:	9f4080e7          	jalr	-1548(ra) # 8000053a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b4e:	24c1                	addw	s1,s1,16
    80003b50:	04c92783          	lw	a5,76(s2)
    80003b54:	04f4f763          	bgeu	s1,a5,80003ba2 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003b58:	4741                	li	a4,16
    80003b5a:	86a6                	mv	a3,s1
    80003b5c:	fc040613          	add	a2,s0,-64
    80003b60:	4581                	li	a1,0
    80003b62:	854a                	mv	a0,s2
    80003b64:	00000097          	auipc	ra,0x0
    80003b68:	d70080e7          	jalr	-656(ra) # 800038d4 <readi>
    80003b6c:	47c1                	li	a5,16
    80003b6e:	fcf518e3          	bne	a0,a5,80003b3e <dirlookup+0x3a>
    if(de.inum == 0)
    80003b72:	fc045783          	lhu	a5,-64(s0)
    80003b76:	dfe1                	beqz	a5,80003b4e <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003b78:	fc240593          	add	a1,s0,-62
    80003b7c:	854e                	mv	a0,s3
    80003b7e:	00000097          	auipc	ra,0x0
    80003b82:	f6c080e7          	jalr	-148(ra) # 80003aea <namecmp>
    80003b86:	f561                	bnez	a0,80003b4e <dirlookup+0x4a>
      if(poff)
    80003b88:	000a0463          	beqz	s4,80003b90 <dirlookup+0x8c>
        *poff = off;
    80003b8c:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003b90:	fc045583          	lhu	a1,-64(s0)
    80003b94:	00092503          	lw	a0,0(s2)
    80003b98:	fffff097          	auipc	ra,0xfffff
    80003b9c:	754080e7          	jalr	1876(ra) # 800032ec <iget>
    80003ba0:	a011                	j	80003ba4 <dirlookup+0xa0>
  return 0;
    80003ba2:	4501                	li	a0,0
}
    80003ba4:	70e2                	ld	ra,56(sp)
    80003ba6:	7442                	ld	s0,48(sp)
    80003ba8:	74a2                	ld	s1,40(sp)
    80003baa:	7902                	ld	s2,32(sp)
    80003bac:	69e2                	ld	s3,24(sp)
    80003bae:	6a42                	ld	s4,16(sp)
    80003bb0:	6121                	add	sp,sp,64
    80003bb2:	8082                	ret

0000000080003bb4 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003bb4:	711d                	add	sp,sp,-96
    80003bb6:	ec86                	sd	ra,88(sp)
    80003bb8:	e8a2                	sd	s0,80(sp)
    80003bba:	e4a6                	sd	s1,72(sp)
    80003bbc:	e0ca                	sd	s2,64(sp)
    80003bbe:	fc4e                	sd	s3,56(sp)
    80003bc0:	f852                	sd	s4,48(sp)
    80003bc2:	f456                	sd	s5,40(sp)
    80003bc4:	f05a                	sd	s6,32(sp)
    80003bc6:	ec5e                	sd	s7,24(sp)
    80003bc8:	e862                	sd	s8,16(sp)
    80003bca:	e466                	sd	s9,8(sp)
    80003bcc:	1080                	add	s0,sp,96
    80003bce:	84aa                	mv	s1,a0
    80003bd0:	8b2e                	mv	s6,a1
    80003bd2:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003bd4:	00054703          	lbu	a4,0(a0)
    80003bd8:	02f00793          	li	a5,47
    80003bdc:	02f70263          	beq	a4,a5,80003c00 <namex+0x4c>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003be0:	ffffe097          	auipc	ra,0xffffe
    80003be4:	dc4080e7          	jalr	-572(ra) # 800019a4 <myproc>
    80003be8:	15053503          	ld	a0,336(a0)
    80003bec:	00000097          	auipc	ra,0x0
    80003bf0:	9f6080e7          	jalr	-1546(ra) # 800035e2 <idup>
    80003bf4:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003bf6:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003bfa:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003bfc:	4b85                	li	s7,1
    80003bfe:	a875                	j	80003cba <namex+0x106>
    ip = iget(ROOTDEV, ROOTINO);
    80003c00:	4585                	li	a1,1
    80003c02:	4505                	li	a0,1
    80003c04:	fffff097          	auipc	ra,0xfffff
    80003c08:	6e8080e7          	jalr	1768(ra) # 800032ec <iget>
    80003c0c:	8a2a                	mv	s4,a0
    80003c0e:	b7e5                	j	80003bf6 <namex+0x42>
      iunlockput(ip);
    80003c10:	8552                	mv	a0,s4
    80003c12:	00000097          	auipc	ra,0x0
    80003c16:	c70080e7          	jalr	-912(ra) # 80003882 <iunlockput>
      return 0;
    80003c1a:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003c1c:	8552                	mv	a0,s4
    80003c1e:	60e6                	ld	ra,88(sp)
    80003c20:	6446                	ld	s0,80(sp)
    80003c22:	64a6                	ld	s1,72(sp)
    80003c24:	6906                	ld	s2,64(sp)
    80003c26:	79e2                	ld	s3,56(sp)
    80003c28:	7a42                	ld	s4,48(sp)
    80003c2a:	7aa2                	ld	s5,40(sp)
    80003c2c:	7b02                	ld	s6,32(sp)
    80003c2e:	6be2                	ld	s7,24(sp)
    80003c30:	6c42                	ld	s8,16(sp)
    80003c32:	6ca2                	ld	s9,8(sp)
    80003c34:	6125                	add	sp,sp,96
    80003c36:	8082                	ret
      iunlock(ip);
    80003c38:	8552                	mv	a0,s4
    80003c3a:	00000097          	auipc	ra,0x0
    80003c3e:	aa8080e7          	jalr	-1368(ra) # 800036e2 <iunlock>
      return ip;
    80003c42:	bfe9                	j	80003c1c <namex+0x68>
      iunlockput(ip);
    80003c44:	8552                	mv	a0,s4
    80003c46:	00000097          	auipc	ra,0x0
    80003c4a:	c3c080e7          	jalr	-964(ra) # 80003882 <iunlockput>
      return 0;
    80003c4e:	8a4e                	mv	s4,s3
    80003c50:	b7f1                	j	80003c1c <namex+0x68>
  len = path - s;
    80003c52:	40998633          	sub	a2,s3,s1
    80003c56:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003c5a:	099c5863          	bge	s8,s9,80003cea <namex+0x136>
    memmove(name, s, DIRSIZ);
    80003c5e:	4639                	li	a2,14
    80003c60:	85a6                	mv	a1,s1
    80003c62:	8556                	mv	a0,s5
    80003c64:	ffffd097          	auipc	ra,0xffffd
    80003c68:	0c4080e7          	jalr	196(ra) # 80000d28 <memmove>
    80003c6c:	84ce                	mv	s1,s3
  while(*path == '/')
    80003c6e:	0004c783          	lbu	a5,0(s1)
    80003c72:	01279763          	bne	a5,s2,80003c80 <namex+0xcc>
    path++;
    80003c76:	0485                	add	s1,s1,1
  while(*path == '/')
    80003c78:	0004c783          	lbu	a5,0(s1)
    80003c7c:	ff278de3          	beq	a5,s2,80003c76 <namex+0xc2>
    ilock(ip);
    80003c80:	8552                	mv	a0,s4
    80003c82:	00000097          	auipc	ra,0x0
    80003c86:	99e080e7          	jalr	-1634(ra) # 80003620 <ilock>
    if(ip->type != T_DIR){
    80003c8a:	044a1783          	lh	a5,68(s4)
    80003c8e:	f97791e3          	bne	a5,s7,80003c10 <namex+0x5c>
    if(nameiparent && *path == '\0'){
    80003c92:	000b0563          	beqz	s6,80003c9c <namex+0xe8>
    80003c96:	0004c783          	lbu	a5,0(s1)
    80003c9a:	dfd9                	beqz	a5,80003c38 <namex+0x84>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003c9c:	4601                	li	a2,0
    80003c9e:	85d6                	mv	a1,s5
    80003ca0:	8552                	mv	a0,s4
    80003ca2:	00000097          	auipc	ra,0x0
    80003ca6:	e62080e7          	jalr	-414(ra) # 80003b04 <dirlookup>
    80003caa:	89aa                	mv	s3,a0
    80003cac:	dd41                	beqz	a0,80003c44 <namex+0x90>
    iunlockput(ip);
    80003cae:	8552                	mv	a0,s4
    80003cb0:	00000097          	auipc	ra,0x0
    80003cb4:	bd2080e7          	jalr	-1070(ra) # 80003882 <iunlockput>
    ip = next;
    80003cb8:	8a4e                	mv	s4,s3
  while(*path == '/')
    80003cba:	0004c783          	lbu	a5,0(s1)
    80003cbe:	01279763          	bne	a5,s2,80003ccc <namex+0x118>
    path++;
    80003cc2:	0485                	add	s1,s1,1
  while(*path == '/')
    80003cc4:	0004c783          	lbu	a5,0(s1)
    80003cc8:	ff278de3          	beq	a5,s2,80003cc2 <namex+0x10e>
  if(*path == 0)
    80003ccc:	cb9d                	beqz	a5,80003d02 <namex+0x14e>
  while(*path != '/' && *path != 0)
    80003cce:	0004c783          	lbu	a5,0(s1)
    80003cd2:	89a6                	mv	s3,s1
  len = path - s;
    80003cd4:	4c81                	li	s9,0
    80003cd6:	4601                	li	a2,0
  while(*path != '/' && *path != 0)
    80003cd8:	01278963          	beq	a5,s2,80003cea <namex+0x136>
    80003cdc:	dbbd                	beqz	a5,80003c52 <namex+0x9e>
    path++;
    80003cde:	0985                	add	s3,s3,1
  while(*path != '/' && *path != 0)
    80003ce0:	0009c783          	lbu	a5,0(s3)
    80003ce4:	ff279ce3          	bne	a5,s2,80003cdc <namex+0x128>
    80003ce8:	b7ad                	j	80003c52 <namex+0x9e>
    memmove(name, s, len);
    80003cea:	2601                	sext.w	a2,a2
    80003cec:	85a6                	mv	a1,s1
    80003cee:	8556                	mv	a0,s5
    80003cf0:	ffffd097          	auipc	ra,0xffffd
    80003cf4:	038080e7          	jalr	56(ra) # 80000d28 <memmove>
    name[len] = 0;
    80003cf8:	9cd6                	add	s9,s9,s5
    80003cfa:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003cfe:	84ce                	mv	s1,s3
    80003d00:	b7bd                	j	80003c6e <namex+0xba>
  if(nameiparent){
    80003d02:	f00b0de3          	beqz	s6,80003c1c <namex+0x68>
    iput(ip);
    80003d06:	8552                	mv	a0,s4
    80003d08:	00000097          	auipc	ra,0x0
    80003d0c:	ad2080e7          	jalr	-1326(ra) # 800037da <iput>
    return 0;
    80003d10:	4a01                	li	s4,0
    80003d12:	b729                	j	80003c1c <namex+0x68>

0000000080003d14 <dirlink>:
{
    80003d14:	7139                	add	sp,sp,-64
    80003d16:	fc06                	sd	ra,56(sp)
    80003d18:	f822                	sd	s0,48(sp)
    80003d1a:	f426                	sd	s1,40(sp)
    80003d1c:	f04a                	sd	s2,32(sp)
    80003d1e:	ec4e                	sd	s3,24(sp)
    80003d20:	e852                	sd	s4,16(sp)
    80003d22:	0080                	add	s0,sp,64
    80003d24:	892a                	mv	s2,a0
    80003d26:	8a2e                	mv	s4,a1
    80003d28:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003d2a:	4601                	li	a2,0
    80003d2c:	00000097          	auipc	ra,0x0
    80003d30:	dd8080e7          	jalr	-552(ra) # 80003b04 <dirlookup>
    80003d34:	e93d                	bnez	a0,80003daa <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d36:	04c92483          	lw	s1,76(s2)
    80003d3a:	c49d                	beqz	s1,80003d68 <dirlink+0x54>
    80003d3c:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d3e:	4741                	li	a4,16
    80003d40:	86a6                	mv	a3,s1
    80003d42:	fc040613          	add	a2,s0,-64
    80003d46:	4581                	li	a1,0
    80003d48:	854a                	mv	a0,s2
    80003d4a:	00000097          	auipc	ra,0x0
    80003d4e:	b8a080e7          	jalr	-1142(ra) # 800038d4 <readi>
    80003d52:	47c1                	li	a5,16
    80003d54:	06f51163          	bne	a0,a5,80003db6 <dirlink+0xa2>
    if(de.inum == 0)
    80003d58:	fc045783          	lhu	a5,-64(s0)
    80003d5c:	c791                	beqz	a5,80003d68 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d5e:	24c1                	addw	s1,s1,16
    80003d60:	04c92783          	lw	a5,76(s2)
    80003d64:	fcf4ede3          	bltu	s1,a5,80003d3e <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003d68:	4639                	li	a2,14
    80003d6a:	85d2                	mv	a1,s4
    80003d6c:	fc240513          	add	a0,s0,-62
    80003d70:	ffffd097          	auipc	ra,0xffffd
    80003d74:	068080e7          	jalr	104(ra) # 80000dd8 <strncpy>
  de.inum = inum;
    80003d78:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d7c:	4741                	li	a4,16
    80003d7e:	86a6                	mv	a3,s1
    80003d80:	fc040613          	add	a2,s0,-64
    80003d84:	4581                	li	a1,0
    80003d86:	854a                	mv	a0,s2
    80003d88:	00000097          	auipc	ra,0x0
    80003d8c:	c44080e7          	jalr	-956(ra) # 800039cc <writei>
    80003d90:	1541                	add	a0,a0,-16
    80003d92:	00a03533          	snez	a0,a0
    80003d96:	40a00533          	neg	a0,a0
}
    80003d9a:	70e2                	ld	ra,56(sp)
    80003d9c:	7442                	ld	s0,48(sp)
    80003d9e:	74a2                	ld	s1,40(sp)
    80003da0:	7902                	ld	s2,32(sp)
    80003da2:	69e2                	ld	s3,24(sp)
    80003da4:	6a42                	ld	s4,16(sp)
    80003da6:	6121                	add	sp,sp,64
    80003da8:	8082                	ret
    iput(ip);
    80003daa:	00000097          	auipc	ra,0x0
    80003dae:	a30080e7          	jalr	-1488(ra) # 800037da <iput>
    return -1;
    80003db2:	557d                	li	a0,-1
    80003db4:	b7dd                	j	80003d9a <dirlink+0x86>
      panic("dirlink read");
    80003db6:	00005517          	auipc	a0,0x5
    80003dba:	86250513          	add	a0,a0,-1950 # 80008618 <syscalls+0x1c8>
    80003dbe:	ffffc097          	auipc	ra,0xffffc
    80003dc2:	77c080e7          	jalr	1916(ra) # 8000053a <panic>

0000000080003dc6 <namei>:

struct inode*
namei(char *path)
{
    80003dc6:	1101                	add	sp,sp,-32
    80003dc8:	ec06                	sd	ra,24(sp)
    80003dca:	e822                	sd	s0,16(sp)
    80003dcc:	1000                	add	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003dce:	fe040613          	add	a2,s0,-32
    80003dd2:	4581                	li	a1,0
    80003dd4:	00000097          	auipc	ra,0x0
    80003dd8:	de0080e7          	jalr	-544(ra) # 80003bb4 <namex>
}
    80003ddc:	60e2                	ld	ra,24(sp)
    80003dde:	6442                	ld	s0,16(sp)
    80003de0:	6105                	add	sp,sp,32
    80003de2:	8082                	ret

0000000080003de4 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003de4:	1141                	add	sp,sp,-16
    80003de6:	e406                	sd	ra,8(sp)
    80003de8:	e022                	sd	s0,0(sp)
    80003dea:	0800                	add	s0,sp,16
    80003dec:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003dee:	4585                	li	a1,1
    80003df0:	00000097          	auipc	ra,0x0
    80003df4:	dc4080e7          	jalr	-572(ra) # 80003bb4 <namex>
}
    80003df8:	60a2                	ld	ra,8(sp)
    80003dfa:	6402                	ld	s0,0(sp)
    80003dfc:	0141                	add	sp,sp,16
    80003dfe:	8082                	ret

0000000080003e00 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003e00:	1101                	add	sp,sp,-32
    80003e02:	ec06                	sd	ra,24(sp)
    80003e04:	e822                	sd	s0,16(sp)
    80003e06:	e426                	sd	s1,8(sp)
    80003e08:	e04a                	sd	s2,0(sp)
    80003e0a:	1000                	add	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003e0c:	0001d917          	auipc	s2,0x1d
    80003e10:	cf490913          	add	s2,s2,-780 # 80020b00 <log>
    80003e14:	01892583          	lw	a1,24(s2)
    80003e18:	02892503          	lw	a0,40(s2)
    80003e1c:	fffff097          	auipc	ra,0xfffff
    80003e20:	ff4080e7          	jalr	-12(ra) # 80002e10 <bread>
    80003e24:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003e26:	02c92603          	lw	a2,44(s2)
    80003e2a:	cd30                	sw	a2,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003e2c:	00c05f63          	blez	a2,80003e4a <write_head+0x4a>
    80003e30:	0001d717          	auipc	a4,0x1d
    80003e34:	d0070713          	add	a4,a4,-768 # 80020b30 <log+0x30>
    80003e38:	87aa                	mv	a5,a0
    80003e3a:	060a                	sll	a2,a2,0x2
    80003e3c:	962a                	add	a2,a2,a0
    hb->block[i] = log.lh.block[i];
    80003e3e:	4314                	lw	a3,0(a4)
    80003e40:	cff4                	sw	a3,92(a5)
  for (i = 0; i < log.lh.n; i++) {
    80003e42:	0711                	add	a4,a4,4
    80003e44:	0791                	add	a5,a5,4
    80003e46:	fec79ce3          	bne	a5,a2,80003e3e <write_head+0x3e>
  }
  bwrite(buf);
    80003e4a:	8526                	mv	a0,s1
    80003e4c:	fffff097          	auipc	ra,0xfffff
    80003e50:	0b6080e7          	jalr	182(ra) # 80002f02 <bwrite>
  brelse(buf);
    80003e54:	8526                	mv	a0,s1
    80003e56:	fffff097          	auipc	ra,0xfffff
    80003e5a:	0ea080e7          	jalr	234(ra) # 80002f40 <brelse>
}
    80003e5e:	60e2                	ld	ra,24(sp)
    80003e60:	6442                	ld	s0,16(sp)
    80003e62:	64a2                	ld	s1,8(sp)
    80003e64:	6902                	ld	s2,0(sp)
    80003e66:	6105                	add	sp,sp,32
    80003e68:	8082                	ret

0000000080003e6a <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003e6a:	0001d797          	auipc	a5,0x1d
    80003e6e:	cc27a783          	lw	a5,-830(a5) # 80020b2c <log+0x2c>
    80003e72:	0af05d63          	blez	a5,80003f2c <install_trans+0xc2>
{
    80003e76:	7139                	add	sp,sp,-64
    80003e78:	fc06                	sd	ra,56(sp)
    80003e7a:	f822                	sd	s0,48(sp)
    80003e7c:	f426                	sd	s1,40(sp)
    80003e7e:	f04a                	sd	s2,32(sp)
    80003e80:	ec4e                	sd	s3,24(sp)
    80003e82:	e852                	sd	s4,16(sp)
    80003e84:	e456                	sd	s5,8(sp)
    80003e86:	e05a                	sd	s6,0(sp)
    80003e88:	0080                	add	s0,sp,64
    80003e8a:	8b2a                	mv	s6,a0
    80003e8c:	0001da97          	auipc	s5,0x1d
    80003e90:	ca4a8a93          	add	s5,s5,-860 # 80020b30 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003e94:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003e96:	0001d997          	auipc	s3,0x1d
    80003e9a:	c6a98993          	add	s3,s3,-918 # 80020b00 <log>
    80003e9e:	a00d                	j	80003ec0 <install_trans+0x56>
    brelse(lbuf);
    80003ea0:	854a                	mv	a0,s2
    80003ea2:	fffff097          	auipc	ra,0xfffff
    80003ea6:	09e080e7          	jalr	158(ra) # 80002f40 <brelse>
    brelse(dbuf);
    80003eaa:	8526                	mv	a0,s1
    80003eac:	fffff097          	auipc	ra,0xfffff
    80003eb0:	094080e7          	jalr	148(ra) # 80002f40 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003eb4:	2a05                	addw	s4,s4,1
    80003eb6:	0a91                	add	s5,s5,4
    80003eb8:	02c9a783          	lw	a5,44(s3)
    80003ebc:	04fa5e63          	bge	s4,a5,80003f18 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003ec0:	0189a583          	lw	a1,24(s3)
    80003ec4:	014585bb          	addw	a1,a1,s4
    80003ec8:	2585                	addw	a1,a1,1
    80003eca:	0289a503          	lw	a0,40(s3)
    80003ece:	fffff097          	auipc	ra,0xfffff
    80003ed2:	f42080e7          	jalr	-190(ra) # 80002e10 <bread>
    80003ed6:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003ed8:	000aa583          	lw	a1,0(s5)
    80003edc:	0289a503          	lw	a0,40(s3)
    80003ee0:	fffff097          	auipc	ra,0xfffff
    80003ee4:	f30080e7          	jalr	-208(ra) # 80002e10 <bread>
    80003ee8:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003eea:	40000613          	li	a2,1024
    80003eee:	05890593          	add	a1,s2,88
    80003ef2:	05850513          	add	a0,a0,88
    80003ef6:	ffffd097          	auipc	ra,0xffffd
    80003efa:	e32080e7          	jalr	-462(ra) # 80000d28 <memmove>
    bwrite(dbuf);  // write dst to disk
    80003efe:	8526                	mv	a0,s1
    80003f00:	fffff097          	auipc	ra,0xfffff
    80003f04:	002080e7          	jalr	2(ra) # 80002f02 <bwrite>
    if(recovering == 0)
    80003f08:	f80b1ce3          	bnez	s6,80003ea0 <install_trans+0x36>
      bunpin(dbuf);
    80003f0c:	8526                	mv	a0,s1
    80003f0e:	fffff097          	auipc	ra,0xfffff
    80003f12:	10a080e7          	jalr	266(ra) # 80003018 <bunpin>
    80003f16:	b769                	j	80003ea0 <install_trans+0x36>
}
    80003f18:	70e2                	ld	ra,56(sp)
    80003f1a:	7442                	ld	s0,48(sp)
    80003f1c:	74a2                	ld	s1,40(sp)
    80003f1e:	7902                	ld	s2,32(sp)
    80003f20:	69e2                	ld	s3,24(sp)
    80003f22:	6a42                	ld	s4,16(sp)
    80003f24:	6aa2                	ld	s5,8(sp)
    80003f26:	6b02                	ld	s6,0(sp)
    80003f28:	6121                	add	sp,sp,64
    80003f2a:	8082                	ret
    80003f2c:	8082                	ret

0000000080003f2e <initlog>:
{
    80003f2e:	7179                	add	sp,sp,-48
    80003f30:	f406                	sd	ra,40(sp)
    80003f32:	f022                	sd	s0,32(sp)
    80003f34:	ec26                	sd	s1,24(sp)
    80003f36:	e84a                	sd	s2,16(sp)
    80003f38:	e44e                	sd	s3,8(sp)
    80003f3a:	1800                	add	s0,sp,48
    80003f3c:	892a                	mv	s2,a0
    80003f3e:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80003f40:	0001d497          	auipc	s1,0x1d
    80003f44:	bc048493          	add	s1,s1,-1088 # 80020b00 <log>
    80003f48:	00004597          	auipc	a1,0x4
    80003f4c:	6e058593          	add	a1,a1,1760 # 80008628 <syscalls+0x1d8>
    80003f50:	8526                	mv	a0,s1
    80003f52:	ffffd097          	auipc	ra,0xffffd
    80003f56:	bee080e7          	jalr	-1042(ra) # 80000b40 <initlock>
  log.start = sb->logstart;
    80003f5a:	0149a583          	lw	a1,20(s3)
    80003f5e:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80003f60:	0109a783          	lw	a5,16(s3)
    80003f64:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80003f66:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80003f6a:	854a                	mv	a0,s2
    80003f6c:	fffff097          	auipc	ra,0xfffff
    80003f70:	ea4080e7          	jalr	-348(ra) # 80002e10 <bread>
  log.lh.n = lh->n;
    80003f74:	4d30                	lw	a2,88(a0)
    80003f76:	d4d0                	sw	a2,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80003f78:	00c05f63          	blez	a2,80003f96 <initlog+0x68>
    80003f7c:	87aa                	mv	a5,a0
    80003f7e:	0001d717          	auipc	a4,0x1d
    80003f82:	bb270713          	add	a4,a4,-1102 # 80020b30 <log+0x30>
    80003f86:	060a                	sll	a2,a2,0x2
    80003f88:	962a                	add	a2,a2,a0
    log.lh.block[i] = lh->block[i];
    80003f8a:	4ff4                	lw	a3,92(a5)
    80003f8c:	c314                	sw	a3,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003f8e:	0791                	add	a5,a5,4
    80003f90:	0711                	add	a4,a4,4
    80003f92:	fec79ce3          	bne	a5,a2,80003f8a <initlog+0x5c>
  brelse(buf);
    80003f96:	fffff097          	auipc	ra,0xfffff
    80003f9a:	faa080e7          	jalr	-86(ra) # 80002f40 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80003f9e:	4505                	li	a0,1
    80003fa0:	00000097          	auipc	ra,0x0
    80003fa4:	eca080e7          	jalr	-310(ra) # 80003e6a <install_trans>
  log.lh.n = 0;
    80003fa8:	0001d797          	auipc	a5,0x1d
    80003fac:	b807a223          	sw	zero,-1148(a5) # 80020b2c <log+0x2c>
  write_head(); // clear the log
    80003fb0:	00000097          	auipc	ra,0x0
    80003fb4:	e50080e7          	jalr	-432(ra) # 80003e00 <write_head>
}
    80003fb8:	70a2                	ld	ra,40(sp)
    80003fba:	7402                	ld	s0,32(sp)
    80003fbc:	64e2                	ld	s1,24(sp)
    80003fbe:	6942                	ld	s2,16(sp)
    80003fc0:	69a2                	ld	s3,8(sp)
    80003fc2:	6145                	add	sp,sp,48
    80003fc4:	8082                	ret

0000000080003fc6 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80003fc6:	1101                	add	sp,sp,-32
    80003fc8:	ec06                	sd	ra,24(sp)
    80003fca:	e822                	sd	s0,16(sp)
    80003fcc:	e426                	sd	s1,8(sp)
    80003fce:	e04a                	sd	s2,0(sp)
    80003fd0:	1000                	add	s0,sp,32
  acquire(&log.lock);
    80003fd2:	0001d517          	auipc	a0,0x1d
    80003fd6:	b2e50513          	add	a0,a0,-1234 # 80020b00 <log>
    80003fda:	ffffd097          	auipc	ra,0xffffd
    80003fde:	bf6080e7          	jalr	-1034(ra) # 80000bd0 <acquire>
  while(1){
    if(log.committing){
    80003fe2:	0001d497          	auipc	s1,0x1d
    80003fe6:	b1e48493          	add	s1,s1,-1250 # 80020b00 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80003fea:	4979                	li	s2,30
    80003fec:	a039                	j	80003ffa <begin_op+0x34>
      sleep(&log, &log.lock);
    80003fee:	85a6                	mv	a1,s1
    80003ff0:	8526                	mv	a0,s1
    80003ff2:	ffffe097          	auipc	ra,0xffffe
    80003ff6:	05a080e7          	jalr	90(ra) # 8000204c <sleep>
    if(log.committing){
    80003ffa:	50dc                	lw	a5,36(s1)
    80003ffc:	fbed                	bnez	a5,80003fee <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80003ffe:	5098                	lw	a4,32(s1)
    80004000:	2705                	addw	a4,a4,1
    80004002:	0027179b          	sllw	a5,a4,0x2
    80004006:	9fb9                	addw	a5,a5,a4
    80004008:	0017979b          	sllw	a5,a5,0x1
    8000400c:	54d4                	lw	a3,44(s1)
    8000400e:	9fb5                	addw	a5,a5,a3
    80004010:	00f95963          	bge	s2,a5,80004022 <begin_op+0x5c>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004014:	85a6                	mv	a1,s1
    80004016:	8526                	mv	a0,s1
    80004018:	ffffe097          	auipc	ra,0xffffe
    8000401c:	034080e7          	jalr	52(ra) # 8000204c <sleep>
    80004020:	bfe9                	j	80003ffa <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004022:	0001d517          	auipc	a0,0x1d
    80004026:	ade50513          	add	a0,a0,-1314 # 80020b00 <log>
    8000402a:	d118                	sw	a4,32(a0)
      release(&log.lock);
    8000402c:	ffffd097          	auipc	ra,0xffffd
    80004030:	c58080e7          	jalr	-936(ra) # 80000c84 <release>
      break;
    }
  }
}
    80004034:	60e2                	ld	ra,24(sp)
    80004036:	6442                	ld	s0,16(sp)
    80004038:	64a2                	ld	s1,8(sp)
    8000403a:	6902                	ld	s2,0(sp)
    8000403c:	6105                	add	sp,sp,32
    8000403e:	8082                	ret

0000000080004040 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004040:	7139                	add	sp,sp,-64
    80004042:	fc06                	sd	ra,56(sp)
    80004044:	f822                	sd	s0,48(sp)
    80004046:	f426                	sd	s1,40(sp)
    80004048:	f04a                	sd	s2,32(sp)
    8000404a:	ec4e                	sd	s3,24(sp)
    8000404c:	e852                	sd	s4,16(sp)
    8000404e:	e456                	sd	s5,8(sp)
    80004050:	0080                	add	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004052:	0001d497          	auipc	s1,0x1d
    80004056:	aae48493          	add	s1,s1,-1362 # 80020b00 <log>
    8000405a:	8526                	mv	a0,s1
    8000405c:	ffffd097          	auipc	ra,0xffffd
    80004060:	b74080e7          	jalr	-1164(ra) # 80000bd0 <acquire>
  log.outstanding -= 1;
    80004064:	509c                	lw	a5,32(s1)
    80004066:	37fd                	addw	a5,a5,-1
    80004068:	0007891b          	sext.w	s2,a5
    8000406c:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000406e:	50dc                	lw	a5,36(s1)
    80004070:	e7b9                	bnez	a5,800040be <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004072:	04091e63          	bnez	s2,800040ce <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004076:	0001d497          	auipc	s1,0x1d
    8000407a:	a8a48493          	add	s1,s1,-1398 # 80020b00 <log>
    8000407e:	4785                	li	a5,1
    80004080:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004082:	8526                	mv	a0,s1
    80004084:	ffffd097          	auipc	ra,0xffffd
    80004088:	c00080e7          	jalr	-1024(ra) # 80000c84 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000408c:	54dc                	lw	a5,44(s1)
    8000408e:	06f04763          	bgtz	a5,800040fc <end_op+0xbc>
    acquire(&log.lock);
    80004092:	0001d497          	auipc	s1,0x1d
    80004096:	a6e48493          	add	s1,s1,-1426 # 80020b00 <log>
    8000409a:	8526                	mv	a0,s1
    8000409c:	ffffd097          	auipc	ra,0xffffd
    800040a0:	b34080e7          	jalr	-1228(ra) # 80000bd0 <acquire>
    log.committing = 0;
    800040a4:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800040a8:	8526                	mv	a0,s1
    800040aa:	ffffe097          	auipc	ra,0xffffe
    800040ae:	006080e7          	jalr	6(ra) # 800020b0 <wakeup>
    release(&log.lock);
    800040b2:	8526                	mv	a0,s1
    800040b4:	ffffd097          	auipc	ra,0xffffd
    800040b8:	bd0080e7          	jalr	-1072(ra) # 80000c84 <release>
}
    800040bc:	a03d                	j	800040ea <end_op+0xaa>
    panic("log.committing");
    800040be:	00004517          	auipc	a0,0x4
    800040c2:	57250513          	add	a0,a0,1394 # 80008630 <syscalls+0x1e0>
    800040c6:	ffffc097          	auipc	ra,0xffffc
    800040ca:	474080e7          	jalr	1140(ra) # 8000053a <panic>
    wakeup(&log);
    800040ce:	0001d497          	auipc	s1,0x1d
    800040d2:	a3248493          	add	s1,s1,-1486 # 80020b00 <log>
    800040d6:	8526                	mv	a0,s1
    800040d8:	ffffe097          	auipc	ra,0xffffe
    800040dc:	fd8080e7          	jalr	-40(ra) # 800020b0 <wakeup>
  release(&log.lock);
    800040e0:	8526                	mv	a0,s1
    800040e2:	ffffd097          	auipc	ra,0xffffd
    800040e6:	ba2080e7          	jalr	-1118(ra) # 80000c84 <release>
}
    800040ea:	70e2                	ld	ra,56(sp)
    800040ec:	7442                	ld	s0,48(sp)
    800040ee:	74a2                	ld	s1,40(sp)
    800040f0:	7902                	ld	s2,32(sp)
    800040f2:	69e2                	ld	s3,24(sp)
    800040f4:	6a42                	ld	s4,16(sp)
    800040f6:	6aa2                	ld	s5,8(sp)
    800040f8:	6121                	add	sp,sp,64
    800040fa:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800040fc:	0001da97          	auipc	s5,0x1d
    80004100:	a34a8a93          	add	s5,s5,-1484 # 80020b30 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004104:	0001da17          	auipc	s4,0x1d
    80004108:	9fca0a13          	add	s4,s4,-1540 # 80020b00 <log>
    8000410c:	018a2583          	lw	a1,24(s4)
    80004110:	012585bb          	addw	a1,a1,s2
    80004114:	2585                	addw	a1,a1,1
    80004116:	028a2503          	lw	a0,40(s4)
    8000411a:	fffff097          	auipc	ra,0xfffff
    8000411e:	cf6080e7          	jalr	-778(ra) # 80002e10 <bread>
    80004122:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004124:	000aa583          	lw	a1,0(s5)
    80004128:	028a2503          	lw	a0,40(s4)
    8000412c:	fffff097          	auipc	ra,0xfffff
    80004130:	ce4080e7          	jalr	-796(ra) # 80002e10 <bread>
    80004134:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004136:	40000613          	li	a2,1024
    8000413a:	05850593          	add	a1,a0,88
    8000413e:	05848513          	add	a0,s1,88
    80004142:	ffffd097          	auipc	ra,0xffffd
    80004146:	be6080e7          	jalr	-1050(ra) # 80000d28 <memmove>
    bwrite(to);  // write the log
    8000414a:	8526                	mv	a0,s1
    8000414c:	fffff097          	auipc	ra,0xfffff
    80004150:	db6080e7          	jalr	-586(ra) # 80002f02 <bwrite>
    brelse(from);
    80004154:	854e                	mv	a0,s3
    80004156:	fffff097          	auipc	ra,0xfffff
    8000415a:	dea080e7          	jalr	-534(ra) # 80002f40 <brelse>
    brelse(to);
    8000415e:	8526                	mv	a0,s1
    80004160:	fffff097          	auipc	ra,0xfffff
    80004164:	de0080e7          	jalr	-544(ra) # 80002f40 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004168:	2905                	addw	s2,s2,1
    8000416a:	0a91                	add	s5,s5,4
    8000416c:	02ca2783          	lw	a5,44(s4)
    80004170:	f8f94ee3          	blt	s2,a5,8000410c <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004174:	00000097          	auipc	ra,0x0
    80004178:	c8c080e7          	jalr	-884(ra) # 80003e00 <write_head>
    install_trans(0); // Now install writes to home locations
    8000417c:	4501                	li	a0,0
    8000417e:	00000097          	auipc	ra,0x0
    80004182:	cec080e7          	jalr	-788(ra) # 80003e6a <install_trans>
    log.lh.n = 0;
    80004186:	0001d797          	auipc	a5,0x1d
    8000418a:	9a07a323          	sw	zero,-1626(a5) # 80020b2c <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000418e:	00000097          	auipc	ra,0x0
    80004192:	c72080e7          	jalr	-910(ra) # 80003e00 <write_head>
    80004196:	bdf5                	j	80004092 <end_op+0x52>

0000000080004198 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004198:	1101                	add	sp,sp,-32
    8000419a:	ec06                	sd	ra,24(sp)
    8000419c:	e822                	sd	s0,16(sp)
    8000419e:	e426                	sd	s1,8(sp)
    800041a0:	e04a                	sd	s2,0(sp)
    800041a2:	1000                	add	s0,sp,32
    800041a4:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800041a6:	0001d917          	auipc	s2,0x1d
    800041aa:	95a90913          	add	s2,s2,-1702 # 80020b00 <log>
    800041ae:	854a                	mv	a0,s2
    800041b0:	ffffd097          	auipc	ra,0xffffd
    800041b4:	a20080e7          	jalr	-1504(ra) # 80000bd0 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800041b8:	02c92603          	lw	a2,44(s2)
    800041bc:	47f5                	li	a5,29
    800041be:	06c7c563          	blt	a5,a2,80004228 <log_write+0x90>
    800041c2:	0001d797          	auipc	a5,0x1d
    800041c6:	95a7a783          	lw	a5,-1702(a5) # 80020b1c <log+0x1c>
    800041ca:	37fd                	addw	a5,a5,-1
    800041cc:	04f65e63          	bge	a2,a5,80004228 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800041d0:	0001d797          	auipc	a5,0x1d
    800041d4:	9507a783          	lw	a5,-1712(a5) # 80020b20 <log+0x20>
    800041d8:	06f05063          	blez	a5,80004238 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800041dc:	4781                	li	a5,0
    800041de:	06c05563          	blez	a2,80004248 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800041e2:	44cc                	lw	a1,12(s1)
    800041e4:	0001d717          	auipc	a4,0x1d
    800041e8:	94c70713          	add	a4,a4,-1716 # 80020b30 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800041ec:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800041ee:	4314                	lw	a3,0(a4)
    800041f0:	04b68c63          	beq	a3,a1,80004248 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800041f4:	2785                	addw	a5,a5,1
    800041f6:	0711                	add	a4,a4,4
    800041f8:	fef61be3          	bne	a2,a5,800041ee <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800041fc:	0621                	add	a2,a2,8
    800041fe:	060a                	sll	a2,a2,0x2
    80004200:	0001d797          	auipc	a5,0x1d
    80004204:	90078793          	add	a5,a5,-1792 # 80020b00 <log>
    80004208:	97b2                	add	a5,a5,a2
    8000420a:	44d8                	lw	a4,12(s1)
    8000420c:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000420e:	8526                	mv	a0,s1
    80004210:	fffff097          	auipc	ra,0xfffff
    80004214:	dcc080e7          	jalr	-564(ra) # 80002fdc <bpin>
    log.lh.n++;
    80004218:	0001d717          	auipc	a4,0x1d
    8000421c:	8e870713          	add	a4,a4,-1816 # 80020b00 <log>
    80004220:	575c                	lw	a5,44(a4)
    80004222:	2785                	addw	a5,a5,1
    80004224:	d75c                	sw	a5,44(a4)
    80004226:	a82d                	j	80004260 <log_write+0xc8>
    panic("too big a transaction");
    80004228:	00004517          	auipc	a0,0x4
    8000422c:	41850513          	add	a0,a0,1048 # 80008640 <syscalls+0x1f0>
    80004230:	ffffc097          	auipc	ra,0xffffc
    80004234:	30a080e7          	jalr	778(ra) # 8000053a <panic>
    panic("log_write outside of trans");
    80004238:	00004517          	auipc	a0,0x4
    8000423c:	42050513          	add	a0,a0,1056 # 80008658 <syscalls+0x208>
    80004240:	ffffc097          	auipc	ra,0xffffc
    80004244:	2fa080e7          	jalr	762(ra) # 8000053a <panic>
  log.lh.block[i] = b->blockno;
    80004248:	00878693          	add	a3,a5,8
    8000424c:	068a                	sll	a3,a3,0x2
    8000424e:	0001d717          	auipc	a4,0x1d
    80004252:	8b270713          	add	a4,a4,-1870 # 80020b00 <log>
    80004256:	9736                	add	a4,a4,a3
    80004258:	44d4                	lw	a3,12(s1)
    8000425a:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000425c:	faf609e3          	beq	a2,a5,8000420e <log_write+0x76>
  }
  release(&log.lock);
    80004260:	0001d517          	auipc	a0,0x1d
    80004264:	8a050513          	add	a0,a0,-1888 # 80020b00 <log>
    80004268:	ffffd097          	auipc	ra,0xffffd
    8000426c:	a1c080e7          	jalr	-1508(ra) # 80000c84 <release>
}
    80004270:	60e2                	ld	ra,24(sp)
    80004272:	6442                	ld	s0,16(sp)
    80004274:	64a2                	ld	s1,8(sp)
    80004276:	6902                	ld	s2,0(sp)
    80004278:	6105                	add	sp,sp,32
    8000427a:	8082                	ret

000000008000427c <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000427c:	1101                	add	sp,sp,-32
    8000427e:	ec06                	sd	ra,24(sp)
    80004280:	e822                	sd	s0,16(sp)
    80004282:	e426                	sd	s1,8(sp)
    80004284:	e04a                	sd	s2,0(sp)
    80004286:	1000                	add	s0,sp,32
    80004288:	84aa                	mv	s1,a0
    8000428a:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000428c:	00004597          	auipc	a1,0x4
    80004290:	3ec58593          	add	a1,a1,1004 # 80008678 <syscalls+0x228>
    80004294:	0521                	add	a0,a0,8
    80004296:	ffffd097          	auipc	ra,0xffffd
    8000429a:	8aa080e7          	jalr	-1878(ra) # 80000b40 <initlock>
  lk->name = name;
    8000429e:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800042a2:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800042a6:	0204a423          	sw	zero,40(s1)
}
    800042aa:	60e2                	ld	ra,24(sp)
    800042ac:	6442                	ld	s0,16(sp)
    800042ae:	64a2                	ld	s1,8(sp)
    800042b0:	6902                	ld	s2,0(sp)
    800042b2:	6105                	add	sp,sp,32
    800042b4:	8082                	ret

00000000800042b6 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800042b6:	1101                	add	sp,sp,-32
    800042b8:	ec06                	sd	ra,24(sp)
    800042ba:	e822                	sd	s0,16(sp)
    800042bc:	e426                	sd	s1,8(sp)
    800042be:	e04a                	sd	s2,0(sp)
    800042c0:	1000                	add	s0,sp,32
    800042c2:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800042c4:	00850913          	add	s2,a0,8
    800042c8:	854a                	mv	a0,s2
    800042ca:	ffffd097          	auipc	ra,0xffffd
    800042ce:	906080e7          	jalr	-1786(ra) # 80000bd0 <acquire>
  while (lk->locked) {
    800042d2:	409c                	lw	a5,0(s1)
    800042d4:	cb89                	beqz	a5,800042e6 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800042d6:	85ca                	mv	a1,s2
    800042d8:	8526                	mv	a0,s1
    800042da:	ffffe097          	auipc	ra,0xffffe
    800042de:	d72080e7          	jalr	-654(ra) # 8000204c <sleep>
  while (lk->locked) {
    800042e2:	409c                	lw	a5,0(s1)
    800042e4:	fbed                	bnez	a5,800042d6 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800042e6:	4785                	li	a5,1
    800042e8:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800042ea:	ffffd097          	auipc	ra,0xffffd
    800042ee:	6ba080e7          	jalr	1722(ra) # 800019a4 <myproc>
    800042f2:	591c                	lw	a5,48(a0)
    800042f4:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800042f6:	854a                	mv	a0,s2
    800042f8:	ffffd097          	auipc	ra,0xffffd
    800042fc:	98c080e7          	jalr	-1652(ra) # 80000c84 <release>
}
    80004300:	60e2                	ld	ra,24(sp)
    80004302:	6442                	ld	s0,16(sp)
    80004304:	64a2                	ld	s1,8(sp)
    80004306:	6902                	ld	s2,0(sp)
    80004308:	6105                	add	sp,sp,32
    8000430a:	8082                	ret

000000008000430c <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000430c:	1101                	add	sp,sp,-32
    8000430e:	ec06                	sd	ra,24(sp)
    80004310:	e822                	sd	s0,16(sp)
    80004312:	e426                	sd	s1,8(sp)
    80004314:	e04a                	sd	s2,0(sp)
    80004316:	1000                	add	s0,sp,32
    80004318:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000431a:	00850913          	add	s2,a0,8
    8000431e:	854a                	mv	a0,s2
    80004320:	ffffd097          	auipc	ra,0xffffd
    80004324:	8b0080e7          	jalr	-1872(ra) # 80000bd0 <acquire>
  lk->locked = 0;
    80004328:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000432c:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004330:	8526                	mv	a0,s1
    80004332:	ffffe097          	auipc	ra,0xffffe
    80004336:	d7e080e7          	jalr	-642(ra) # 800020b0 <wakeup>
  release(&lk->lk);
    8000433a:	854a                	mv	a0,s2
    8000433c:	ffffd097          	auipc	ra,0xffffd
    80004340:	948080e7          	jalr	-1720(ra) # 80000c84 <release>
}
    80004344:	60e2                	ld	ra,24(sp)
    80004346:	6442                	ld	s0,16(sp)
    80004348:	64a2                	ld	s1,8(sp)
    8000434a:	6902                	ld	s2,0(sp)
    8000434c:	6105                	add	sp,sp,32
    8000434e:	8082                	ret

0000000080004350 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004350:	7179                	add	sp,sp,-48
    80004352:	f406                	sd	ra,40(sp)
    80004354:	f022                	sd	s0,32(sp)
    80004356:	ec26                	sd	s1,24(sp)
    80004358:	e84a                	sd	s2,16(sp)
    8000435a:	e44e                	sd	s3,8(sp)
    8000435c:	1800                	add	s0,sp,48
    8000435e:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004360:	00850913          	add	s2,a0,8
    80004364:	854a                	mv	a0,s2
    80004366:	ffffd097          	auipc	ra,0xffffd
    8000436a:	86a080e7          	jalr	-1942(ra) # 80000bd0 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000436e:	409c                	lw	a5,0(s1)
    80004370:	ef99                	bnez	a5,8000438e <holdingsleep+0x3e>
    80004372:	4481                	li	s1,0
  release(&lk->lk);
    80004374:	854a                	mv	a0,s2
    80004376:	ffffd097          	auipc	ra,0xffffd
    8000437a:	90e080e7          	jalr	-1778(ra) # 80000c84 <release>
  return r;
}
    8000437e:	8526                	mv	a0,s1
    80004380:	70a2                	ld	ra,40(sp)
    80004382:	7402                	ld	s0,32(sp)
    80004384:	64e2                	ld	s1,24(sp)
    80004386:	6942                	ld	s2,16(sp)
    80004388:	69a2                	ld	s3,8(sp)
    8000438a:	6145                	add	sp,sp,48
    8000438c:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000438e:	0284a983          	lw	s3,40(s1)
    80004392:	ffffd097          	auipc	ra,0xffffd
    80004396:	612080e7          	jalr	1554(ra) # 800019a4 <myproc>
    8000439a:	5904                	lw	s1,48(a0)
    8000439c:	413484b3          	sub	s1,s1,s3
    800043a0:	0014b493          	seqz	s1,s1
    800043a4:	bfc1                	j	80004374 <holdingsleep+0x24>

00000000800043a6 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800043a6:	1141                	add	sp,sp,-16
    800043a8:	e406                	sd	ra,8(sp)
    800043aa:	e022                	sd	s0,0(sp)
    800043ac:	0800                	add	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800043ae:	00004597          	auipc	a1,0x4
    800043b2:	2da58593          	add	a1,a1,730 # 80008688 <syscalls+0x238>
    800043b6:	0001d517          	auipc	a0,0x1d
    800043ba:	89250513          	add	a0,a0,-1902 # 80020c48 <ftable>
    800043be:	ffffc097          	auipc	ra,0xffffc
    800043c2:	782080e7          	jalr	1922(ra) # 80000b40 <initlock>
}
    800043c6:	60a2                	ld	ra,8(sp)
    800043c8:	6402                	ld	s0,0(sp)
    800043ca:	0141                	add	sp,sp,16
    800043cc:	8082                	ret

00000000800043ce <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800043ce:	1101                	add	sp,sp,-32
    800043d0:	ec06                	sd	ra,24(sp)
    800043d2:	e822                	sd	s0,16(sp)
    800043d4:	e426                	sd	s1,8(sp)
    800043d6:	1000                	add	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800043d8:	0001d517          	auipc	a0,0x1d
    800043dc:	87050513          	add	a0,a0,-1936 # 80020c48 <ftable>
    800043e0:	ffffc097          	auipc	ra,0xffffc
    800043e4:	7f0080e7          	jalr	2032(ra) # 80000bd0 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800043e8:	0001d497          	auipc	s1,0x1d
    800043ec:	87848493          	add	s1,s1,-1928 # 80020c60 <ftable+0x18>
    800043f0:	0001e717          	auipc	a4,0x1e
    800043f4:	81070713          	add	a4,a4,-2032 # 80021c00 <disk>
    if(f->ref == 0){
    800043f8:	40dc                	lw	a5,4(s1)
    800043fa:	cf99                	beqz	a5,80004418 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800043fc:	02848493          	add	s1,s1,40
    80004400:	fee49ce3          	bne	s1,a4,800043f8 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004404:	0001d517          	auipc	a0,0x1d
    80004408:	84450513          	add	a0,a0,-1980 # 80020c48 <ftable>
    8000440c:	ffffd097          	auipc	ra,0xffffd
    80004410:	878080e7          	jalr	-1928(ra) # 80000c84 <release>
  return 0;
    80004414:	4481                	li	s1,0
    80004416:	a819                	j	8000442c <filealloc+0x5e>
      f->ref = 1;
    80004418:	4785                	li	a5,1
    8000441a:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000441c:	0001d517          	auipc	a0,0x1d
    80004420:	82c50513          	add	a0,a0,-2004 # 80020c48 <ftable>
    80004424:	ffffd097          	auipc	ra,0xffffd
    80004428:	860080e7          	jalr	-1952(ra) # 80000c84 <release>
}
    8000442c:	8526                	mv	a0,s1
    8000442e:	60e2                	ld	ra,24(sp)
    80004430:	6442                	ld	s0,16(sp)
    80004432:	64a2                	ld	s1,8(sp)
    80004434:	6105                	add	sp,sp,32
    80004436:	8082                	ret

0000000080004438 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004438:	1101                	add	sp,sp,-32
    8000443a:	ec06                	sd	ra,24(sp)
    8000443c:	e822                	sd	s0,16(sp)
    8000443e:	e426                	sd	s1,8(sp)
    80004440:	1000                	add	s0,sp,32
    80004442:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004444:	0001d517          	auipc	a0,0x1d
    80004448:	80450513          	add	a0,a0,-2044 # 80020c48 <ftable>
    8000444c:	ffffc097          	auipc	ra,0xffffc
    80004450:	784080e7          	jalr	1924(ra) # 80000bd0 <acquire>
  if(f->ref < 1)
    80004454:	40dc                	lw	a5,4(s1)
    80004456:	02f05263          	blez	a5,8000447a <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000445a:	2785                	addw	a5,a5,1
    8000445c:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000445e:	0001c517          	auipc	a0,0x1c
    80004462:	7ea50513          	add	a0,a0,2026 # 80020c48 <ftable>
    80004466:	ffffd097          	auipc	ra,0xffffd
    8000446a:	81e080e7          	jalr	-2018(ra) # 80000c84 <release>
  return f;
}
    8000446e:	8526                	mv	a0,s1
    80004470:	60e2                	ld	ra,24(sp)
    80004472:	6442                	ld	s0,16(sp)
    80004474:	64a2                	ld	s1,8(sp)
    80004476:	6105                	add	sp,sp,32
    80004478:	8082                	ret
    panic("filedup");
    8000447a:	00004517          	auipc	a0,0x4
    8000447e:	21650513          	add	a0,a0,534 # 80008690 <syscalls+0x240>
    80004482:	ffffc097          	auipc	ra,0xffffc
    80004486:	0b8080e7          	jalr	184(ra) # 8000053a <panic>

000000008000448a <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000448a:	7139                	add	sp,sp,-64
    8000448c:	fc06                	sd	ra,56(sp)
    8000448e:	f822                	sd	s0,48(sp)
    80004490:	f426                	sd	s1,40(sp)
    80004492:	f04a                	sd	s2,32(sp)
    80004494:	ec4e                	sd	s3,24(sp)
    80004496:	e852                	sd	s4,16(sp)
    80004498:	e456                	sd	s5,8(sp)
    8000449a:	0080                	add	s0,sp,64
    8000449c:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000449e:	0001c517          	auipc	a0,0x1c
    800044a2:	7aa50513          	add	a0,a0,1962 # 80020c48 <ftable>
    800044a6:	ffffc097          	auipc	ra,0xffffc
    800044aa:	72a080e7          	jalr	1834(ra) # 80000bd0 <acquire>
  if(f->ref < 1)
    800044ae:	40dc                	lw	a5,4(s1)
    800044b0:	06f05163          	blez	a5,80004512 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800044b4:	37fd                	addw	a5,a5,-1
    800044b6:	0007871b          	sext.w	a4,a5
    800044ba:	c0dc                	sw	a5,4(s1)
    800044bc:	06e04363          	bgtz	a4,80004522 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800044c0:	0004a903          	lw	s2,0(s1)
    800044c4:	0094ca83          	lbu	s5,9(s1)
    800044c8:	0104ba03          	ld	s4,16(s1)
    800044cc:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800044d0:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800044d4:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800044d8:	0001c517          	auipc	a0,0x1c
    800044dc:	77050513          	add	a0,a0,1904 # 80020c48 <ftable>
    800044e0:	ffffc097          	auipc	ra,0xffffc
    800044e4:	7a4080e7          	jalr	1956(ra) # 80000c84 <release>

  if(ff.type == FD_PIPE){
    800044e8:	4785                	li	a5,1
    800044ea:	04f90d63          	beq	s2,a5,80004544 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800044ee:	3979                	addw	s2,s2,-2
    800044f0:	4785                	li	a5,1
    800044f2:	0527e063          	bltu	a5,s2,80004532 <fileclose+0xa8>
    begin_op();
    800044f6:	00000097          	auipc	ra,0x0
    800044fa:	ad0080e7          	jalr	-1328(ra) # 80003fc6 <begin_op>
    iput(ff.ip);
    800044fe:	854e                	mv	a0,s3
    80004500:	fffff097          	auipc	ra,0xfffff
    80004504:	2da080e7          	jalr	730(ra) # 800037da <iput>
    end_op();
    80004508:	00000097          	auipc	ra,0x0
    8000450c:	b38080e7          	jalr	-1224(ra) # 80004040 <end_op>
    80004510:	a00d                	j	80004532 <fileclose+0xa8>
    panic("fileclose");
    80004512:	00004517          	auipc	a0,0x4
    80004516:	18650513          	add	a0,a0,390 # 80008698 <syscalls+0x248>
    8000451a:	ffffc097          	auipc	ra,0xffffc
    8000451e:	020080e7          	jalr	32(ra) # 8000053a <panic>
    release(&ftable.lock);
    80004522:	0001c517          	auipc	a0,0x1c
    80004526:	72650513          	add	a0,a0,1830 # 80020c48 <ftable>
    8000452a:	ffffc097          	auipc	ra,0xffffc
    8000452e:	75a080e7          	jalr	1882(ra) # 80000c84 <release>
  }
}
    80004532:	70e2                	ld	ra,56(sp)
    80004534:	7442                	ld	s0,48(sp)
    80004536:	74a2                	ld	s1,40(sp)
    80004538:	7902                	ld	s2,32(sp)
    8000453a:	69e2                	ld	s3,24(sp)
    8000453c:	6a42                	ld	s4,16(sp)
    8000453e:	6aa2                	ld	s5,8(sp)
    80004540:	6121                	add	sp,sp,64
    80004542:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004544:	85d6                	mv	a1,s5
    80004546:	8552                	mv	a0,s4
    80004548:	00000097          	auipc	ra,0x0
    8000454c:	348080e7          	jalr	840(ra) # 80004890 <pipeclose>
    80004550:	b7cd                	j	80004532 <fileclose+0xa8>

0000000080004552 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004552:	715d                	add	sp,sp,-80
    80004554:	e486                	sd	ra,72(sp)
    80004556:	e0a2                	sd	s0,64(sp)
    80004558:	fc26                	sd	s1,56(sp)
    8000455a:	f84a                	sd	s2,48(sp)
    8000455c:	f44e                	sd	s3,40(sp)
    8000455e:	0880                	add	s0,sp,80
    80004560:	84aa                	mv	s1,a0
    80004562:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004564:	ffffd097          	auipc	ra,0xffffd
    80004568:	440080e7          	jalr	1088(ra) # 800019a4 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000456c:	409c                	lw	a5,0(s1)
    8000456e:	37f9                	addw	a5,a5,-2
    80004570:	4705                	li	a4,1
    80004572:	04f76763          	bltu	a4,a5,800045c0 <filestat+0x6e>
    80004576:	892a                	mv	s2,a0
    ilock(f->ip);
    80004578:	6c88                	ld	a0,24(s1)
    8000457a:	fffff097          	auipc	ra,0xfffff
    8000457e:	0a6080e7          	jalr	166(ra) # 80003620 <ilock>
    stati(f->ip, &st);
    80004582:	fb840593          	add	a1,s0,-72
    80004586:	6c88                	ld	a0,24(s1)
    80004588:	fffff097          	auipc	ra,0xfffff
    8000458c:	322080e7          	jalr	802(ra) # 800038aa <stati>
    iunlock(f->ip);
    80004590:	6c88                	ld	a0,24(s1)
    80004592:	fffff097          	auipc	ra,0xfffff
    80004596:	150080e7          	jalr	336(ra) # 800036e2 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000459a:	46e1                	li	a3,24
    8000459c:	fb840613          	add	a2,s0,-72
    800045a0:	85ce                	mv	a1,s3
    800045a2:	05093503          	ld	a0,80(s2)
    800045a6:	ffffd097          	auipc	ra,0xffffd
    800045aa:	0be080e7          	jalr	190(ra) # 80001664 <copyout>
    800045ae:	41f5551b          	sraw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800045b2:	60a6                	ld	ra,72(sp)
    800045b4:	6406                	ld	s0,64(sp)
    800045b6:	74e2                	ld	s1,56(sp)
    800045b8:	7942                	ld	s2,48(sp)
    800045ba:	79a2                	ld	s3,40(sp)
    800045bc:	6161                	add	sp,sp,80
    800045be:	8082                	ret
  return -1;
    800045c0:	557d                	li	a0,-1
    800045c2:	bfc5                	j	800045b2 <filestat+0x60>

00000000800045c4 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800045c4:	7179                	add	sp,sp,-48
    800045c6:	f406                	sd	ra,40(sp)
    800045c8:	f022                	sd	s0,32(sp)
    800045ca:	ec26                	sd	s1,24(sp)
    800045cc:	e84a                	sd	s2,16(sp)
    800045ce:	e44e                	sd	s3,8(sp)
    800045d0:	1800                	add	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800045d2:	00854783          	lbu	a5,8(a0)
    800045d6:	c3d5                	beqz	a5,8000467a <fileread+0xb6>
    800045d8:	84aa                	mv	s1,a0
    800045da:	89ae                	mv	s3,a1
    800045dc:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800045de:	411c                	lw	a5,0(a0)
    800045e0:	4705                	li	a4,1
    800045e2:	04e78963          	beq	a5,a4,80004634 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800045e6:	470d                	li	a4,3
    800045e8:	04e78d63          	beq	a5,a4,80004642 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800045ec:	4709                	li	a4,2
    800045ee:	06e79e63          	bne	a5,a4,8000466a <fileread+0xa6>
    ilock(f->ip);
    800045f2:	6d08                	ld	a0,24(a0)
    800045f4:	fffff097          	auipc	ra,0xfffff
    800045f8:	02c080e7          	jalr	44(ra) # 80003620 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800045fc:	874a                	mv	a4,s2
    800045fe:	5094                	lw	a3,32(s1)
    80004600:	864e                	mv	a2,s3
    80004602:	4585                	li	a1,1
    80004604:	6c88                	ld	a0,24(s1)
    80004606:	fffff097          	auipc	ra,0xfffff
    8000460a:	2ce080e7          	jalr	718(ra) # 800038d4 <readi>
    8000460e:	892a                	mv	s2,a0
    80004610:	00a05563          	blez	a0,8000461a <fileread+0x56>
      f->off += r;
    80004614:	509c                	lw	a5,32(s1)
    80004616:	9fa9                	addw	a5,a5,a0
    80004618:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000461a:	6c88                	ld	a0,24(s1)
    8000461c:	fffff097          	auipc	ra,0xfffff
    80004620:	0c6080e7          	jalr	198(ra) # 800036e2 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004624:	854a                	mv	a0,s2
    80004626:	70a2                	ld	ra,40(sp)
    80004628:	7402                	ld	s0,32(sp)
    8000462a:	64e2                	ld	s1,24(sp)
    8000462c:	6942                	ld	s2,16(sp)
    8000462e:	69a2                	ld	s3,8(sp)
    80004630:	6145                	add	sp,sp,48
    80004632:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004634:	6908                	ld	a0,16(a0)
    80004636:	00000097          	auipc	ra,0x0
    8000463a:	3c2080e7          	jalr	962(ra) # 800049f8 <piperead>
    8000463e:	892a                	mv	s2,a0
    80004640:	b7d5                	j	80004624 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004642:	02451783          	lh	a5,36(a0)
    80004646:	03079693          	sll	a3,a5,0x30
    8000464a:	92c1                	srl	a3,a3,0x30
    8000464c:	4725                	li	a4,9
    8000464e:	02d76863          	bltu	a4,a3,8000467e <fileread+0xba>
    80004652:	0792                	sll	a5,a5,0x4
    80004654:	0001c717          	auipc	a4,0x1c
    80004658:	55470713          	add	a4,a4,1364 # 80020ba8 <devsw>
    8000465c:	97ba                	add	a5,a5,a4
    8000465e:	639c                	ld	a5,0(a5)
    80004660:	c38d                	beqz	a5,80004682 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004662:	4505                	li	a0,1
    80004664:	9782                	jalr	a5
    80004666:	892a                	mv	s2,a0
    80004668:	bf75                	j	80004624 <fileread+0x60>
    panic("fileread");
    8000466a:	00004517          	auipc	a0,0x4
    8000466e:	03e50513          	add	a0,a0,62 # 800086a8 <syscalls+0x258>
    80004672:	ffffc097          	auipc	ra,0xffffc
    80004676:	ec8080e7          	jalr	-312(ra) # 8000053a <panic>
    return -1;
    8000467a:	597d                	li	s2,-1
    8000467c:	b765                	j	80004624 <fileread+0x60>
      return -1;
    8000467e:	597d                	li	s2,-1
    80004680:	b755                	j	80004624 <fileread+0x60>
    80004682:	597d                	li	s2,-1
    80004684:	b745                	j	80004624 <fileread+0x60>

0000000080004686 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004686:	00954783          	lbu	a5,9(a0)
    8000468a:	10078e63          	beqz	a5,800047a6 <filewrite+0x120>
{
    8000468e:	715d                	add	sp,sp,-80
    80004690:	e486                	sd	ra,72(sp)
    80004692:	e0a2                	sd	s0,64(sp)
    80004694:	fc26                	sd	s1,56(sp)
    80004696:	f84a                	sd	s2,48(sp)
    80004698:	f44e                	sd	s3,40(sp)
    8000469a:	f052                	sd	s4,32(sp)
    8000469c:	ec56                	sd	s5,24(sp)
    8000469e:	e85a                	sd	s6,16(sp)
    800046a0:	e45e                	sd	s7,8(sp)
    800046a2:	e062                	sd	s8,0(sp)
    800046a4:	0880                	add	s0,sp,80
    800046a6:	892a                	mv	s2,a0
    800046a8:	8b2e                	mv	s6,a1
    800046aa:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800046ac:	411c                	lw	a5,0(a0)
    800046ae:	4705                	li	a4,1
    800046b0:	02e78263          	beq	a5,a4,800046d4 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800046b4:	470d                	li	a4,3
    800046b6:	02e78563          	beq	a5,a4,800046e0 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800046ba:	4709                	li	a4,2
    800046bc:	0ce79d63          	bne	a5,a4,80004796 <filewrite+0x110>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800046c0:	0ac05b63          	blez	a2,80004776 <filewrite+0xf0>
    int i = 0;
    800046c4:	4981                	li	s3,0
      int n1 = n - i;
      if(n1 > max)
    800046c6:	6b85                	lui	s7,0x1
    800046c8:	c00b8b93          	add	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    800046cc:	6c05                	lui	s8,0x1
    800046ce:	c00c0c1b          	addw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    800046d2:	a851                	j	80004766 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    800046d4:	6908                	ld	a0,16(a0)
    800046d6:	00000097          	auipc	ra,0x0
    800046da:	22a080e7          	jalr	554(ra) # 80004900 <pipewrite>
    800046de:	a045                	j	8000477e <filewrite+0xf8>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800046e0:	02451783          	lh	a5,36(a0)
    800046e4:	03079693          	sll	a3,a5,0x30
    800046e8:	92c1                	srl	a3,a3,0x30
    800046ea:	4725                	li	a4,9
    800046ec:	0ad76f63          	bltu	a4,a3,800047aa <filewrite+0x124>
    800046f0:	0792                	sll	a5,a5,0x4
    800046f2:	0001c717          	auipc	a4,0x1c
    800046f6:	4b670713          	add	a4,a4,1206 # 80020ba8 <devsw>
    800046fa:	97ba                	add	a5,a5,a4
    800046fc:	679c                	ld	a5,8(a5)
    800046fe:	cbc5                	beqz	a5,800047ae <filewrite+0x128>
    ret = devsw[f->major].write(1, addr, n);
    80004700:	4505                	li	a0,1
    80004702:	9782                	jalr	a5
    80004704:	a8ad                	j	8000477e <filewrite+0xf8>
      if(n1 > max)
    80004706:	00048a9b          	sext.w	s5,s1
        n1 = max;

      begin_op();
    8000470a:	00000097          	auipc	ra,0x0
    8000470e:	8bc080e7          	jalr	-1860(ra) # 80003fc6 <begin_op>
      ilock(f->ip);
    80004712:	01893503          	ld	a0,24(s2)
    80004716:	fffff097          	auipc	ra,0xfffff
    8000471a:	f0a080e7          	jalr	-246(ra) # 80003620 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    8000471e:	8756                	mv	a4,s5
    80004720:	02092683          	lw	a3,32(s2)
    80004724:	01698633          	add	a2,s3,s6
    80004728:	4585                	li	a1,1
    8000472a:	01893503          	ld	a0,24(s2)
    8000472e:	fffff097          	auipc	ra,0xfffff
    80004732:	29e080e7          	jalr	670(ra) # 800039cc <writei>
    80004736:	84aa                	mv	s1,a0
    80004738:	00a05763          	blez	a0,80004746 <filewrite+0xc0>
        f->off += r;
    8000473c:	02092783          	lw	a5,32(s2)
    80004740:	9fa9                	addw	a5,a5,a0
    80004742:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004746:	01893503          	ld	a0,24(s2)
    8000474a:	fffff097          	auipc	ra,0xfffff
    8000474e:	f98080e7          	jalr	-104(ra) # 800036e2 <iunlock>
      end_op();
    80004752:	00000097          	auipc	ra,0x0
    80004756:	8ee080e7          	jalr	-1810(ra) # 80004040 <end_op>

      if(r != n1){
    8000475a:	009a9f63          	bne	s5,s1,80004778 <filewrite+0xf2>
        // error from writei
        break;
      }
      i += r;
    8000475e:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004762:	0149db63          	bge	s3,s4,80004778 <filewrite+0xf2>
      int n1 = n - i;
    80004766:	413a04bb          	subw	s1,s4,s3
      if(n1 > max)
    8000476a:	0004879b          	sext.w	a5,s1
    8000476e:	f8fbdce3          	bge	s7,a5,80004706 <filewrite+0x80>
    80004772:	84e2                	mv	s1,s8
    80004774:	bf49                	j	80004706 <filewrite+0x80>
    int i = 0;
    80004776:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004778:	033a1d63          	bne	s4,s3,800047b2 <filewrite+0x12c>
    8000477c:	8552                	mv	a0,s4
  } else {
    panic("filewrite");
  }

  return ret;
}
    8000477e:	60a6                	ld	ra,72(sp)
    80004780:	6406                	ld	s0,64(sp)
    80004782:	74e2                	ld	s1,56(sp)
    80004784:	7942                	ld	s2,48(sp)
    80004786:	79a2                	ld	s3,40(sp)
    80004788:	7a02                	ld	s4,32(sp)
    8000478a:	6ae2                	ld	s5,24(sp)
    8000478c:	6b42                	ld	s6,16(sp)
    8000478e:	6ba2                	ld	s7,8(sp)
    80004790:	6c02                	ld	s8,0(sp)
    80004792:	6161                	add	sp,sp,80
    80004794:	8082                	ret
    panic("filewrite");
    80004796:	00004517          	auipc	a0,0x4
    8000479a:	f2250513          	add	a0,a0,-222 # 800086b8 <syscalls+0x268>
    8000479e:	ffffc097          	auipc	ra,0xffffc
    800047a2:	d9c080e7          	jalr	-612(ra) # 8000053a <panic>
    return -1;
    800047a6:	557d                	li	a0,-1
}
    800047a8:	8082                	ret
      return -1;
    800047aa:	557d                	li	a0,-1
    800047ac:	bfc9                	j	8000477e <filewrite+0xf8>
    800047ae:	557d                	li	a0,-1
    800047b0:	b7f9                	j	8000477e <filewrite+0xf8>
    ret = (i == n ? n : -1);
    800047b2:	557d                	li	a0,-1
    800047b4:	b7e9                	j	8000477e <filewrite+0xf8>

00000000800047b6 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800047b6:	7179                	add	sp,sp,-48
    800047b8:	f406                	sd	ra,40(sp)
    800047ba:	f022                	sd	s0,32(sp)
    800047bc:	ec26                	sd	s1,24(sp)
    800047be:	e84a                	sd	s2,16(sp)
    800047c0:	e44e                	sd	s3,8(sp)
    800047c2:	e052                	sd	s4,0(sp)
    800047c4:	1800                	add	s0,sp,48
    800047c6:	84aa                	mv	s1,a0
    800047c8:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800047ca:	0005b023          	sd	zero,0(a1)
    800047ce:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800047d2:	00000097          	auipc	ra,0x0
    800047d6:	bfc080e7          	jalr	-1028(ra) # 800043ce <filealloc>
    800047da:	e088                	sd	a0,0(s1)
    800047dc:	c551                	beqz	a0,80004868 <pipealloc+0xb2>
    800047de:	00000097          	auipc	ra,0x0
    800047e2:	bf0080e7          	jalr	-1040(ra) # 800043ce <filealloc>
    800047e6:	00aa3023          	sd	a0,0(s4)
    800047ea:	c92d                	beqz	a0,8000485c <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800047ec:	ffffc097          	auipc	ra,0xffffc
    800047f0:	2f4080e7          	jalr	756(ra) # 80000ae0 <kalloc>
    800047f4:	892a                	mv	s2,a0
    800047f6:	c125                	beqz	a0,80004856 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800047f8:	4985                	li	s3,1
    800047fa:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800047fe:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004802:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004806:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    8000480a:	00004597          	auipc	a1,0x4
    8000480e:	ebe58593          	add	a1,a1,-322 # 800086c8 <syscalls+0x278>
    80004812:	ffffc097          	auipc	ra,0xffffc
    80004816:	32e080e7          	jalr	814(ra) # 80000b40 <initlock>
  (*f0)->type = FD_PIPE;
    8000481a:	609c                	ld	a5,0(s1)
    8000481c:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004820:	609c                	ld	a5,0(s1)
    80004822:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004826:	609c                	ld	a5,0(s1)
    80004828:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    8000482c:	609c                	ld	a5,0(s1)
    8000482e:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004832:	000a3783          	ld	a5,0(s4)
    80004836:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    8000483a:	000a3783          	ld	a5,0(s4)
    8000483e:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004842:	000a3783          	ld	a5,0(s4)
    80004846:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    8000484a:	000a3783          	ld	a5,0(s4)
    8000484e:	0127b823          	sd	s2,16(a5)
  return 0;
    80004852:	4501                	li	a0,0
    80004854:	a025                	j	8000487c <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004856:	6088                	ld	a0,0(s1)
    80004858:	e501                	bnez	a0,80004860 <pipealloc+0xaa>
    8000485a:	a039                	j	80004868 <pipealloc+0xb2>
    8000485c:	6088                	ld	a0,0(s1)
    8000485e:	c51d                	beqz	a0,8000488c <pipealloc+0xd6>
    fileclose(*f0);
    80004860:	00000097          	auipc	ra,0x0
    80004864:	c2a080e7          	jalr	-982(ra) # 8000448a <fileclose>
  if(*f1)
    80004868:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    8000486c:	557d                	li	a0,-1
  if(*f1)
    8000486e:	c799                	beqz	a5,8000487c <pipealloc+0xc6>
    fileclose(*f1);
    80004870:	853e                	mv	a0,a5
    80004872:	00000097          	auipc	ra,0x0
    80004876:	c18080e7          	jalr	-1000(ra) # 8000448a <fileclose>
  return -1;
    8000487a:	557d                	li	a0,-1
}
    8000487c:	70a2                	ld	ra,40(sp)
    8000487e:	7402                	ld	s0,32(sp)
    80004880:	64e2                	ld	s1,24(sp)
    80004882:	6942                	ld	s2,16(sp)
    80004884:	69a2                	ld	s3,8(sp)
    80004886:	6a02                	ld	s4,0(sp)
    80004888:	6145                	add	sp,sp,48
    8000488a:	8082                	ret
  return -1;
    8000488c:	557d                	li	a0,-1
    8000488e:	b7fd                	j	8000487c <pipealloc+0xc6>

0000000080004890 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004890:	1101                	add	sp,sp,-32
    80004892:	ec06                	sd	ra,24(sp)
    80004894:	e822                	sd	s0,16(sp)
    80004896:	e426                	sd	s1,8(sp)
    80004898:	e04a                	sd	s2,0(sp)
    8000489a:	1000                	add	s0,sp,32
    8000489c:	84aa                	mv	s1,a0
    8000489e:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800048a0:	ffffc097          	auipc	ra,0xffffc
    800048a4:	330080e7          	jalr	816(ra) # 80000bd0 <acquire>
  if(writable){
    800048a8:	02090d63          	beqz	s2,800048e2 <pipeclose+0x52>
    pi->writeopen = 0;
    800048ac:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800048b0:	21848513          	add	a0,s1,536
    800048b4:	ffffd097          	auipc	ra,0xffffd
    800048b8:	7fc080e7          	jalr	2044(ra) # 800020b0 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800048bc:	2204b783          	ld	a5,544(s1)
    800048c0:	eb95                	bnez	a5,800048f4 <pipeclose+0x64>
    release(&pi->lock);
    800048c2:	8526                	mv	a0,s1
    800048c4:	ffffc097          	auipc	ra,0xffffc
    800048c8:	3c0080e7          	jalr	960(ra) # 80000c84 <release>
    kfree((char*)pi);
    800048cc:	8526                	mv	a0,s1
    800048ce:	ffffc097          	auipc	ra,0xffffc
    800048d2:	114080e7          	jalr	276(ra) # 800009e2 <kfree>
  } else
    release(&pi->lock);
}
    800048d6:	60e2                	ld	ra,24(sp)
    800048d8:	6442                	ld	s0,16(sp)
    800048da:	64a2                	ld	s1,8(sp)
    800048dc:	6902                	ld	s2,0(sp)
    800048de:	6105                	add	sp,sp,32
    800048e0:	8082                	ret
    pi->readopen = 0;
    800048e2:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800048e6:	21c48513          	add	a0,s1,540
    800048ea:	ffffd097          	auipc	ra,0xffffd
    800048ee:	7c6080e7          	jalr	1990(ra) # 800020b0 <wakeup>
    800048f2:	b7e9                	j	800048bc <pipeclose+0x2c>
    release(&pi->lock);
    800048f4:	8526                	mv	a0,s1
    800048f6:	ffffc097          	auipc	ra,0xffffc
    800048fa:	38e080e7          	jalr	910(ra) # 80000c84 <release>
}
    800048fe:	bfe1                	j	800048d6 <pipeclose+0x46>

0000000080004900 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004900:	711d                	add	sp,sp,-96
    80004902:	ec86                	sd	ra,88(sp)
    80004904:	e8a2                	sd	s0,80(sp)
    80004906:	e4a6                	sd	s1,72(sp)
    80004908:	e0ca                	sd	s2,64(sp)
    8000490a:	fc4e                	sd	s3,56(sp)
    8000490c:	f852                	sd	s4,48(sp)
    8000490e:	f456                	sd	s5,40(sp)
    80004910:	f05a                	sd	s6,32(sp)
    80004912:	ec5e                	sd	s7,24(sp)
    80004914:	e862                	sd	s8,16(sp)
    80004916:	1080                	add	s0,sp,96
    80004918:	84aa                	mv	s1,a0
    8000491a:	8aae                	mv	s5,a1
    8000491c:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    8000491e:	ffffd097          	auipc	ra,0xffffd
    80004922:	086080e7          	jalr	134(ra) # 800019a4 <myproc>
    80004926:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004928:	8526                	mv	a0,s1
    8000492a:	ffffc097          	auipc	ra,0xffffc
    8000492e:	2a6080e7          	jalr	678(ra) # 80000bd0 <acquire>
  while(i < n){
    80004932:	0b405663          	blez	s4,800049de <pipewrite+0xde>
  int i = 0;
    80004936:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004938:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    8000493a:	21848c13          	add	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    8000493e:	21c48b93          	add	s7,s1,540
    80004942:	a089                	j	80004984 <pipewrite+0x84>
      release(&pi->lock);
    80004944:	8526                	mv	a0,s1
    80004946:	ffffc097          	auipc	ra,0xffffc
    8000494a:	33e080e7          	jalr	830(ra) # 80000c84 <release>
      return -1;
    8000494e:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004950:	854a                	mv	a0,s2
    80004952:	60e6                	ld	ra,88(sp)
    80004954:	6446                	ld	s0,80(sp)
    80004956:	64a6                	ld	s1,72(sp)
    80004958:	6906                	ld	s2,64(sp)
    8000495a:	79e2                	ld	s3,56(sp)
    8000495c:	7a42                	ld	s4,48(sp)
    8000495e:	7aa2                	ld	s5,40(sp)
    80004960:	7b02                	ld	s6,32(sp)
    80004962:	6be2                	ld	s7,24(sp)
    80004964:	6c42                	ld	s8,16(sp)
    80004966:	6125                	add	sp,sp,96
    80004968:	8082                	ret
      wakeup(&pi->nread);
    8000496a:	8562                	mv	a0,s8
    8000496c:	ffffd097          	auipc	ra,0xffffd
    80004970:	744080e7          	jalr	1860(ra) # 800020b0 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004974:	85a6                	mv	a1,s1
    80004976:	855e                	mv	a0,s7
    80004978:	ffffd097          	auipc	ra,0xffffd
    8000497c:	6d4080e7          	jalr	1748(ra) # 8000204c <sleep>
  while(i < n){
    80004980:	07495063          	bge	s2,s4,800049e0 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004984:	2204a783          	lw	a5,544(s1)
    80004988:	dfd5                	beqz	a5,80004944 <pipewrite+0x44>
    8000498a:	854e                	mv	a0,s3
    8000498c:	ffffe097          	auipc	ra,0xffffe
    80004990:	968080e7          	jalr	-1688(ra) # 800022f4 <killed>
    80004994:	f945                	bnez	a0,80004944 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004996:	2184a783          	lw	a5,536(s1)
    8000499a:	21c4a703          	lw	a4,540(s1)
    8000499e:	2007879b          	addw	a5,a5,512
    800049a2:	fcf704e3          	beq	a4,a5,8000496a <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800049a6:	4685                	li	a3,1
    800049a8:	01590633          	add	a2,s2,s5
    800049ac:	faf40593          	add	a1,s0,-81
    800049b0:	0509b503          	ld	a0,80(s3)
    800049b4:	ffffd097          	auipc	ra,0xffffd
    800049b8:	d3c080e7          	jalr	-708(ra) # 800016f0 <copyin>
    800049bc:	03650263          	beq	a0,s6,800049e0 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800049c0:	21c4a783          	lw	a5,540(s1)
    800049c4:	0017871b          	addw	a4,a5,1
    800049c8:	20e4ae23          	sw	a4,540(s1)
    800049cc:	1ff7f793          	and	a5,a5,511
    800049d0:	97a6                	add	a5,a5,s1
    800049d2:	faf44703          	lbu	a4,-81(s0)
    800049d6:	00e78c23          	sb	a4,24(a5)
      i++;
    800049da:	2905                	addw	s2,s2,1
    800049dc:	b755                	j	80004980 <pipewrite+0x80>
  int i = 0;
    800049de:	4901                	li	s2,0
  wakeup(&pi->nread);
    800049e0:	21848513          	add	a0,s1,536
    800049e4:	ffffd097          	auipc	ra,0xffffd
    800049e8:	6cc080e7          	jalr	1740(ra) # 800020b0 <wakeup>
  release(&pi->lock);
    800049ec:	8526                	mv	a0,s1
    800049ee:	ffffc097          	auipc	ra,0xffffc
    800049f2:	296080e7          	jalr	662(ra) # 80000c84 <release>
  return i;
    800049f6:	bfa9                	j	80004950 <pipewrite+0x50>

00000000800049f8 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800049f8:	715d                	add	sp,sp,-80
    800049fa:	e486                	sd	ra,72(sp)
    800049fc:	e0a2                	sd	s0,64(sp)
    800049fe:	fc26                	sd	s1,56(sp)
    80004a00:	f84a                	sd	s2,48(sp)
    80004a02:	f44e                	sd	s3,40(sp)
    80004a04:	f052                	sd	s4,32(sp)
    80004a06:	ec56                	sd	s5,24(sp)
    80004a08:	e85a                	sd	s6,16(sp)
    80004a0a:	0880                	add	s0,sp,80
    80004a0c:	84aa                	mv	s1,a0
    80004a0e:	892e                	mv	s2,a1
    80004a10:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004a12:	ffffd097          	auipc	ra,0xffffd
    80004a16:	f92080e7          	jalr	-110(ra) # 800019a4 <myproc>
    80004a1a:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004a1c:	8526                	mv	a0,s1
    80004a1e:	ffffc097          	auipc	ra,0xffffc
    80004a22:	1b2080e7          	jalr	434(ra) # 80000bd0 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004a26:	2184a703          	lw	a4,536(s1)
    80004a2a:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004a2e:	21848993          	add	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004a32:	02f71763          	bne	a4,a5,80004a60 <piperead+0x68>
    80004a36:	2244a783          	lw	a5,548(s1)
    80004a3a:	c39d                	beqz	a5,80004a60 <piperead+0x68>
    if(killed(pr)){
    80004a3c:	8552                	mv	a0,s4
    80004a3e:	ffffe097          	auipc	ra,0xffffe
    80004a42:	8b6080e7          	jalr	-1866(ra) # 800022f4 <killed>
    80004a46:	e949                	bnez	a0,80004ad8 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004a48:	85a6                	mv	a1,s1
    80004a4a:	854e                	mv	a0,s3
    80004a4c:	ffffd097          	auipc	ra,0xffffd
    80004a50:	600080e7          	jalr	1536(ra) # 8000204c <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004a54:	2184a703          	lw	a4,536(s1)
    80004a58:	21c4a783          	lw	a5,540(s1)
    80004a5c:	fcf70de3          	beq	a4,a5,80004a36 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004a60:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004a62:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004a64:	05505463          	blez	s5,80004aac <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80004a68:	2184a783          	lw	a5,536(s1)
    80004a6c:	21c4a703          	lw	a4,540(s1)
    80004a70:	02f70e63          	beq	a4,a5,80004aac <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004a74:	0017871b          	addw	a4,a5,1
    80004a78:	20e4ac23          	sw	a4,536(s1)
    80004a7c:	1ff7f793          	and	a5,a5,511
    80004a80:	97a6                	add	a5,a5,s1
    80004a82:	0187c783          	lbu	a5,24(a5)
    80004a86:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004a8a:	4685                	li	a3,1
    80004a8c:	fbf40613          	add	a2,s0,-65
    80004a90:	85ca                	mv	a1,s2
    80004a92:	050a3503          	ld	a0,80(s4)
    80004a96:	ffffd097          	auipc	ra,0xffffd
    80004a9a:	bce080e7          	jalr	-1074(ra) # 80001664 <copyout>
    80004a9e:	01650763          	beq	a0,s6,80004aac <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004aa2:	2985                	addw	s3,s3,1
    80004aa4:	0905                	add	s2,s2,1
    80004aa6:	fd3a91e3          	bne	s5,s3,80004a68 <piperead+0x70>
    80004aaa:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004aac:	21c48513          	add	a0,s1,540
    80004ab0:	ffffd097          	auipc	ra,0xffffd
    80004ab4:	600080e7          	jalr	1536(ra) # 800020b0 <wakeup>
  release(&pi->lock);
    80004ab8:	8526                	mv	a0,s1
    80004aba:	ffffc097          	auipc	ra,0xffffc
    80004abe:	1ca080e7          	jalr	458(ra) # 80000c84 <release>
  return i;
}
    80004ac2:	854e                	mv	a0,s3
    80004ac4:	60a6                	ld	ra,72(sp)
    80004ac6:	6406                	ld	s0,64(sp)
    80004ac8:	74e2                	ld	s1,56(sp)
    80004aca:	7942                	ld	s2,48(sp)
    80004acc:	79a2                	ld	s3,40(sp)
    80004ace:	7a02                	ld	s4,32(sp)
    80004ad0:	6ae2                	ld	s5,24(sp)
    80004ad2:	6b42                	ld	s6,16(sp)
    80004ad4:	6161                	add	sp,sp,80
    80004ad6:	8082                	ret
      release(&pi->lock);
    80004ad8:	8526                	mv	a0,s1
    80004ada:	ffffc097          	auipc	ra,0xffffc
    80004ade:	1aa080e7          	jalr	426(ra) # 80000c84 <release>
      return -1;
    80004ae2:	59fd                	li	s3,-1
    80004ae4:	bff9                	j	80004ac2 <piperead+0xca>

0000000080004ae6 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004ae6:	1141                	add	sp,sp,-16
    80004ae8:	e422                	sd	s0,8(sp)
    80004aea:	0800                	add	s0,sp,16
    80004aec:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004aee:	8905                	and	a0,a0,1
    80004af0:	050e                	sll	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80004af2:	8b89                	and	a5,a5,2
    80004af4:	c399                	beqz	a5,80004afa <flags2perm+0x14>
      perm |= PTE_W;
    80004af6:	00456513          	or	a0,a0,4
    return perm;
}
    80004afa:	6422                	ld	s0,8(sp)
    80004afc:	0141                	add	sp,sp,16
    80004afe:	8082                	ret

0000000080004b00 <exec>:

int
exec(char *path, char **argv)
{
    80004b00:	df010113          	add	sp,sp,-528
    80004b04:	20113423          	sd	ra,520(sp)
    80004b08:	20813023          	sd	s0,512(sp)
    80004b0c:	ffa6                	sd	s1,504(sp)
    80004b0e:	fbca                	sd	s2,496(sp)
    80004b10:	f7ce                	sd	s3,488(sp)
    80004b12:	f3d2                	sd	s4,480(sp)
    80004b14:	efd6                	sd	s5,472(sp)
    80004b16:	ebda                	sd	s6,464(sp)
    80004b18:	e7de                	sd	s7,456(sp)
    80004b1a:	e3e2                	sd	s8,448(sp)
    80004b1c:	ff66                	sd	s9,440(sp)
    80004b1e:	fb6a                	sd	s10,432(sp)
    80004b20:	f76e                	sd	s11,424(sp)
    80004b22:	0c00                	add	s0,sp,528
    80004b24:	892a                	mv	s2,a0
    80004b26:	dea43c23          	sd	a0,-520(s0)
    80004b2a:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004b2e:	ffffd097          	auipc	ra,0xffffd
    80004b32:	e76080e7          	jalr	-394(ra) # 800019a4 <myproc>
    80004b36:	84aa                	mv	s1,a0

  begin_op();
    80004b38:	fffff097          	auipc	ra,0xfffff
    80004b3c:	48e080e7          	jalr	1166(ra) # 80003fc6 <begin_op>

  if((ip = namei(path)) == 0){
    80004b40:	854a                	mv	a0,s2
    80004b42:	fffff097          	auipc	ra,0xfffff
    80004b46:	284080e7          	jalr	644(ra) # 80003dc6 <namei>
    80004b4a:	c92d                	beqz	a0,80004bbc <exec+0xbc>
    80004b4c:	8a2a                	mv	s4,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004b4e:	fffff097          	auipc	ra,0xfffff
    80004b52:	ad2080e7          	jalr	-1326(ra) # 80003620 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004b56:	04000713          	li	a4,64
    80004b5a:	4681                	li	a3,0
    80004b5c:	e5040613          	add	a2,s0,-432
    80004b60:	4581                	li	a1,0
    80004b62:	8552                	mv	a0,s4
    80004b64:	fffff097          	auipc	ra,0xfffff
    80004b68:	d70080e7          	jalr	-656(ra) # 800038d4 <readi>
    80004b6c:	04000793          	li	a5,64
    80004b70:	00f51a63          	bne	a0,a5,80004b84 <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004b74:	e5042703          	lw	a4,-432(s0)
    80004b78:	464c47b7          	lui	a5,0x464c4
    80004b7c:	57f78793          	add	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004b80:	04f70463          	beq	a4,a5,80004bc8 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004b84:	8552                	mv	a0,s4
    80004b86:	fffff097          	auipc	ra,0xfffff
    80004b8a:	cfc080e7          	jalr	-772(ra) # 80003882 <iunlockput>
    end_op();
    80004b8e:	fffff097          	auipc	ra,0xfffff
    80004b92:	4b2080e7          	jalr	1202(ra) # 80004040 <end_op>
  }
  return -1;
    80004b96:	557d                	li	a0,-1
}
    80004b98:	20813083          	ld	ra,520(sp)
    80004b9c:	20013403          	ld	s0,512(sp)
    80004ba0:	74fe                	ld	s1,504(sp)
    80004ba2:	795e                	ld	s2,496(sp)
    80004ba4:	79be                	ld	s3,488(sp)
    80004ba6:	7a1e                	ld	s4,480(sp)
    80004ba8:	6afe                	ld	s5,472(sp)
    80004baa:	6b5e                	ld	s6,464(sp)
    80004bac:	6bbe                	ld	s7,456(sp)
    80004bae:	6c1e                	ld	s8,448(sp)
    80004bb0:	7cfa                	ld	s9,440(sp)
    80004bb2:	7d5a                	ld	s10,432(sp)
    80004bb4:	7dba                	ld	s11,424(sp)
    80004bb6:	21010113          	add	sp,sp,528
    80004bba:	8082                	ret
    end_op();
    80004bbc:	fffff097          	auipc	ra,0xfffff
    80004bc0:	484080e7          	jalr	1156(ra) # 80004040 <end_op>
    return -1;
    80004bc4:	557d                	li	a0,-1
    80004bc6:	bfc9                	j	80004b98 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004bc8:	8526                	mv	a0,s1
    80004bca:	ffffd097          	auipc	ra,0xffffd
    80004bce:	e9e080e7          	jalr	-354(ra) # 80001a68 <proc_pagetable>
    80004bd2:	8b2a                	mv	s6,a0
    80004bd4:	d945                	beqz	a0,80004b84 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004bd6:	e7042d03          	lw	s10,-400(s0)
    80004bda:	e8845783          	lhu	a5,-376(s0)
    80004bde:	10078463          	beqz	a5,80004ce6 <exec+0x1e6>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004be2:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004be4:	4d81                	li	s11,0
    if(ph.vaddr % PGSIZE != 0)
    80004be6:	6c85                	lui	s9,0x1
    80004be8:	fffc8793          	add	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004bec:	def43823          	sd	a5,-528(s0)

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    if(sz - i < PGSIZE)
    80004bf0:	6a85                	lui	s5,0x1
    80004bf2:	a0b5                	j	80004c5e <exec+0x15e>
      panic("loadseg: address should exist");
    80004bf4:	00004517          	auipc	a0,0x4
    80004bf8:	adc50513          	add	a0,a0,-1316 # 800086d0 <syscalls+0x280>
    80004bfc:	ffffc097          	auipc	ra,0xffffc
    80004c00:	93e080e7          	jalr	-1730(ra) # 8000053a <panic>
    if(sz - i < PGSIZE)
    80004c04:	2481                	sext.w	s1,s1
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004c06:	8726                	mv	a4,s1
    80004c08:	012c06bb          	addw	a3,s8,s2
    80004c0c:	4581                	li	a1,0
    80004c0e:	8552                	mv	a0,s4
    80004c10:	fffff097          	auipc	ra,0xfffff
    80004c14:	cc4080e7          	jalr	-828(ra) # 800038d4 <readi>
    80004c18:	2501                	sext.w	a0,a0
    80004c1a:	24a49863          	bne	s1,a0,80004e6a <exec+0x36a>
  for(i = 0; i < sz; i += PGSIZE){
    80004c1e:	012a893b          	addw	s2,s5,s2
    80004c22:	03397563          	bgeu	s2,s3,80004c4c <exec+0x14c>
    pa = walkaddr(pagetable, va + i);
    80004c26:	02091593          	sll	a1,s2,0x20
    80004c2a:	9181                	srl	a1,a1,0x20
    80004c2c:	95de                	add	a1,a1,s7
    80004c2e:	855a                	mv	a0,s6
    80004c30:	ffffc097          	auipc	ra,0xffffc
    80004c34:	424080e7          	jalr	1060(ra) # 80001054 <walkaddr>
    80004c38:	862a                	mv	a2,a0
    if(pa == 0)
    80004c3a:	dd4d                	beqz	a0,80004bf4 <exec+0xf4>
    if(sz - i < PGSIZE)
    80004c3c:	412984bb          	subw	s1,s3,s2
    80004c40:	0004879b          	sext.w	a5,s1
    80004c44:	fcfcf0e3          	bgeu	s9,a5,80004c04 <exec+0x104>
    80004c48:	84d6                	mv	s1,s5
    80004c4a:	bf6d                	j	80004c04 <exec+0x104>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004c4c:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004c50:	2d85                	addw	s11,s11,1
    80004c52:	038d0d1b          	addw	s10,s10,56
    80004c56:	e8845783          	lhu	a5,-376(s0)
    80004c5a:	08fdd763          	bge	s11,a5,80004ce8 <exec+0x1e8>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004c5e:	2d01                	sext.w	s10,s10
    80004c60:	03800713          	li	a4,56
    80004c64:	86ea                	mv	a3,s10
    80004c66:	e1840613          	add	a2,s0,-488
    80004c6a:	4581                	li	a1,0
    80004c6c:	8552                	mv	a0,s4
    80004c6e:	fffff097          	auipc	ra,0xfffff
    80004c72:	c66080e7          	jalr	-922(ra) # 800038d4 <readi>
    80004c76:	03800793          	li	a5,56
    80004c7a:	1ef51663          	bne	a0,a5,80004e66 <exec+0x366>
    if(ph.type != ELF_PROG_LOAD)
    80004c7e:	e1842783          	lw	a5,-488(s0)
    80004c82:	4705                	li	a4,1
    80004c84:	fce796e3          	bne	a5,a4,80004c50 <exec+0x150>
    if(ph.memsz < ph.filesz)
    80004c88:	e4043483          	ld	s1,-448(s0)
    80004c8c:	e3843783          	ld	a5,-456(s0)
    80004c90:	1ef4e863          	bltu	s1,a5,80004e80 <exec+0x380>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004c94:	e2843783          	ld	a5,-472(s0)
    80004c98:	94be                	add	s1,s1,a5
    80004c9a:	1ef4e663          	bltu	s1,a5,80004e86 <exec+0x386>
    if(ph.vaddr % PGSIZE != 0)
    80004c9e:	df043703          	ld	a4,-528(s0)
    80004ca2:	8ff9                	and	a5,a5,a4
    80004ca4:	1e079463          	bnez	a5,80004e8c <exec+0x38c>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004ca8:	e1c42503          	lw	a0,-484(s0)
    80004cac:	00000097          	auipc	ra,0x0
    80004cb0:	e3a080e7          	jalr	-454(ra) # 80004ae6 <flags2perm>
    80004cb4:	86aa                	mv	a3,a0
    80004cb6:	8626                	mv	a2,s1
    80004cb8:	85ca                	mv	a1,s2
    80004cba:	855a                	mv	a0,s6
    80004cbc:	ffffc097          	auipc	ra,0xffffc
    80004cc0:	74c080e7          	jalr	1868(ra) # 80001408 <uvmalloc>
    80004cc4:	e0a43423          	sd	a0,-504(s0)
    80004cc8:	1c050563          	beqz	a0,80004e92 <exec+0x392>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004ccc:	e2843b83          	ld	s7,-472(s0)
    80004cd0:	e2042c03          	lw	s8,-480(s0)
    80004cd4:	e3842983          	lw	s3,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004cd8:	00098463          	beqz	s3,80004ce0 <exec+0x1e0>
    80004cdc:	4901                	li	s2,0
    80004cde:	b7a1                	j	80004c26 <exec+0x126>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004ce0:	e0843903          	ld	s2,-504(s0)
    80004ce4:	b7b5                	j	80004c50 <exec+0x150>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004ce6:	4901                	li	s2,0
  iunlockput(ip);
    80004ce8:	8552                	mv	a0,s4
    80004cea:	fffff097          	auipc	ra,0xfffff
    80004cee:	b98080e7          	jalr	-1128(ra) # 80003882 <iunlockput>
  end_op();
    80004cf2:	fffff097          	auipc	ra,0xfffff
    80004cf6:	34e080e7          	jalr	846(ra) # 80004040 <end_op>
  p = myproc();
    80004cfa:	ffffd097          	auipc	ra,0xffffd
    80004cfe:	caa080e7          	jalr	-854(ra) # 800019a4 <myproc>
    80004d02:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004d04:	04853c83          	ld	s9,72(a0)
  sz = PGROUNDUP(sz);
    80004d08:	6985                	lui	s3,0x1
    80004d0a:	19fd                	add	s3,s3,-1 # fff <_entry-0x7ffff001>
    80004d0c:	99ca                	add	s3,s3,s2
    80004d0e:	77fd                	lui	a5,0xfffff
    80004d10:	00f9f9b3          	and	s3,s3,a5
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004d14:	4691                	li	a3,4
    80004d16:	6609                	lui	a2,0x2
    80004d18:	964e                	add	a2,a2,s3
    80004d1a:	85ce                	mv	a1,s3
    80004d1c:	855a                	mv	a0,s6
    80004d1e:	ffffc097          	auipc	ra,0xffffc
    80004d22:	6ea080e7          	jalr	1770(ra) # 80001408 <uvmalloc>
    80004d26:	892a                	mv	s2,a0
    80004d28:	e0a43423          	sd	a0,-504(s0)
    80004d2c:	e509                	bnez	a0,80004d36 <exec+0x236>
  if(pagetable)
    80004d2e:	e1343423          	sd	s3,-504(s0)
    80004d32:	4a01                	li	s4,0
    80004d34:	aa1d                	j	80004e6a <exec+0x36a>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004d36:	75f9                	lui	a1,0xffffe
    80004d38:	95aa                	add	a1,a1,a0
    80004d3a:	855a                	mv	a0,s6
    80004d3c:	ffffd097          	auipc	ra,0xffffd
    80004d40:	8f6080e7          	jalr	-1802(ra) # 80001632 <uvmclear>
  stackbase = sp - PGSIZE;
    80004d44:	7bfd                	lui	s7,0xfffff
    80004d46:	9bca                	add	s7,s7,s2
  for(argc = 0; argv[argc]; argc++) {
    80004d48:	e0043783          	ld	a5,-512(s0)
    80004d4c:	6388                	ld	a0,0(a5)
    80004d4e:	c52d                	beqz	a0,80004db8 <exec+0x2b8>
    80004d50:	e9040993          	add	s3,s0,-368
    80004d54:	f9040c13          	add	s8,s0,-112
    80004d58:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004d5a:	ffffc097          	auipc	ra,0xffffc
    80004d5e:	0ec080e7          	jalr	236(ra) # 80000e46 <strlen>
    80004d62:	0015079b          	addw	a5,a0,1
    80004d66:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004d6a:	ff07f913          	and	s2,a5,-16
    if(sp < stackbase)
    80004d6e:	13796563          	bltu	s2,s7,80004e98 <exec+0x398>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004d72:	e0043d03          	ld	s10,-512(s0)
    80004d76:	000d3a03          	ld	s4,0(s10)
    80004d7a:	8552                	mv	a0,s4
    80004d7c:	ffffc097          	auipc	ra,0xffffc
    80004d80:	0ca080e7          	jalr	202(ra) # 80000e46 <strlen>
    80004d84:	0015069b          	addw	a3,a0,1
    80004d88:	8652                	mv	a2,s4
    80004d8a:	85ca                	mv	a1,s2
    80004d8c:	855a                	mv	a0,s6
    80004d8e:	ffffd097          	auipc	ra,0xffffd
    80004d92:	8d6080e7          	jalr	-1834(ra) # 80001664 <copyout>
    80004d96:	10054363          	bltz	a0,80004e9c <exec+0x39c>
    ustack[argc] = sp;
    80004d9a:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004d9e:	0485                	add	s1,s1,1
    80004da0:	008d0793          	add	a5,s10,8
    80004da4:	e0f43023          	sd	a5,-512(s0)
    80004da8:	008d3503          	ld	a0,8(s10)
    80004dac:	c909                	beqz	a0,80004dbe <exec+0x2be>
    if(argc >= MAXARG)
    80004dae:	09a1                	add	s3,s3,8
    80004db0:	fb8995e3          	bne	s3,s8,80004d5a <exec+0x25a>
  ip = 0;
    80004db4:	4a01                	li	s4,0
    80004db6:	a855                	j	80004e6a <exec+0x36a>
  sp = sz;
    80004db8:	e0843903          	ld	s2,-504(s0)
  for(argc = 0; argv[argc]; argc++) {
    80004dbc:	4481                	li	s1,0
  ustack[argc] = 0;
    80004dbe:	00349793          	sll	a5,s1,0x3
    80004dc2:	f9078793          	add	a5,a5,-112 # ffffffffffffef90 <end+0xffffffff7ffdd250>
    80004dc6:	97a2                	add	a5,a5,s0
    80004dc8:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80004dcc:	00148693          	add	a3,s1,1
    80004dd0:	068e                	sll	a3,a3,0x3
    80004dd2:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004dd6:	ff097913          	and	s2,s2,-16
  sz = sz1;
    80004dda:	e0843983          	ld	s3,-504(s0)
  if(sp < stackbase)
    80004dde:	f57968e3          	bltu	s2,s7,80004d2e <exec+0x22e>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004de2:	e9040613          	add	a2,s0,-368
    80004de6:	85ca                	mv	a1,s2
    80004de8:	855a                	mv	a0,s6
    80004dea:	ffffd097          	auipc	ra,0xffffd
    80004dee:	87a080e7          	jalr	-1926(ra) # 80001664 <copyout>
    80004df2:	0a054763          	bltz	a0,80004ea0 <exec+0x3a0>
  p->trapframe->a1 = sp;
    80004df6:	058ab783          	ld	a5,88(s5) # 1058 <_entry-0x7fffefa8>
    80004dfa:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004dfe:	df843783          	ld	a5,-520(s0)
    80004e02:	0007c703          	lbu	a4,0(a5)
    80004e06:	cf11                	beqz	a4,80004e22 <exec+0x322>
    80004e08:	0785                	add	a5,a5,1
    if(*s == '/')
    80004e0a:	02f00693          	li	a3,47
    80004e0e:	a039                	j	80004e1c <exec+0x31c>
      last = s+1;
    80004e10:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80004e14:	0785                	add	a5,a5,1
    80004e16:	fff7c703          	lbu	a4,-1(a5)
    80004e1a:	c701                	beqz	a4,80004e22 <exec+0x322>
    if(*s == '/')
    80004e1c:	fed71ce3          	bne	a4,a3,80004e14 <exec+0x314>
    80004e20:	bfc5                	j	80004e10 <exec+0x310>
  safestrcpy(p->name, last, sizeof(p->name));
    80004e22:	4641                	li	a2,16
    80004e24:	df843583          	ld	a1,-520(s0)
    80004e28:	158a8513          	add	a0,s5,344
    80004e2c:	ffffc097          	auipc	ra,0xffffc
    80004e30:	fe8080e7          	jalr	-24(ra) # 80000e14 <safestrcpy>
  oldpagetable = p->pagetable;
    80004e34:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004e38:	056ab823          	sd	s6,80(s5)
  p->sz = sz;
    80004e3c:	e0843783          	ld	a5,-504(s0)
    80004e40:	04fab423          	sd	a5,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004e44:	058ab783          	ld	a5,88(s5)
    80004e48:	e6843703          	ld	a4,-408(s0)
    80004e4c:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004e4e:	058ab783          	ld	a5,88(s5)
    80004e52:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004e56:	85e6                	mv	a1,s9
    80004e58:	ffffd097          	auipc	ra,0xffffd
    80004e5c:	cac080e7          	jalr	-852(ra) # 80001b04 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004e60:	0004851b          	sext.w	a0,s1
    80004e64:	bb15                	j	80004b98 <exec+0x98>
    80004e66:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004e6a:	e0843583          	ld	a1,-504(s0)
    80004e6e:	855a                	mv	a0,s6
    80004e70:	ffffd097          	auipc	ra,0xffffd
    80004e74:	c94080e7          	jalr	-876(ra) # 80001b04 <proc_freepagetable>
  return -1;
    80004e78:	557d                	li	a0,-1
  if(ip){
    80004e7a:	d00a0fe3          	beqz	s4,80004b98 <exec+0x98>
    80004e7e:	b319                	j	80004b84 <exec+0x84>
    80004e80:	e1243423          	sd	s2,-504(s0)
    80004e84:	b7dd                	j	80004e6a <exec+0x36a>
    80004e86:	e1243423          	sd	s2,-504(s0)
    80004e8a:	b7c5                	j	80004e6a <exec+0x36a>
    80004e8c:	e1243423          	sd	s2,-504(s0)
    80004e90:	bfe9                	j	80004e6a <exec+0x36a>
    80004e92:	e1243423          	sd	s2,-504(s0)
    80004e96:	bfd1                	j	80004e6a <exec+0x36a>
  ip = 0;
    80004e98:	4a01                	li	s4,0
    80004e9a:	bfc1                	j	80004e6a <exec+0x36a>
    80004e9c:	4a01                	li	s4,0
  if(pagetable)
    80004e9e:	b7f1                	j	80004e6a <exec+0x36a>
  sz = sz1;
    80004ea0:	e0843983          	ld	s3,-504(s0)
    80004ea4:	b569                	j	80004d2e <exec+0x22e>

0000000080004ea6 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004ea6:	7179                	add	sp,sp,-48
    80004ea8:	f406                	sd	ra,40(sp)
    80004eaa:	f022                	sd	s0,32(sp)
    80004eac:	ec26                	sd	s1,24(sp)
    80004eae:	e84a                	sd	s2,16(sp)
    80004eb0:	1800                	add	s0,sp,48
    80004eb2:	892e                	mv	s2,a1
    80004eb4:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80004eb6:	fdc40593          	add	a1,s0,-36
    80004eba:	ffffe097          	auipc	ra,0xffffe
    80004ebe:	c04080e7          	jalr	-1020(ra) # 80002abe <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004ec2:	fdc42703          	lw	a4,-36(s0)
    80004ec6:	47bd                	li	a5,15
    80004ec8:	02e7eb63          	bltu	a5,a4,80004efe <argfd+0x58>
    80004ecc:	ffffd097          	auipc	ra,0xffffd
    80004ed0:	ad8080e7          	jalr	-1320(ra) # 800019a4 <myproc>
    80004ed4:	fdc42703          	lw	a4,-36(s0)
    80004ed8:	01a70793          	add	a5,a4,26
    80004edc:	078e                	sll	a5,a5,0x3
    80004ede:	953e                	add	a0,a0,a5
    80004ee0:	611c                	ld	a5,0(a0)
    80004ee2:	c385                	beqz	a5,80004f02 <argfd+0x5c>
    return -1;
  if(pfd)
    80004ee4:	00090463          	beqz	s2,80004eec <argfd+0x46>
    *pfd = fd;
    80004ee8:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80004eec:	4501                	li	a0,0
  if(pf)
    80004eee:	c091                	beqz	s1,80004ef2 <argfd+0x4c>
    *pf = f;
    80004ef0:	e09c                	sd	a5,0(s1)
}
    80004ef2:	70a2                	ld	ra,40(sp)
    80004ef4:	7402                	ld	s0,32(sp)
    80004ef6:	64e2                	ld	s1,24(sp)
    80004ef8:	6942                	ld	s2,16(sp)
    80004efa:	6145                	add	sp,sp,48
    80004efc:	8082                	ret
    return -1;
    80004efe:	557d                	li	a0,-1
    80004f00:	bfcd                	j	80004ef2 <argfd+0x4c>
    80004f02:	557d                	li	a0,-1
    80004f04:	b7fd                	j	80004ef2 <argfd+0x4c>

0000000080004f06 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80004f06:	1101                	add	sp,sp,-32
    80004f08:	ec06                	sd	ra,24(sp)
    80004f0a:	e822                	sd	s0,16(sp)
    80004f0c:	e426                	sd	s1,8(sp)
    80004f0e:	1000                	add	s0,sp,32
    80004f10:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80004f12:	ffffd097          	auipc	ra,0xffffd
    80004f16:	a92080e7          	jalr	-1390(ra) # 800019a4 <myproc>
    80004f1a:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80004f1c:	0d050793          	add	a5,a0,208
    80004f20:	4501                	li	a0,0
    80004f22:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80004f24:	6398                	ld	a4,0(a5)
    80004f26:	cb19                	beqz	a4,80004f3c <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80004f28:	2505                	addw	a0,a0,1
    80004f2a:	07a1                	add	a5,a5,8
    80004f2c:	fed51ce3          	bne	a0,a3,80004f24 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80004f30:	557d                	li	a0,-1
}
    80004f32:	60e2                	ld	ra,24(sp)
    80004f34:	6442                	ld	s0,16(sp)
    80004f36:	64a2                	ld	s1,8(sp)
    80004f38:	6105                	add	sp,sp,32
    80004f3a:	8082                	ret
      p->ofile[fd] = f;
    80004f3c:	01a50793          	add	a5,a0,26
    80004f40:	078e                	sll	a5,a5,0x3
    80004f42:	963e                	add	a2,a2,a5
    80004f44:	e204                	sd	s1,0(a2)
      return fd;
    80004f46:	b7f5                	j	80004f32 <fdalloc+0x2c>

0000000080004f48 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80004f48:	715d                	add	sp,sp,-80
    80004f4a:	e486                	sd	ra,72(sp)
    80004f4c:	e0a2                	sd	s0,64(sp)
    80004f4e:	fc26                	sd	s1,56(sp)
    80004f50:	f84a                	sd	s2,48(sp)
    80004f52:	f44e                	sd	s3,40(sp)
    80004f54:	f052                	sd	s4,32(sp)
    80004f56:	ec56                	sd	s5,24(sp)
    80004f58:	e85a                	sd	s6,16(sp)
    80004f5a:	0880                	add	s0,sp,80
    80004f5c:	8b2e                	mv	s6,a1
    80004f5e:	89b2                	mv	s3,a2
    80004f60:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80004f62:	fb040593          	add	a1,s0,-80
    80004f66:	fffff097          	auipc	ra,0xfffff
    80004f6a:	e7e080e7          	jalr	-386(ra) # 80003de4 <nameiparent>
    80004f6e:	84aa                	mv	s1,a0
    80004f70:	14050b63          	beqz	a0,800050c6 <create+0x17e>
    return 0;

  ilock(dp);
    80004f74:	ffffe097          	auipc	ra,0xffffe
    80004f78:	6ac080e7          	jalr	1708(ra) # 80003620 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80004f7c:	4601                	li	a2,0
    80004f7e:	fb040593          	add	a1,s0,-80
    80004f82:	8526                	mv	a0,s1
    80004f84:	fffff097          	auipc	ra,0xfffff
    80004f88:	b80080e7          	jalr	-1152(ra) # 80003b04 <dirlookup>
    80004f8c:	8aaa                	mv	s5,a0
    80004f8e:	c921                	beqz	a0,80004fde <create+0x96>
    iunlockput(dp);
    80004f90:	8526                	mv	a0,s1
    80004f92:	fffff097          	auipc	ra,0xfffff
    80004f96:	8f0080e7          	jalr	-1808(ra) # 80003882 <iunlockput>
    ilock(ip);
    80004f9a:	8556                	mv	a0,s5
    80004f9c:	ffffe097          	auipc	ra,0xffffe
    80004fa0:	684080e7          	jalr	1668(ra) # 80003620 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80004fa4:	4789                	li	a5,2
    80004fa6:	02fb1563          	bne	s6,a5,80004fd0 <create+0x88>
    80004faa:	044ad783          	lhu	a5,68(s5)
    80004fae:	37f9                	addw	a5,a5,-2
    80004fb0:	17c2                	sll	a5,a5,0x30
    80004fb2:	93c1                	srl	a5,a5,0x30
    80004fb4:	4705                	li	a4,1
    80004fb6:	00f76d63          	bltu	a4,a5,80004fd0 <create+0x88>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80004fba:	8556                	mv	a0,s5
    80004fbc:	60a6                	ld	ra,72(sp)
    80004fbe:	6406                	ld	s0,64(sp)
    80004fc0:	74e2                	ld	s1,56(sp)
    80004fc2:	7942                	ld	s2,48(sp)
    80004fc4:	79a2                	ld	s3,40(sp)
    80004fc6:	7a02                	ld	s4,32(sp)
    80004fc8:	6ae2                	ld	s5,24(sp)
    80004fca:	6b42                	ld	s6,16(sp)
    80004fcc:	6161                	add	sp,sp,80
    80004fce:	8082                	ret
    iunlockput(ip);
    80004fd0:	8556                	mv	a0,s5
    80004fd2:	fffff097          	auipc	ra,0xfffff
    80004fd6:	8b0080e7          	jalr	-1872(ra) # 80003882 <iunlockput>
    return 0;
    80004fda:	4a81                	li	s5,0
    80004fdc:	bff9                	j	80004fba <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0){
    80004fde:	85da                	mv	a1,s6
    80004fe0:	4088                	lw	a0,0(s1)
    80004fe2:	ffffe097          	auipc	ra,0xffffe
    80004fe6:	4a6080e7          	jalr	1190(ra) # 80003488 <ialloc>
    80004fea:	8a2a                	mv	s4,a0
    80004fec:	c529                	beqz	a0,80005036 <create+0xee>
  ilock(ip);
    80004fee:	ffffe097          	auipc	ra,0xffffe
    80004ff2:	632080e7          	jalr	1586(ra) # 80003620 <ilock>
  ip->major = major;
    80004ff6:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80004ffa:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80004ffe:	4905                	li	s2,1
    80005000:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80005004:	8552                	mv	a0,s4
    80005006:	ffffe097          	auipc	ra,0xffffe
    8000500a:	54e080e7          	jalr	1358(ra) # 80003554 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000500e:	032b0b63          	beq	s6,s2,80005044 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80005012:	004a2603          	lw	a2,4(s4)
    80005016:	fb040593          	add	a1,s0,-80
    8000501a:	8526                	mv	a0,s1
    8000501c:	fffff097          	auipc	ra,0xfffff
    80005020:	cf8080e7          	jalr	-776(ra) # 80003d14 <dirlink>
    80005024:	06054f63          	bltz	a0,800050a2 <create+0x15a>
  iunlockput(dp);
    80005028:	8526                	mv	a0,s1
    8000502a:	fffff097          	auipc	ra,0xfffff
    8000502e:	858080e7          	jalr	-1960(ra) # 80003882 <iunlockput>
  return ip;
    80005032:	8ad2                	mv	s5,s4
    80005034:	b759                	j	80004fba <create+0x72>
    iunlockput(dp);
    80005036:	8526                	mv	a0,s1
    80005038:	fffff097          	auipc	ra,0xfffff
    8000503c:	84a080e7          	jalr	-1974(ra) # 80003882 <iunlockput>
    return 0;
    80005040:	8ad2                	mv	s5,s4
    80005042:	bfa5                	j	80004fba <create+0x72>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005044:	004a2603          	lw	a2,4(s4)
    80005048:	00003597          	auipc	a1,0x3
    8000504c:	6a858593          	add	a1,a1,1704 # 800086f0 <syscalls+0x2a0>
    80005050:	8552                	mv	a0,s4
    80005052:	fffff097          	auipc	ra,0xfffff
    80005056:	cc2080e7          	jalr	-830(ra) # 80003d14 <dirlink>
    8000505a:	04054463          	bltz	a0,800050a2 <create+0x15a>
    8000505e:	40d0                	lw	a2,4(s1)
    80005060:	00003597          	auipc	a1,0x3
    80005064:	69858593          	add	a1,a1,1688 # 800086f8 <syscalls+0x2a8>
    80005068:	8552                	mv	a0,s4
    8000506a:	fffff097          	auipc	ra,0xfffff
    8000506e:	caa080e7          	jalr	-854(ra) # 80003d14 <dirlink>
    80005072:	02054863          	bltz	a0,800050a2 <create+0x15a>
  if(dirlink(dp, name, ip->inum) < 0)
    80005076:	004a2603          	lw	a2,4(s4)
    8000507a:	fb040593          	add	a1,s0,-80
    8000507e:	8526                	mv	a0,s1
    80005080:	fffff097          	auipc	ra,0xfffff
    80005084:	c94080e7          	jalr	-876(ra) # 80003d14 <dirlink>
    80005088:	00054d63          	bltz	a0,800050a2 <create+0x15a>
    dp->nlink++;  // for ".."
    8000508c:	04a4d783          	lhu	a5,74(s1)
    80005090:	2785                	addw	a5,a5,1
    80005092:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005096:	8526                	mv	a0,s1
    80005098:	ffffe097          	auipc	ra,0xffffe
    8000509c:	4bc080e7          	jalr	1212(ra) # 80003554 <iupdate>
    800050a0:	b761                	j	80005028 <create+0xe0>
  ip->nlink = 0;
    800050a2:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    800050a6:	8552                	mv	a0,s4
    800050a8:	ffffe097          	auipc	ra,0xffffe
    800050ac:	4ac080e7          	jalr	1196(ra) # 80003554 <iupdate>
  iunlockput(ip);
    800050b0:	8552                	mv	a0,s4
    800050b2:	ffffe097          	auipc	ra,0xffffe
    800050b6:	7d0080e7          	jalr	2000(ra) # 80003882 <iunlockput>
  iunlockput(dp);
    800050ba:	8526                	mv	a0,s1
    800050bc:	ffffe097          	auipc	ra,0xffffe
    800050c0:	7c6080e7          	jalr	1990(ra) # 80003882 <iunlockput>
  return 0;
    800050c4:	bddd                	j	80004fba <create+0x72>
    return 0;
    800050c6:	8aaa                	mv	s5,a0
    800050c8:	bdcd                	j	80004fba <create+0x72>

00000000800050ca <sys_dup>:
{
    800050ca:	7179                	add	sp,sp,-48
    800050cc:	f406                	sd	ra,40(sp)
    800050ce:	f022                	sd	s0,32(sp)
    800050d0:	ec26                	sd	s1,24(sp)
    800050d2:	e84a                	sd	s2,16(sp)
    800050d4:	1800                	add	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800050d6:	fd840613          	add	a2,s0,-40
    800050da:	4581                	li	a1,0
    800050dc:	4501                	li	a0,0
    800050de:	00000097          	auipc	ra,0x0
    800050e2:	dc8080e7          	jalr	-568(ra) # 80004ea6 <argfd>
    return -1;
    800050e6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800050e8:	02054363          	bltz	a0,8000510e <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    800050ec:	fd843903          	ld	s2,-40(s0)
    800050f0:	854a                	mv	a0,s2
    800050f2:	00000097          	auipc	ra,0x0
    800050f6:	e14080e7          	jalr	-492(ra) # 80004f06 <fdalloc>
    800050fa:	84aa                	mv	s1,a0
    return -1;
    800050fc:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800050fe:	00054863          	bltz	a0,8000510e <sys_dup+0x44>
  filedup(f);
    80005102:	854a                	mv	a0,s2
    80005104:	fffff097          	auipc	ra,0xfffff
    80005108:	334080e7          	jalr	820(ra) # 80004438 <filedup>
  return fd;
    8000510c:	87a6                	mv	a5,s1
}
    8000510e:	853e                	mv	a0,a5
    80005110:	70a2                	ld	ra,40(sp)
    80005112:	7402                	ld	s0,32(sp)
    80005114:	64e2                	ld	s1,24(sp)
    80005116:	6942                	ld	s2,16(sp)
    80005118:	6145                	add	sp,sp,48
    8000511a:	8082                	ret

000000008000511c <sys_read>:
{
    8000511c:	7179                	add	sp,sp,-48
    8000511e:	f406                	sd	ra,40(sp)
    80005120:	f022                	sd	s0,32(sp)
    80005122:	1800                	add	s0,sp,48
  argaddr(1, &p);
    80005124:	fd840593          	add	a1,s0,-40
    80005128:	4505                	li	a0,1
    8000512a:	ffffe097          	auipc	ra,0xffffe
    8000512e:	9b4080e7          	jalr	-1612(ra) # 80002ade <argaddr>
  argint(2, &n);
    80005132:	fe440593          	add	a1,s0,-28
    80005136:	4509                	li	a0,2
    80005138:	ffffe097          	auipc	ra,0xffffe
    8000513c:	986080e7          	jalr	-1658(ra) # 80002abe <argint>
  if(argfd(0, 0, &f) < 0)
    80005140:	fe840613          	add	a2,s0,-24
    80005144:	4581                	li	a1,0
    80005146:	4501                	li	a0,0
    80005148:	00000097          	auipc	ra,0x0
    8000514c:	d5e080e7          	jalr	-674(ra) # 80004ea6 <argfd>
    80005150:	87aa                	mv	a5,a0
    return -1;
    80005152:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005154:	0007cc63          	bltz	a5,8000516c <sys_read+0x50>
  return fileread(f, p, n);
    80005158:	fe442603          	lw	a2,-28(s0)
    8000515c:	fd843583          	ld	a1,-40(s0)
    80005160:	fe843503          	ld	a0,-24(s0)
    80005164:	fffff097          	auipc	ra,0xfffff
    80005168:	460080e7          	jalr	1120(ra) # 800045c4 <fileread>
}
    8000516c:	70a2                	ld	ra,40(sp)
    8000516e:	7402                	ld	s0,32(sp)
    80005170:	6145                	add	sp,sp,48
    80005172:	8082                	ret

0000000080005174 <sys_write>:
{
    80005174:	7179                	add	sp,sp,-48
    80005176:	f406                	sd	ra,40(sp)
    80005178:	f022                	sd	s0,32(sp)
    8000517a:	1800                	add	s0,sp,48
  argaddr(1, &p);
    8000517c:	fd840593          	add	a1,s0,-40
    80005180:	4505                	li	a0,1
    80005182:	ffffe097          	auipc	ra,0xffffe
    80005186:	95c080e7          	jalr	-1700(ra) # 80002ade <argaddr>
  argint(2, &n);
    8000518a:	fe440593          	add	a1,s0,-28
    8000518e:	4509                	li	a0,2
    80005190:	ffffe097          	auipc	ra,0xffffe
    80005194:	92e080e7          	jalr	-1746(ra) # 80002abe <argint>
  if(argfd(0, 0, &f) < 0)
    80005198:	fe840613          	add	a2,s0,-24
    8000519c:	4581                	li	a1,0
    8000519e:	4501                	li	a0,0
    800051a0:	00000097          	auipc	ra,0x0
    800051a4:	d06080e7          	jalr	-762(ra) # 80004ea6 <argfd>
    800051a8:	87aa                	mv	a5,a0
    return -1;
    800051aa:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800051ac:	0007cc63          	bltz	a5,800051c4 <sys_write+0x50>
  return filewrite(f, p, n);
    800051b0:	fe442603          	lw	a2,-28(s0)
    800051b4:	fd843583          	ld	a1,-40(s0)
    800051b8:	fe843503          	ld	a0,-24(s0)
    800051bc:	fffff097          	auipc	ra,0xfffff
    800051c0:	4ca080e7          	jalr	1226(ra) # 80004686 <filewrite>
}
    800051c4:	70a2                	ld	ra,40(sp)
    800051c6:	7402                	ld	s0,32(sp)
    800051c8:	6145                	add	sp,sp,48
    800051ca:	8082                	ret

00000000800051cc <sys_close>:
{
    800051cc:	1101                	add	sp,sp,-32
    800051ce:	ec06                	sd	ra,24(sp)
    800051d0:	e822                	sd	s0,16(sp)
    800051d2:	1000                	add	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800051d4:	fe040613          	add	a2,s0,-32
    800051d8:	fec40593          	add	a1,s0,-20
    800051dc:	4501                	li	a0,0
    800051de:	00000097          	auipc	ra,0x0
    800051e2:	cc8080e7          	jalr	-824(ra) # 80004ea6 <argfd>
    return -1;
    800051e6:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800051e8:	02054463          	bltz	a0,80005210 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800051ec:	ffffc097          	auipc	ra,0xffffc
    800051f0:	7b8080e7          	jalr	1976(ra) # 800019a4 <myproc>
    800051f4:	fec42783          	lw	a5,-20(s0)
    800051f8:	07e9                	add	a5,a5,26
    800051fa:	078e                	sll	a5,a5,0x3
    800051fc:	953e                	add	a0,a0,a5
    800051fe:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80005202:	fe043503          	ld	a0,-32(s0)
    80005206:	fffff097          	auipc	ra,0xfffff
    8000520a:	284080e7          	jalr	644(ra) # 8000448a <fileclose>
  return 0;
    8000520e:	4781                	li	a5,0
}
    80005210:	853e                	mv	a0,a5
    80005212:	60e2                	ld	ra,24(sp)
    80005214:	6442                	ld	s0,16(sp)
    80005216:	6105                	add	sp,sp,32
    80005218:	8082                	ret

000000008000521a <sys_fstat>:
{
    8000521a:	1101                	add	sp,sp,-32
    8000521c:	ec06                	sd	ra,24(sp)
    8000521e:	e822                	sd	s0,16(sp)
    80005220:	1000                	add	s0,sp,32
  argaddr(1, &st);
    80005222:	fe040593          	add	a1,s0,-32
    80005226:	4505                	li	a0,1
    80005228:	ffffe097          	auipc	ra,0xffffe
    8000522c:	8b6080e7          	jalr	-1866(ra) # 80002ade <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005230:	fe840613          	add	a2,s0,-24
    80005234:	4581                	li	a1,0
    80005236:	4501                	li	a0,0
    80005238:	00000097          	auipc	ra,0x0
    8000523c:	c6e080e7          	jalr	-914(ra) # 80004ea6 <argfd>
    80005240:	87aa                	mv	a5,a0
    return -1;
    80005242:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005244:	0007ca63          	bltz	a5,80005258 <sys_fstat+0x3e>
  return filestat(f, st);
    80005248:	fe043583          	ld	a1,-32(s0)
    8000524c:	fe843503          	ld	a0,-24(s0)
    80005250:	fffff097          	auipc	ra,0xfffff
    80005254:	302080e7          	jalr	770(ra) # 80004552 <filestat>
}
    80005258:	60e2                	ld	ra,24(sp)
    8000525a:	6442                	ld	s0,16(sp)
    8000525c:	6105                	add	sp,sp,32
    8000525e:	8082                	ret

0000000080005260 <sys_link>:
{
    80005260:	7169                	add	sp,sp,-304
    80005262:	f606                	sd	ra,296(sp)
    80005264:	f222                	sd	s0,288(sp)
    80005266:	ee26                	sd	s1,280(sp)
    80005268:	ea4a                	sd	s2,272(sp)
    8000526a:	1a00                	add	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000526c:	08000613          	li	a2,128
    80005270:	ed040593          	add	a1,s0,-304
    80005274:	4501                	li	a0,0
    80005276:	ffffe097          	auipc	ra,0xffffe
    8000527a:	888080e7          	jalr	-1912(ra) # 80002afe <argstr>
    return -1;
    8000527e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005280:	10054e63          	bltz	a0,8000539c <sys_link+0x13c>
    80005284:	08000613          	li	a2,128
    80005288:	f5040593          	add	a1,s0,-176
    8000528c:	4505                	li	a0,1
    8000528e:	ffffe097          	auipc	ra,0xffffe
    80005292:	870080e7          	jalr	-1936(ra) # 80002afe <argstr>
    return -1;
    80005296:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005298:	10054263          	bltz	a0,8000539c <sys_link+0x13c>
  begin_op();
    8000529c:	fffff097          	auipc	ra,0xfffff
    800052a0:	d2a080e7          	jalr	-726(ra) # 80003fc6 <begin_op>
  if((ip = namei(old)) == 0){
    800052a4:	ed040513          	add	a0,s0,-304
    800052a8:	fffff097          	auipc	ra,0xfffff
    800052ac:	b1e080e7          	jalr	-1250(ra) # 80003dc6 <namei>
    800052b0:	84aa                	mv	s1,a0
    800052b2:	c551                	beqz	a0,8000533e <sys_link+0xde>
  ilock(ip);
    800052b4:	ffffe097          	auipc	ra,0xffffe
    800052b8:	36c080e7          	jalr	876(ra) # 80003620 <ilock>
  if(ip->type == T_DIR){
    800052bc:	04449703          	lh	a4,68(s1)
    800052c0:	4785                	li	a5,1
    800052c2:	08f70463          	beq	a4,a5,8000534a <sys_link+0xea>
  ip->nlink++;
    800052c6:	04a4d783          	lhu	a5,74(s1)
    800052ca:	2785                	addw	a5,a5,1
    800052cc:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800052d0:	8526                	mv	a0,s1
    800052d2:	ffffe097          	auipc	ra,0xffffe
    800052d6:	282080e7          	jalr	642(ra) # 80003554 <iupdate>
  iunlock(ip);
    800052da:	8526                	mv	a0,s1
    800052dc:	ffffe097          	auipc	ra,0xffffe
    800052e0:	406080e7          	jalr	1030(ra) # 800036e2 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800052e4:	fd040593          	add	a1,s0,-48
    800052e8:	f5040513          	add	a0,s0,-176
    800052ec:	fffff097          	auipc	ra,0xfffff
    800052f0:	af8080e7          	jalr	-1288(ra) # 80003de4 <nameiparent>
    800052f4:	892a                	mv	s2,a0
    800052f6:	c935                	beqz	a0,8000536a <sys_link+0x10a>
  ilock(dp);
    800052f8:	ffffe097          	auipc	ra,0xffffe
    800052fc:	328080e7          	jalr	808(ra) # 80003620 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005300:	00092703          	lw	a4,0(s2)
    80005304:	409c                	lw	a5,0(s1)
    80005306:	04f71d63          	bne	a4,a5,80005360 <sys_link+0x100>
    8000530a:	40d0                	lw	a2,4(s1)
    8000530c:	fd040593          	add	a1,s0,-48
    80005310:	854a                	mv	a0,s2
    80005312:	fffff097          	auipc	ra,0xfffff
    80005316:	a02080e7          	jalr	-1534(ra) # 80003d14 <dirlink>
    8000531a:	04054363          	bltz	a0,80005360 <sys_link+0x100>
  iunlockput(dp);
    8000531e:	854a                	mv	a0,s2
    80005320:	ffffe097          	auipc	ra,0xffffe
    80005324:	562080e7          	jalr	1378(ra) # 80003882 <iunlockput>
  iput(ip);
    80005328:	8526                	mv	a0,s1
    8000532a:	ffffe097          	auipc	ra,0xffffe
    8000532e:	4b0080e7          	jalr	1200(ra) # 800037da <iput>
  end_op();
    80005332:	fffff097          	auipc	ra,0xfffff
    80005336:	d0e080e7          	jalr	-754(ra) # 80004040 <end_op>
  return 0;
    8000533a:	4781                	li	a5,0
    8000533c:	a085                	j	8000539c <sys_link+0x13c>
    end_op();
    8000533e:	fffff097          	auipc	ra,0xfffff
    80005342:	d02080e7          	jalr	-766(ra) # 80004040 <end_op>
    return -1;
    80005346:	57fd                	li	a5,-1
    80005348:	a891                	j	8000539c <sys_link+0x13c>
    iunlockput(ip);
    8000534a:	8526                	mv	a0,s1
    8000534c:	ffffe097          	auipc	ra,0xffffe
    80005350:	536080e7          	jalr	1334(ra) # 80003882 <iunlockput>
    end_op();
    80005354:	fffff097          	auipc	ra,0xfffff
    80005358:	cec080e7          	jalr	-788(ra) # 80004040 <end_op>
    return -1;
    8000535c:	57fd                	li	a5,-1
    8000535e:	a83d                	j	8000539c <sys_link+0x13c>
    iunlockput(dp);
    80005360:	854a                	mv	a0,s2
    80005362:	ffffe097          	auipc	ra,0xffffe
    80005366:	520080e7          	jalr	1312(ra) # 80003882 <iunlockput>
  ilock(ip);
    8000536a:	8526                	mv	a0,s1
    8000536c:	ffffe097          	auipc	ra,0xffffe
    80005370:	2b4080e7          	jalr	692(ra) # 80003620 <ilock>
  ip->nlink--;
    80005374:	04a4d783          	lhu	a5,74(s1)
    80005378:	37fd                	addw	a5,a5,-1
    8000537a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000537e:	8526                	mv	a0,s1
    80005380:	ffffe097          	auipc	ra,0xffffe
    80005384:	1d4080e7          	jalr	468(ra) # 80003554 <iupdate>
  iunlockput(ip);
    80005388:	8526                	mv	a0,s1
    8000538a:	ffffe097          	auipc	ra,0xffffe
    8000538e:	4f8080e7          	jalr	1272(ra) # 80003882 <iunlockput>
  end_op();
    80005392:	fffff097          	auipc	ra,0xfffff
    80005396:	cae080e7          	jalr	-850(ra) # 80004040 <end_op>
  return -1;
    8000539a:	57fd                	li	a5,-1
}
    8000539c:	853e                	mv	a0,a5
    8000539e:	70b2                	ld	ra,296(sp)
    800053a0:	7412                	ld	s0,288(sp)
    800053a2:	64f2                	ld	s1,280(sp)
    800053a4:	6952                	ld	s2,272(sp)
    800053a6:	6155                	add	sp,sp,304
    800053a8:	8082                	ret

00000000800053aa <sys_unlink>:
{
    800053aa:	7151                	add	sp,sp,-240
    800053ac:	f586                	sd	ra,232(sp)
    800053ae:	f1a2                	sd	s0,224(sp)
    800053b0:	eda6                	sd	s1,216(sp)
    800053b2:	e9ca                	sd	s2,208(sp)
    800053b4:	e5ce                	sd	s3,200(sp)
    800053b6:	1980                	add	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800053b8:	08000613          	li	a2,128
    800053bc:	f3040593          	add	a1,s0,-208
    800053c0:	4501                	li	a0,0
    800053c2:	ffffd097          	auipc	ra,0xffffd
    800053c6:	73c080e7          	jalr	1852(ra) # 80002afe <argstr>
    800053ca:	18054163          	bltz	a0,8000554c <sys_unlink+0x1a2>
  begin_op();
    800053ce:	fffff097          	auipc	ra,0xfffff
    800053d2:	bf8080e7          	jalr	-1032(ra) # 80003fc6 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800053d6:	fb040593          	add	a1,s0,-80
    800053da:	f3040513          	add	a0,s0,-208
    800053de:	fffff097          	auipc	ra,0xfffff
    800053e2:	a06080e7          	jalr	-1530(ra) # 80003de4 <nameiparent>
    800053e6:	84aa                	mv	s1,a0
    800053e8:	c979                	beqz	a0,800054be <sys_unlink+0x114>
  ilock(dp);
    800053ea:	ffffe097          	auipc	ra,0xffffe
    800053ee:	236080e7          	jalr	566(ra) # 80003620 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800053f2:	00003597          	auipc	a1,0x3
    800053f6:	2fe58593          	add	a1,a1,766 # 800086f0 <syscalls+0x2a0>
    800053fa:	fb040513          	add	a0,s0,-80
    800053fe:	ffffe097          	auipc	ra,0xffffe
    80005402:	6ec080e7          	jalr	1772(ra) # 80003aea <namecmp>
    80005406:	14050a63          	beqz	a0,8000555a <sys_unlink+0x1b0>
    8000540a:	00003597          	auipc	a1,0x3
    8000540e:	2ee58593          	add	a1,a1,750 # 800086f8 <syscalls+0x2a8>
    80005412:	fb040513          	add	a0,s0,-80
    80005416:	ffffe097          	auipc	ra,0xffffe
    8000541a:	6d4080e7          	jalr	1748(ra) # 80003aea <namecmp>
    8000541e:	12050e63          	beqz	a0,8000555a <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005422:	f2c40613          	add	a2,s0,-212
    80005426:	fb040593          	add	a1,s0,-80
    8000542a:	8526                	mv	a0,s1
    8000542c:	ffffe097          	auipc	ra,0xffffe
    80005430:	6d8080e7          	jalr	1752(ra) # 80003b04 <dirlookup>
    80005434:	892a                	mv	s2,a0
    80005436:	12050263          	beqz	a0,8000555a <sys_unlink+0x1b0>
  ilock(ip);
    8000543a:	ffffe097          	auipc	ra,0xffffe
    8000543e:	1e6080e7          	jalr	486(ra) # 80003620 <ilock>
  if(ip->nlink < 1)
    80005442:	04a91783          	lh	a5,74(s2)
    80005446:	08f05263          	blez	a5,800054ca <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000544a:	04491703          	lh	a4,68(s2)
    8000544e:	4785                	li	a5,1
    80005450:	08f70563          	beq	a4,a5,800054da <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005454:	4641                	li	a2,16
    80005456:	4581                	li	a1,0
    80005458:	fc040513          	add	a0,s0,-64
    8000545c:	ffffc097          	auipc	ra,0xffffc
    80005460:	870080e7          	jalr	-1936(ra) # 80000ccc <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005464:	4741                	li	a4,16
    80005466:	f2c42683          	lw	a3,-212(s0)
    8000546a:	fc040613          	add	a2,s0,-64
    8000546e:	4581                	li	a1,0
    80005470:	8526                	mv	a0,s1
    80005472:	ffffe097          	auipc	ra,0xffffe
    80005476:	55a080e7          	jalr	1370(ra) # 800039cc <writei>
    8000547a:	47c1                	li	a5,16
    8000547c:	0af51563          	bne	a0,a5,80005526 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005480:	04491703          	lh	a4,68(s2)
    80005484:	4785                	li	a5,1
    80005486:	0af70863          	beq	a4,a5,80005536 <sys_unlink+0x18c>
  iunlockput(dp);
    8000548a:	8526                	mv	a0,s1
    8000548c:	ffffe097          	auipc	ra,0xffffe
    80005490:	3f6080e7          	jalr	1014(ra) # 80003882 <iunlockput>
  ip->nlink--;
    80005494:	04a95783          	lhu	a5,74(s2)
    80005498:	37fd                	addw	a5,a5,-1
    8000549a:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000549e:	854a                	mv	a0,s2
    800054a0:	ffffe097          	auipc	ra,0xffffe
    800054a4:	0b4080e7          	jalr	180(ra) # 80003554 <iupdate>
  iunlockput(ip);
    800054a8:	854a                	mv	a0,s2
    800054aa:	ffffe097          	auipc	ra,0xffffe
    800054ae:	3d8080e7          	jalr	984(ra) # 80003882 <iunlockput>
  end_op();
    800054b2:	fffff097          	auipc	ra,0xfffff
    800054b6:	b8e080e7          	jalr	-1138(ra) # 80004040 <end_op>
  return 0;
    800054ba:	4501                	li	a0,0
    800054bc:	a84d                	j	8000556e <sys_unlink+0x1c4>
    end_op();
    800054be:	fffff097          	auipc	ra,0xfffff
    800054c2:	b82080e7          	jalr	-1150(ra) # 80004040 <end_op>
    return -1;
    800054c6:	557d                	li	a0,-1
    800054c8:	a05d                	j	8000556e <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800054ca:	00003517          	auipc	a0,0x3
    800054ce:	23650513          	add	a0,a0,566 # 80008700 <syscalls+0x2b0>
    800054d2:	ffffb097          	auipc	ra,0xffffb
    800054d6:	068080e7          	jalr	104(ra) # 8000053a <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800054da:	04c92703          	lw	a4,76(s2)
    800054de:	02000793          	li	a5,32
    800054e2:	f6e7f9e3          	bgeu	a5,a4,80005454 <sys_unlink+0xaa>
    800054e6:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800054ea:	4741                	li	a4,16
    800054ec:	86ce                	mv	a3,s3
    800054ee:	f1840613          	add	a2,s0,-232
    800054f2:	4581                	li	a1,0
    800054f4:	854a                	mv	a0,s2
    800054f6:	ffffe097          	auipc	ra,0xffffe
    800054fa:	3de080e7          	jalr	990(ra) # 800038d4 <readi>
    800054fe:	47c1                	li	a5,16
    80005500:	00f51b63          	bne	a0,a5,80005516 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005504:	f1845783          	lhu	a5,-232(s0)
    80005508:	e7a1                	bnez	a5,80005550 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000550a:	29c1                	addw	s3,s3,16
    8000550c:	04c92783          	lw	a5,76(s2)
    80005510:	fcf9ede3          	bltu	s3,a5,800054ea <sys_unlink+0x140>
    80005514:	b781                	j	80005454 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005516:	00003517          	auipc	a0,0x3
    8000551a:	20250513          	add	a0,a0,514 # 80008718 <syscalls+0x2c8>
    8000551e:	ffffb097          	auipc	ra,0xffffb
    80005522:	01c080e7          	jalr	28(ra) # 8000053a <panic>
    panic("unlink: writei");
    80005526:	00003517          	auipc	a0,0x3
    8000552a:	20a50513          	add	a0,a0,522 # 80008730 <syscalls+0x2e0>
    8000552e:	ffffb097          	auipc	ra,0xffffb
    80005532:	00c080e7          	jalr	12(ra) # 8000053a <panic>
    dp->nlink--;
    80005536:	04a4d783          	lhu	a5,74(s1)
    8000553a:	37fd                	addw	a5,a5,-1
    8000553c:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005540:	8526                	mv	a0,s1
    80005542:	ffffe097          	auipc	ra,0xffffe
    80005546:	012080e7          	jalr	18(ra) # 80003554 <iupdate>
    8000554a:	b781                	j	8000548a <sys_unlink+0xe0>
    return -1;
    8000554c:	557d                	li	a0,-1
    8000554e:	a005                	j	8000556e <sys_unlink+0x1c4>
    iunlockput(ip);
    80005550:	854a                	mv	a0,s2
    80005552:	ffffe097          	auipc	ra,0xffffe
    80005556:	330080e7          	jalr	816(ra) # 80003882 <iunlockput>
  iunlockput(dp);
    8000555a:	8526                	mv	a0,s1
    8000555c:	ffffe097          	auipc	ra,0xffffe
    80005560:	326080e7          	jalr	806(ra) # 80003882 <iunlockput>
  end_op();
    80005564:	fffff097          	auipc	ra,0xfffff
    80005568:	adc080e7          	jalr	-1316(ra) # 80004040 <end_op>
  return -1;
    8000556c:	557d                	li	a0,-1
}
    8000556e:	70ae                	ld	ra,232(sp)
    80005570:	740e                	ld	s0,224(sp)
    80005572:	64ee                	ld	s1,216(sp)
    80005574:	694e                	ld	s2,208(sp)
    80005576:	69ae                	ld	s3,200(sp)
    80005578:	616d                	add	sp,sp,240
    8000557a:	8082                	ret

000000008000557c <sys_open>:

uint64
sys_open(void)
{
    8000557c:	7131                	add	sp,sp,-192
    8000557e:	fd06                	sd	ra,184(sp)
    80005580:	f922                	sd	s0,176(sp)
    80005582:	f526                	sd	s1,168(sp)
    80005584:	f14a                	sd	s2,160(sp)
    80005586:	ed4e                	sd	s3,152(sp)
    80005588:	0180                	add	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    8000558a:	f4c40593          	add	a1,s0,-180
    8000558e:	4505                	li	a0,1
    80005590:	ffffd097          	auipc	ra,0xffffd
    80005594:	52e080e7          	jalr	1326(ra) # 80002abe <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005598:	08000613          	li	a2,128
    8000559c:	f5040593          	add	a1,s0,-176
    800055a0:	4501                	li	a0,0
    800055a2:	ffffd097          	auipc	ra,0xffffd
    800055a6:	55c080e7          	jalr	1372(ra) # 80002afe <argstr>
    800055aa:	87aa                	mv	a5,a0
    return -1;
    800055ac:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    800055ae:	0a07c863          	bltz	a5,8000565e <sys_open+0xe2>

  begin_op();
    800055b2:	fffff097          	auipc	ra,0xfffff
    800055b6:	a14080e7          	jalr	-1516(ra) # 80003fc6 <begin_op>

  if(omode & O_CREATE){
    800055ba:	f4c42783          	lw	a5,-180(s0)
    800055be:	2007f793          	and	a5,a5,512
    800055c2:	cbdd                	beqz	a5,80005678 <sys_open+0xfc>
    ip = create(path, T_FILE, 0, 0);
    800055c4:	4681                	li	a3,0
    800055c6:	4601                	li	a2,0
    800055c8:	4589                	li	a1,2
    800055ca:	f5040513          	add	a0,s0,-176
    800055ce:	00000097          	auipc	ra,0x0
    800055d2:	97a080e7          	jalr	-1670(ra) # 80004f48 <create>
    800055d6:	84aa                	mv	s1,a0
    if(ip == 0){
    800055d8:	c951                	beqz	a0,8000566c <sys_open+0xf0>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800055da:	04449703          	lh	a4,68(s1)
    800055de:	478d                	li	a5,3
    800055e0:	00f71763          	bne	a4,a5,800055ee <sys_open+0x72>
    800055e4:	0464d703          	lhu	a4,70(s1)
    800055e8:	47a5                	li	a5,9
    800055ea:	0ce7ec63          	bltu	a5,a4,800056c2 <sys_open+0x146>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800055ee:	fffff097          	auipc	ra,0xfffff
    800055f2:	de0080e7          	jalr	-544(ra) # 800043ce <filealloc>
    800055f6:	892a                	mv	s2,a0
    800055f8:	c56d                	beqz	a0,800056e2 <sys_open+0x166>
    800055fa:	00000097          	auipc	ra,0x0
    800055fe:	90c080e7          	jalr	-1780(ra) # 80004f06 <fdalloc>
    80005602:	89aa                	mv	s3,a0
    80005604:	0c054a63          	bltz	a0,800056d8 <sys_open+0x15c>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005608:	04449703          	lh	a4,68(s1)
    8000560c:	478d                	li	a5,3
    8000560e:	0ef70563          	beq	a4,a5,800056f8 <sys_open+0x17c>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005612:	4789                	li	a5,2
    80005614:	00f92023          	sw	a5,0(s2)
    f->off = 0;
    80005618:	02092023          	sw	zero,32(s2)
  }
  f->ip = ip;
    8000561c:	00993c23          	sd	s1,24(s2)
  f->readable = !(omode & O_WRONLY);
    80005620:	f4c42783          	lw	a5,-180(s0)
    80005624:	0017c713          	xor	a4,a5,1
    80005628:	8b05                	and	a4,a4,1
    8000562a:	00e90423          	sb	a4,8(s2)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000562e:	0037f713          	and	a4,a5,3
    80005632:	00e03733          	snez	a4,a4
    80005636:	00e904a3          	sb	a4,9(s2)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    8000563a:	4007f793          	and	a5,a5,1024
    8000563e:	c791                	beqz	a5,8000564a <sys_open+0xce>
    80005640:	04449703          	lh	a4,68(s1)
    80005644:	4789                	li	a5,2
    80005646:	0cf70063          	beq	a4,a5,80005706 <sys_open+0x18a>
    itrunc(ip);
  }

  iunlock(ip);
    8000564a:	8526                	mv	a0,s1
    8000564c:	ffffe097          	auipc	ra,0xffffe
    80005650:	096080e7          	jalr	150(ra) # 800036e2 <iunlock>
  end_op();
    80005654:	fffff097          	auipc	ra,0xfffff
    80005658:	9ec080e7          	jalr	-1556(ra) # 80004040 <end_op>

  return fd;
    8000565c:	854e                	mv	a0,s3
}
    8000565e:	70ea                	ld	ra,184(sp)
    80005660:	744a                	ld	s0,176(sp)
    80005662:	74aa                	ld	s1,168(sp)
    80005664:	790a                	ld	s2,160(sp)
    80005666:	69ea                	ld	s3,152(sp)
    80005668:	6129                	add	sp,sp,192
    8000566a:	8082                	ret
      end_op();
    8000566c:	fffff097          	auipc	ra,0xfffff
    80005670:	9d4080e7          	jalr	-1580(ra) # 80004040 <end_op>
      return -1;
    80005674:	557d                	li	a0,-1
    80005676:	b7e5                	j	8000565e <sys_open+0xe2>
    if((ip = namei(path)) == 0){
    80005678:	f5040513          	add	a0,s0,-176
    8000567c:	ffffe097          	auipc	ra,0xffffe
    80005680:	74a080e7          	jalr	1866(ra) # 80003dc6 <namei>
    80005684:	84aa                	mv	s1,a0
    80005686:	c905                	beqz	a0,800056b6 <sys_open+0x13a>
    ilock(ip);
    80005688:	ffffe097          	auipc	ra,0xffffe
    8000568c:	f98080e7          	jalr	-104(ra) # 80003620 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005690:	04449703          	lh	a4,68(s1)
    80005694:	4785                	li	a5,1
    80005696:	f4f712e3          	bne	a4,a5,800055da <sys_open+0x5e>
    8000569a:	f4c42783          	lw	a5,-180(s0)
    8000569e:	dba1                	beqz	a5,800055ee <sys_open+0x72>
      iunlockput(ip);
    800056a0:	8526                	mv	a0,s1
    800056a2:	ffffe097          	auipc	ra,0xffffe
    800056a6:	1e0080e7          	jalr	480(ra) # 80003882 <iunlockput>
      end_op();
    800056aa:	fffff097          	auipc	ra,0xfffff
    800056ae:	996080e7          	jalr	-1642(ra) # 80004040 <end_op>
      return -1;
    800056b2:	557d                	li	a0,-1
    800056b4:	b76d                	j	8000565e <sys_open+0xe2>
      end_op();
    800056b6:	fffff097          	auipc	ra,0xfffff
    800056ba:	98a080e7          	jalr	-1654(ra) # 80004040 <end_op>
      return -1;
    800056be:	557d                	li	a0,-1
    800056c0:	bf79                	j	8000565e <sys_open+0xe2>
    iunlockput(ip);
    800056c2:	8526                	mv	a0,s1
    800056c4:	ffffe097          	auipc	ra,0xffffe
    800056c8:	1be080e7          	jalr	446(ra) # 80003882 <iunlockput>
    end_op();
    800056cc:	fffff097          	auipc	ra,0xfffff
    800056d0:	974080e7          	jalr	-1676(ra) # 80004040 <end_op>
    return -1;
    800056d4:	557d                	li	a0,-1
    800056d6:	b761                	j	8000565e <sys_open+0xe2>
      fileclose(f);
    800056d8:	854a                	mv	a0,s2
    800056da:	fffff097          	auipc	ra,0xfffff
    800056de:	db0080e7          	jalr	-592(ra) # 8000448a <fileclose>
    iunlockput(ip);
    800056e2:	8526                	mv	a0,s1
    800056e4:	ffffe097          	auipc	ra,0xffffe
    800056e8:	19e080e7          	jalr	414(ra) # 80003882 <iunlockput>
    end_op();
    800056ec:	fffff097          	auipc	ra,0xfffff
    800056f0:	954080e7          	jalr	-1708(ra) # 80004040 <end_op>
    return -1;
    800056f4:	557d                	li	a0,-1
    800056f6:	b7a5                	j	8000565e <sys_open+0xe2>
    f->type = FD_DEVICE;
    800056f8:	00f92023          	sw	a5,0(s2)
    f->major = ip->major;
    800056fc:	04649783          	lh	a5,70(s1)
    80005700:	02f91223          	sh	a5,36(s2)
    80005704:	bf21                	j	8000561c <sys_open+0xa0>
    itrunc(ip);
    80005706:	8526                	mv	a0,s1
    80005708:	ffffe097          	auipc	ra,0xffffe
    8000570c:	026080e7          	jalr	38(ra) # 8000372e <itrunc>
    80005710:	bf2d                	j	8000564a <sys_open+0xce>

0000000080005712 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005712:	7175                	add	sp,sp,-144
    80005714:	e506                	sd	ra,136(sp)
    80005716:	e122                	sd	s0,128(sp)
    80005718:	0900                	add	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    8000571a:	fffff097          	auipc	ra,0xfffff
    8000571e:	8ac080e7          	jalr	-1876(ra) # 80003fc6 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005722:	08000613          	li	a2,128
    80005726:	f7040593          	add	a1,s0,-144
    8000572a:	4501                	li	a0,0
    8000572c:	ffffd097          	auipc	ra,0xffffd
    80005730:	3d2080e7          	jalr	978(ra) # 80002afe <argstr>
    80005734:	02054963          	bltz	a0,80005766 <sys_mkdir+0x54>
    80005738:	4681                	li	a3,0
    8000573a:	4601                	li	a2,0
    8000573c:	4585                	li	a1,1
    8000573e:	f7040513          	add	a0,s0,-144
    80005742:	00000097          	auipc	ra,0x0
    80005746:	806080e7          	jalr	-2042(ra) # 80004f48 <create>
    8000574a:	cd11                	beqz	a0,80005766 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000574c:	ffffe097          	auipc	ra,0xffffe
    80005750:	136080e7          	jalr	310(ra) # 80003882 <iunlockput>
  end_op();
    80005754:	fffff097          	auipc	ra,0xfffff
    80005758:	8ec080e7          	jalr	-1812(ra) # 80004040 <end_op>
  return 0;
    8000575c:	4501                	li	a0,0
}
    8000575e:	60aa                	ld	ra,136(sp)
    80005760:	640a                	ld	s0,128(sp)
    80005762:	6149                	add	sp,sp,144
    80005764:	8082                	ret
    end_op();
    80005766:	fffff097          	auipc	ra,0xfffff
    8000576a:	8da080e7          	jalr	-1830(ra) # 80004040 <end_op>
    return -1;
    8000576e:	557d                	li	a0,-1
    80005770:	b7fd                	j	8000575e <sys_mkdir+0x4c>

0000000080005772 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005772:	7135                	add	sp,sp,-160
    80005774:	ed06                	sd	ra,152(sp)
    80005776:	e922                	sd	s0,144(sp)
    80005778:	1100                	add	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    8000577a:	fffff097          	auipc	ra,0xfffff
    8000577e:	84c080e7          	jalr	-1972(ra) # 80003fc6 <begin_op>
  argint(1, &major);
    80005782:	f6c40593          	add	a1,s0,-148
    80005786:	4505                	li	a0,1
    80005788:	ffffd097          	auipc	ra,0xffffd
    8000578c:	336080e7          	jalr	822(ra) # 80002abe <argint>
  argint(2, &minor);
    80005790:	f6840593          	add	a1,s0,-152
    80005794:	4509                	li	a0,2
    80005796:	ffffd097          	auipc	ra,0xffffd
    8000579a:	328080e7          	jalr	808(ra) # 80002abe <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000579e:	08000613          	li	a2,128
    800057a2:	f7040593          	add	a1,s0,-144
    800057a6:	4501                	li	a0,0
    800057a8:	ffffd097          	auipc	ra,0xffffd
    800057ac:	356080e7          	jalr	854(ra) # 80002afe <argstr>
    800057b0:	02054b63          	bltz	a0,800057e6 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800057b4:	f6841683          	lh	a3,-152(s0)
    800057b8:	f6c41603          	lh	a2,-148(s0)
    800057bc:	458d                	li	a1,3
    800057be:	f7040513          	add	a0,s0,-144
    800057c2:	fffff097          	auipc	ra,0xfffff
    800057c6:	786080e7          	jalr	1926(ra) # 80004f48 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800057ca:	cd11                	beqz	a0,800057e6 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800057cc:	ffffe097          	auipc	ra,0xffffe
    800057d0:	0b6080e7          	jalr	182(ra) # 80003882 <iunlockput>
  end_op();
    800057d4:	fffff097          	auipc	ra,0xfffff
    800057d8:	86c080e7          	jalr	-1940(ra) # 80004040 <end_op>
  return 0;
    800057dc:	4501                	li	a0,0
}
    800057de:	60ea                	ld	ra,152(sp)
    800057e0:	644a                	ld	s0,144(sp)
    800057e2:	610d                	add	sp,sp,160
    800057e4:	8082                	ret
    end_op();
    800057e6:	fffff097          	auipc	ra,0xfffff
    800057ea:	85a080e7          	jalr	-1958(ra) # 80004040 <end_op>
    return -1;
    800057ee:	557d                	li	a0,-1
    800057f0:	b7fd                	j	800057de <sys_mknod+0x6c>

00000000800057f2 <sys_chdir>:

uint64
sys_chdir(void)
{
    800057f2:	7135                	add	sp,sp,-160
    800057f4:	ed06                	sd	ra,152(sp)
    800057f6:	e922                	sd	s0,144(sp)
    800057f8:	e526                	sd	s1,136(sp)
    800057fa:	e14a                	sd	s2,128(sp)
    800057fc:	1100                	add	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800057fe:	ffffc097          	auipc	ra,0xffffc
    80005802:	1a6080e7          	jalr	422(ra) # 800019a4 <myproc>
    80005806:	892a                	mv	s2,a0
  
  begin_op();
    80005808:	ffffe097          	auipc	ra,0xffffe
    8000580c:	7be080e7          	jalr	1982(ra) # 80003fc6 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005810:	08000613          	li	a2,128
    80005814:	f6040593          	add	a1,s0,-160
    80005818:	4501                	li	a0,0
    8000581a:	ffffd097          	auipc	ra,0xffffd
    8000581e:	2e4080e7          	jalr	740(ra) # 80002afe <argstr>
    80005822:	04054b63          	bltz	a0,80005878 <sys_chdir+0x86>
    80005826:	f6040513          	add	a0,s0,-160
    8000582a:	ffffe097          	auipc	ra,0xffffe
    8000582e:	59c080e7          	jalr	1436(ra) # 80003dc6 <namei>
    80005832:	84aa                	mv	s1,a0
    80005834:	c131                	beqz	a0,80005878 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005836:	ffffe097          	auipc	ra,0xffffe
    8000583a:	dea080e7          	jalr	-534(ra) # 80003620 <ilock>
  if(ip->type != T_DIR){
    8000583e:	04449703          	lh	a4,68(s1)
    80005842:	4785                	li	a5,1
    80005844:	04f71063          	bne	a4,a5,80005884 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005848:	8526                	mv	a0,s1
    8000584a:	ffffe097          	auipc	ra,0xffffe
    8000584e:	e98080e7          	jalr	-360(ra) # 800036e2 <iunlock>
  iput(p->cwd);
    80005852:	15093503          	ld	a0,336(s2)
    80005856:	ffffe097          	auipc	ra,0xffffe
    8000585a:	f84080e7          	jalr	-124(ra) # 800037da <iput>
  end_op();
    8000585e:	ffffe097          	auipc	ra,0xffffe
    80005862:	7e2080e7          	jalr	2018(ra) # 80004040 <end_op>
  p->cwd = ip;
    80005866:	14993823          	sd	s1,336(s2)
  return 0;
    8000586a:	4501                	li	a0,0
}
    8000586c:	60ea                	ld	ra,152(sp)
    8000586e:	644a                	ld	s0,144(sp)
    80005870:	64aa                	ld	s1,136(sp)
    80005872:	690a                	ld	s2,128(sp)
    80005874:	610d                	add	sp,sp,160
    80005876:	8082                	ret
    end_op();
    80005878:	ffffe097          	auipc	ra,0xffffe
    8000587c:	7c8080e7          	jalr	1992(ra) # 80004040 <end_op>
    return -1;
    80005880:	557d                	li	a0,-1
    80005882:	b7ed                	j	8000586c <sys_chdir+0x7a>
    iunlockput(ip);
    80005884:	8526                	mv	a0,s1
    80005886:	ffffe097          	auipc	ra,0xffffe
    8000588a:	ffc080e7          	jalr	-4(ra) # 80003882 <iunlockput>
    end_op();
    8000588e:	ffffe097          	auipc	ra,0xffffe
    80005892:	7b2080e7          	jalr	1970(ra) # 80004040 <end_op>
    return -1;
    80005896:	557d                	li	a0,-1
    80005898:	bfd1                	j	8000586c <sys_chdir+0x7a>

000000008000589a <sys_exec>:

uint64
sys_exec(void)
{
    8000589a:	7121                	add	sp,sp,-448
    8000589c:	ff06                	sd	ra,440(sp)
    8000589e:	fb22                	sd	s0,432(sp)
    800058a0:	f726                	sd	s1,424(sp)
    800058a2:	f34a                	sd	s2,416(sp)
    800058a4:	ef4e                	sd	s3,408(sp)
    800058a6:	eb52                	sd	s4,400(sp)
    800058a8:	0380                	add	s0,sp,448
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    800058aa:	e4840593          	add	a1,s0,-440
    800058ae:	4505                	li	a0,1
    800058b0:	ffffd097          	auipc	ra,0xffffd
    800058b4:	22e080e7          	jalr	558(ra) # 80002ade <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    800058b8:	08000613          	li	a2,128
    800058bc:	f5040593          	add	a1,s0,-176
    800058c0:	4501                	li	a0,0
    800058c2:	ffffd097          	auipc	ra,0xffffd
    800058c6:	23c080e7          	jalr	572(ra) # 80002afe <argstr>
    800058ca:	87aa                	mv	a5,a0
    return -1;
    800058cc:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    800058ce:	0c07c263          	bltz	a5,80005992 <sys_exec+0xf8>
  }
  memset(argv, 0, sizeof(argv));
    800058d2:	10000613          	li	a2,256
    800058d6:	4581                	li	a1,0
    800058d8:	e5040513          	add	a0,s0,-432
    800058dc:	ffffb097          	auipc	ra,0xffffb
    800058e0:	3f0080e7          	jalr	1008(ra) # 80000ccc <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800058e4:	e5040493          	add	s1,s0,-432
  memset(argv, 0, sizeof(argv));
    800058e8:	89a6                	mv	s3,s1
    800058ea:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800058ec:	02000a13          	li	s4,32
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800058f0:	00391513          	sll	a0,s2,0x3
    800058f4:	e4040593          	add	a1,s0,-448
    800058f8:	e4843783          	ld	a5,-440(s0)
    800058fc:	953e                	add	a0,a0,a5
    800058fe:	ffffd097          	auipc	ra,0xffffd
    80005902:	122080e7          	jalr	290(ra) # 80002a20 <fetchaddr>
    80005906:	02054a63          	bltz	a0,8000593a <sys_exec+0xa0>
      goto bad;
    }
    if(uarg == 0){
    8000590a:	e4043783          	ld	a5,-448(s0)
    8000590e:	c3b9                	beqz	a5,80005954 <sys_exec+0xba>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005910:	ffffb097          	auipc	ra,0xffffb
    80005914:	1d0080e7          	jalr	464(ra) # 80000ae0 <kalloc>
    80005918:	85aa                	mv	a1,a0
    8000591a:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    8000591e:	cd11                	beqz	a0,8000593a <sys_exec+0xa0>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005920:	6605                	lui	a2,0x1
    80005922:	e4043503          	ld	a0,-448(s0)
    80005926:	ffffd097          	auipc	ra,0xffffd
    8000592a:	14c080e7          	jalr	332(ra) # 80002a72 <fetchstr>
    8000592e:	00054663          	bltz	a0,8000593a <sys_exec+0xa0>
    if(i >= NELEM(argv)){
    80005932:	0905                	add	s2,s2,1
    80005934:	09a1                	add	s3,s3,8
    80005936:	fb491de3          	bne	s2,s4,800058f0 <sys_exec+0x56>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000593a:	f5040913          	add	s2,s0,-176
    8000593e:	6088                	ld	a0,0(s1)
    80005940:	c921                	beqz	a0,80005990 <sys_exec+0xf6>
    kfree(argv[i]);
    80005942:	ffffb097          	auipc	ra,0xffffb
    80005946:	0a0080e7          	jalr	160(ra) # 800009e2 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000594a:	04a1                	add	s1,s1,8
    8000594c:	ff2499e3          	bne	s1,s2,8000593e <sys_exec+0xa4>
  return -1;
    80005950:	557d                	li	a0,-1
    80005952:	a081                	j	80005992 <sys_exec+0xf8>
      argv[i] = 0;
    80005954:	0009079b          	sext.w	a5,s2
    80005958:	078e                	sll	a5,a5,0x3
    8000595a:	fd078793          	add	a5,a5,-48
    8000595e:	97a2                	add	a5,a5,s0
    80005960:	e807b023          	sd	zero,-384(a5)
  int ret = exec(path, argv);
    80005964:	e5040593          	add	a1,s0,-432
    80005968:	f5040513          	add	a0,s0,-176
    8000596c:	fffff097          	auipc	ra,0xfffff
    80005970:	194080e7          	jalr	404(ra) # 80004b00 <exec>
    80005974:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005976:	f5040993          	add	s3,s0,-176
    8000597a:	6088                	ld	a0,0(s1)
    8000597c:	c901                	beqz	a0,8000598c <sys_exec+0xf2>
    kfree(argv[i]);
    8000597e:	ffffb097          	auipc	ra,0xffffb
    80005982:	064080e7          	jalr	100(ra) # 800009e2 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005986:	04a1                	add	s1,s1,8
    80005988:	ff3499e3          	bne	s1,s3,8000597a <sys_exec+0xe0>
  return ret;
    8000598c:	854a                	mv	a0,s2
    8000598e:	a011                	j	80005992 <sys_exec+0xf8>
  return -1;
    80005990:	557d                	li	a0,-1
}
    80005992:	70fa                	ld	ra,440(sp)
    80005994:	745a                	ld	s0,432(sp)
    80005996:	74ba                	ld	s1,424(sp)
    80005998:	791a                	ld	s2,416(sp)
    8000599a:	69fa                	ld	s3,408(sp)
    8000599c:	6a5a                	ld	s4,400(sp)
    8000599e:	6139                	add	sp,sp,448
    800059a0:	8082                	ret

00000000800059a2 <sys_pipe>:

uint64
sys_pipe(void)
{
    800059a2:	7139                	add	sp,sp,-64
    800059a4:	fc06                	sd	ra,56(sp)
    800059a6:	f822                	sd	s0,48(sp)
    800059a8:	f426                	sd	s1,40(sp)
    800059aa:	0080                	add	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800059ac:	ffffc097          	auipc	ra,0xffffc
    800059b0:	ff8080e7          	jalr	-8(ra) # 800019a4 <myproc>
    800059b4:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    800059b6:	fd840593          	add	a1,s0,-40
    800059ba:	4501                	li	a0,0
    800059bc:	ffffd097          	auipc	ra,0xffffd
    800059c0:	122080e7          	jalr	290(ra) # 80002ade <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    800059c4:	fc840593          	add	a1,s0,-56
    800059c8:	fd040513          	add	a0,s0,-48
    800059cc:	fffff097          	auipc	ra,0xfffff
    800059d0:	dea080e7          	jalr	-534(ra) # 800047b6 <pipealloc>
    return -1;
    800059d4:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800059d6:	0c054463          	bltz	a0,80005a9e <sys_pipe+0xfc>
  fd0 = -1;
    800059da:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800059de:	fd043503          	ld	a0,-48(s0)
    800059e2:	fffff097          	auipc	ra,0xfffff
    800059e6:	524080e7          	jalr	1316(ra) # 80004f06 <fdalloc>
    800059ea:	fca42223          	sw	a0,-60(s0)
    800059ee:	08054b63          	bltz	a0,80005a84 <sys_pipe+0xe2>
    800059f2:	fc843503          	ld	a0,-56(s0)
    800059f6:	fffff097          	auipc	ra,0xfffff
    800059fa:	510080e7          	jalr	1296(ra) # 80004f06 <fdalloc>
    800059fe:	fca42023          	sw	a0,-64(s0)
    80005a02:	06054863          	bltz	a0,80005a72 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005a06:	4691                	li	a3,4
    80005a08:	fc440613          	add	a2,s0,-60
    80005a0c:	fd843583          	ld	a1,-40(s0)
    80005a10:	68a8                	ld	a0,80(s1)
    80005a12:	ffffc097          	auipc	ra,0xffffc
    80005a16:	c52080e7          	jalr	-942(ra) # 80001664 <copyout>
    80005a1a:	02054063          	bltz	a0,80005a3a <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005a1e:	4691                	li	a3,4
    80005a20:	fc040613          	add	a2,s0,-64
    80005a24:	fd843583          	ld	a1,-40(s0)
    80005a28:	0591                	add	a1,a1,4
    80005a2a:	68a8                	ld	a0,80(s1)
    80005a2c:	ffffc097          	auipc	ra,0xffffc
    80005a30:	c38080e7          	jalr	-968(ra) # 80001664 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005a34:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005a36:	06055463          	bgez	a0,80005a9e <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005a3a:	fc442783          	lw	a5,-60(s0)
    80005a3e:	07e9                	add	a5,a5,26
    80005a40:	078e                	sll	a5,a5,0x3
    80005a42:	97a6                	add	a5,a5,s1
    80005a44:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005a48:	fc042783          	lw	a5,-64(s0)
    80005a4c:	07e9                	add	a5,a5,26
    80005a4e:	078e                	sll	a5,a5,0x3
    80005a50:	94be                	add	s1,s1,a5
    80005a52:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005a56:	fd043503          	ld	a0,-48(s0)
    80005a5a:	fffff097          	auipc	ra,0xfffff
    80005a5e:	a30080e7          	jalr	-1488(ra) # 8000448a <fileclose>
    fileclose(wf);
    80005a62:	fc843503          	ld	a0,-56(s0)
    80005a66:	fffff097          	auipc	ra,0xfffff
    80005a6a:	a24080e7          	jalr	-1500(ra) # 8000448a <fileclose>
    return -1;
    80005a6e:	57fd                	li	a5,-1
    80005a70:	a03d                	j	80005a9e <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005a72:	fc442783          	lw	a5,-60(s0)
    80005a76:	0007c763          	bltz	a5,80005a84 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005a7a:	07e9                	add	a5,a5,26
    80005a7c:	078e                	sll	a5,a5,0x3
    80005a7e:	97a6                	add	a5,a5,s1
    80005a80:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005a84:	fd043503          	ld	a0,-48(s0)
    80005a88:	fffff097          	auipc	ra,0xfffff
    80005a8c:	a02080e7          	jalr	-1534(ra) # 8000448a <fileclose>
    fileclose(wf);
    80005a90:	fc843503          	ld	a0,-56(s0)
    80005a94:	fffff097          	auipc	ra,0xfffff
    80005a98:	9f6080e7          	jalr	-1546(ra) # 8000448a <fileclose>
    return -1;
    80005a9c:	57fd                	li	a5,-1
}
    80005a9e:	853e                	mv	a0,a5
    80005aa0:	70e2                	ld	ra,56(sp)
    80005aa2:	7442                	ld	s0,48(sp)
    80005aa4:	74a2                	ld	s1,40(sp)
    80005aa6:	6121                	add	sp,sp,64
    80005aa8:	8082                	ret
    80005aaa:	0000                	unimp
    80005aac:	0000                	unimp
	...

0000000080005ab0 <kernelvec>:
    80005ab0:	7111                	add	sp,sp,-256
    80005ab2:	e006                	sd	ra,0(sp)
    80005ab4:	e40a                	sd	sp,8(sp)
    80005ab6:	e80e                	sd	gp,16(sp)
    80005ab8:	ec12                	sd	tp,24(sp)
    80005aba:	f016                	sd	t0,32(sp)
    80005abc:	f41a                	sd	t1,40(sp)
    80005abe:	f81e                	sd	t2,48(sp)
    80005ac0:	fc22                	sd	s0,56(sp)
    80005ac2:	e0a6                	sd	s1,64(sp)
    80005ac4:	e4aa                	sd	a0,72(sp)
    80005ac6:	e8ae                	sd	a1,80(sp)
    80005ac8:	ecb2                	sd	a2,88(sp)
    80005aca:	f0b6                	sd	a3,96(sp)
    80005acc:	f4ba                	sd	a4,104(sp)
    80005ace:	f8be                	sd	a5,112(sp)
    80005ad0:	fcc2                	sd	a6,120(sp)
    80005ad2:	e146                	sd	a7,128(sp)
    80005ad4:	e54a                	sd	s2,136(sp)
    80005ad6:	e94e                	sd	s3,144(sp)
    80005ad8:	ed52                	sd	s4,152(sp)
    80005ada:	f156                	sd	s5,160(sp)
    80005adc:	f55a                	sd	s6,168(sp)
    80005ade:	f95e                	sd	s7,176(sp)
    80005ae0:	fd62                	sd	s8,184(sp)
    80005ae2:	e1e6                	sd	s9,192(sp)
    80005ae4:	e5ea                	sd	s10,200(sp)
    80005ae6:	e9ee                	sd	s11,208(sp)
    80005ae8:	edf2                	sd	t3,216(sp)
    80005aea:	f1f6                	sd	t4,224(sp)
    80005aec:	f5fa                	sd	t5,232(sp)
    80005aee:	f9fe                	sd	t6,240(sp)
    80005af0:	dfdfc0ef          	jal	800028ec <kerneltrap>
    80005af4:	6082                	ld	ra,0(sp)
    80005af6:	6122                	ld	sp,8(sp)
    80005af8:	61c2                	ld	gp,16(sp)
    80005afa:	7282                	ld	t0,32(sp)
    80005afc:	7322                	ld	t1,40(sp)
    80005afe:	73c2                	ld	t2,48(sp)
    80005b00:	7462                	ld	s0,56(sp)
    80005b02:	6486                	ld	s1,64(sp)
    80005b04:	6526                	ld	a0,72(sp)
    80005b06:	65c6                	ld	a1,80(sp)
    80005b08:	6666                	ld	a2,88(sp)
    80005b0a:	7686                	ld	a3,96(sp)
    80005b0c:	7726                	ld	a4,104(sp)
    80005b0e:	77c6                	ld	a5,112(sp)
    80005b10:	7866                	ld	a6,120(sp)
    80005b12:	688a                	ld	a7,128(sp)
    80005b14:	692a                	ld	s2,136(sp)
    80005b16:	69ca                	ld	s3,144(sp)
    80005b18:	6a6a                	ld	s4,152(sp)
    80005b1a:	7a8a                	ld	s5,160(sp)
    80005b1c:	7b2a                	ld	s6,168(sp)
    80005b1e:	7bca                	ld	s7,176(sp)
    80005b20:	7c6a                	ld	s8,184(sp)
    80005b22:	6c8e                	ld	s9,192(sp)
    80005b24:	6d2e                	ld	s10,200(sp)
    80005b26:	6dce                	ld	s11,208(sp)
    80005b28:	6e6e                	ld	t3,216(sp)
    80005b2a:	7e8e                	ld	t4,224(sp)
    80005b2c:	7f2e                	ld	t5,232(sp)
    80005b2e:	7fce                	ld	t6,240(sp)
    80005b30:	6111                	add	sp,sp,256
    80005b32:	10200073          	sret
    80005b36:	00000013          	nop
    80005b3a:	00000013          	nop
    80005b3e:	0001                	nop

0000000080005b40 <timervec>:
    80005b40:	34051573          	csrrw	a0,mscratch,a0
    80005b44:	e10c                	sd	a1,0(a0)
    80005b46:	e510                	sd	a2,8(a0)
    80005b48:	e914                	sd	a3,16(a0)
    80005b4a:	6d0c                	ld	a1,24(a0)
    80005b4c:	7110                	ld	a2,32(a0)
    80005b4e:	6194                	ld	a3,0(a1)
    80005b50:	96b2                	add	a3,a3,a2
    80005b52:	e194                	sd	a3,0(a1)
    80005b54:	4589                	li	a1,2
    80005b56:	14459073          	csrw	sip,a1
    80005b5a:	6914                	ld	a3,16(a0)
    80005b5c:	6510                	ld	a2,8(a0)
    80005b5e:	610c                	ld	a1,0(a0)
    80005b60:	34051573          	csrrw	a0,mscratch,a0
    80005b64:	30200073          	mret
	...

0000000080005b6a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005b6a:	1141                	add	sp,sp,-16
    80005b6c:	e422                	sd	s0,8(sp)
    80005b6e:	0800                	add	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005b70:	0c0007b7          	lui	a5,0xc000
    80005b74:	4705                	li	a4,1
    80005b76:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005b78:	c3d8                	sw	a4,4(a5)
}
    80005b7a:	6422                	ld	s0,8(sp)
    80005b7c:	0141                	add	sp,sp,16
    80005b7e:	8082                	ret

0000000080005b80 <plicinithart>:

void
plicinithart(void)
{
    80005b80:	1141                	add	sp,sp,-16
    80005b82:	e406                	sd	ra,8(sp)
    80005b84:	e022                	sd	s0,0(sp)
    80005b86:	0800                	add	s0,sp,16
  int hart = cpuid();
    80005b88:	ffffc097          	auipc	ra,0xffffc
    80005b8c:	df0080e7          	jalr	-528(ra) # 80001978 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005b90:	0085171b          	sllw	a4,a0,0x8
    80005b94:	0c0027b7          	lui	a5,0xc002
    80005b98:	97ba                	add	a5,a5,a4
    80005b9a:	40200713          	li	a4,1026
    80005b9e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005ba2:	00d5151b          	sllw	a0,a0,0xd
    80005ba6:	0c2017b7          	lui	a5,0xc201
    80005baa:	97aa                	add	a5,a5,a0
    80005bac:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005bb0:	60a2                	ld	ra,8(sp)
    80005bb2:	6402                	ld	s0,0(sp)
    80005bb4:	0141                	add	sp,sp,16
    80005bb6:	8082                	ret

0000000080005bb8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005bb8:	1141                	add	sp,sp,-16
    80005bba:	e406                	sd	ra,8(sp)
    80005bbc:	e022                	sd	s0,0(sp)
    80005bbe:	0800                	add	s0,sp,16
  int hart = cpuid();
    80005bc0:	ffffc097          	auipc	ra,0xffffc
    80005bc4:	db8080e7          	jalr	-584(ra) # 80001978 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005bc8:	00d5151b          	sllw	a0,a0,0xd
    80005bcc:	0c2017b7          	lui	a5,0xc201
    80005bd0:	97aa                	add	a5,a5,a0
  return irq;
}
    80005bd2:	43c8                	lw	a0,4(a5)
    80005bd4:	60a2                	ld	ra,8(sp)
    80005bd6:	6402                	ld	s0,0(sp)
    80005bd8:	0141                	add	sp,sp,16
    80005bda:	8082                	ret

0000000080005bdc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005bdc:	1101                	add	sp,sp,-32
    80005bde:	ec06                	sd	ra,24(sp)
    80005be0:	e822                	sd	s0,16(sp)
    80005be2:	e426                	sd	s1,8(sp)
    80005be4:	1000                	add	s0,sp,32
    80005be6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005be8:	ffffc097          	auipc	ra,0xffffc
    80005bec:	d90080e7          	jalr	-624(ra) # 80001978 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005bf0:	00d5151b          	sllw	a0,a0,0xd
    80005bf4:	0c2017b7          	lui	a5,0xc201
    80005bf8:	97aa                	add	a5,a5,a0
    80005bfa:	c3c4                	sw	s1,4(a5)
}
    80005bfc:	60e2                	ld	ra,24(sp)
    80005bfe:	6442                	ld	s0,16(sp)
    80005c00:	64a2                	ld	s1,8(sp)
    80005c02:	6105                	add	sp,sp,32
    80005c04:	8082                	ret

0000000080005c06 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005c06:	1141                	add	sp,sp,-16
    80005c08:	e406                	sd	ra,8(sp)
    80005c0a:	e022                	sd	s0,0(sp)
    80005c0c:	0800                	add	s0,sp,16
  if(i >= NUM)
    80005c0e:	479d                	li	a5,7
    80005c10:	04a7cc63          	blt	a5,a0,80005c68 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005c14:	0001c797          	auipc	a5,0x1c
    80005c18:	fec78793          	add	a5,a5,-20 # 80021c00 <disk>
    80005c1c:	97aa                	add	a5,a5,a0
    80005c1e:	0187c783          	lbu	a5,24(a5)
    80005c22:	ebb9                	bnez	a5,80005c78 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005c24:	00451693          	sll	a3,a0,0x4
    80005c28:	0001c797          	auipc	a5,0x1c
    80005c2c:	fd878793          	add	a5,a5,-40 # 80021c00 <disk>
    80005c30:	6398                	ld	a4,0(a5)
    80005c32:	9736                	add	a4,a4,a3
    80005c34:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80005c38:	6398                	ld	a4,0(a5)
    80005c3a:	9736                	add	a4,a4,a3
    80005c3c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005c40:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005c44:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005c48:	97aa                	add	a5,a5,a0
    80005c4a:	4705                	li	a4,1
    80005c4c:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80005c50:	0001c517          	auipc	a0,0x1c
    80005c54:	fc850513          	add	a0,a0,-56 # 80021c18 <disk+0x18>
    80005c58:	ffffc097          	auipc	ra,0xffffc
    80005c5c:	458080e7          	jalr	1112(ra) # 800020b0 <wakeup>
}
    80005c60:	60a2                	ld	ra,8(sp)
    80005c62:	6402                	ld	s0,0(sp)
    80005c64:	0141                	add	sp,sp,16
    80005c66:	8082                	ret
    panic("free_desc 1");
    80005c68:	00003517          	auipc	a0,0x3
    80005c6c:	ad850513          	add	a0,a0,-1320 # 80008740 <syscalls+0x2f0>
    80005c70:	ffffb097          	auipc	ra,0xffffb
    80005c74:	8ca080e7          	jalr	-1846(ra) # 8000053a <panic>
    panic("free_desc 2");
    80005c78:	00003517          	auipc	a0,0x3
    80005c7c:	ad850513          	add	a0,a0,-1320 # 80008750 <syscalls+0x300>
    80005c80:	ffffb097          	auipc	ra,0xffffb
    80005c84:	8ba080e7          	jalr	-1862(ra) # 8000053a <panic>

0000000080005c88 <virtio_disk_init>:
{
    80005c88:	1101                	add	sp,sp,-32
    80005c8a:	ec06                	sd	ra,24(sp)
    80005c8c:	e822                	sd	s0,16(sp)
    80005c8e:	e426                	sd	s1,8(sp)
    80005c90:	e04a                	sd	s2,0(sp)
    80005c92:	1000                	add	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005c94:	00003597          	auipc	a1,0x3
    80005c98:	acc58593          	add	a1,a1,-1332 # 80008760 <syscalls+0x310>
    80005c9c:	0001c517          	auipc	a0,0x1c
    80005ca0:	08c50513          	add	a0,a0,140 # 80021d28 <disk+0x128>
    80005ca4:	ffffb097          	auipc	ra,0xffffb
    80005ca8:	e9c080e7          	jalr	-356(ra) # 80000b40 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005cac:	100017b7          	lui	a5,0x10001
    80005cb0:	4398                	lw	a4,0(a5)
    80005cb2:	2701                	sext.w	a4,a4
    80005cb4:	747277b7          	lui	a5,0x74727
    80005cb8:	97678793          	add	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005cbc:	14f71b63          	bne	a4,a5,80005e12 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005cc0:	100017b7          	lui	a5,0x10001
    80005cc4:	43dc                	lw	a5,4(a5)
    80005cc6:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005cc8:	4709                	li	a4,2
    80005cca:	14e79463          	bne	a5,a4,80005e12 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005cce:	100017b7          	lui	a5,0x10001
    80005cd2:	479c                	lw	a5,8(a5)
    80005cd4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005cd6:	12e79e63          	bne	a5,a4,80005e12 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005cda:	100017b7          	lui	a5,0x10001
    80005cde:	47d8                	lw	a4,12(a5)
    80005ce0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005ce2:	554d47b7          	lui	a5,0x554d4
    80005ce6:	55178793          	add	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005cea:	12f71463          	bne	a4,a5,80005e12 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005cee:	100017b7          	lui	a5,0x10001
    80005cf2:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005cf6:	4705                	li	a4,1
    80005cf8:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005cfa:	470d                	li	a4,3
    80005cfc:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005cfe:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005d00:	c7ffe6b7          	lui	a3,0xc7ffe
    80005d04:	75f68693          	add	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fdca1f>
    80005d08:	8f75                	and	a4,a4,a3
    80005d0a:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005d0c:	472d                	li	a4,11
    80005d0e:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80005d10:	5bbc                	lw	a5,112(a5)
    80005d12:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80005d16:	8ba1                	and	a5,a5,8
    80005d18:	10078563          	beqz	a5,80005e22 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005d1c:	100017b7          	lui	a5,0x10001
    80005d20:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80005d24:	43fc                	lw	a5,68(a5)
    80005d26:	2781                	sext.w	a5,a5
    80005d28:	10079563          	bnez	a5,80005e32 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005d2c:	100017b7          	lui	a5,0x10001
    80005d30:	5bdc                	lw	a5,52(a5)
    80005d32:	2781                	sext.w	a5,a5
  if(max == 0)
    80005d34:	10078763          	beqz	a5,80005e42 <virtio_disk_init+0x1ba>
  if(max < NUM)
    80005d38:	471d                	li	a4,7
    80005d3a:	10f77c63          	bgeu	a4,a5,80005e52 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    80005d3e:	ffffb097          	auipc	ra,0xffffb
    80005d42:	da2080e7          	jalr	-606(ra) # 80000ae0 <kalloc>
    80005d46:	0001c497          	auipc	s1,0x1c
    80005d4a:	eba48493          	add	s1,s1,-326 # 80021c00 <disk>
    80005d4e:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80005d50:	ffffb097          	auipc	ra,0xffffb
    80005d54:	d90080e7          	jalr	-624(ra) # 80000ae0 <kalloc>
    80005d58:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    80005d5a:	ffffb097          	auipc	ra,0xffffb
    80005d5e:	d86080e7          	jalr	-634(ra) # 80000ae0 <kalloc>
    80005d62:	87aa                	mv	a5,a0
    80005d64:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80005d66:	6088                	ld	a0,0(s1)
    80005d68:	cd6d                	beqz	a0,80005e62 <virtio_disk_init+0x1da>
    80005d6a:	0001c717          	auipc	a4,0x1c
    80005d6e:	e9e73703          	ld	a4,-354(a4) # 80021c08 <disk+0x8>
    80005d72:	cb65                	beqz	a4,80005e62 <virtio_disk_init+0x1da>
    80005d74:	c7fd                	beqz	a5,80005e62 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    80005d76:	6605                	lui	a2,0x1
    80005d78:	4581                	li	a1,0
    80005d7a:	ffffb097          	auipc	ra,0xffffb
    80005d7e:	f52080e7          	jalr	-174(ra) # 80000ccc <memset>
  memset(disk.avail, 0, PGSIZE);
    80005d82:	0001c497          	auipc	s1,0x1c
    80005d86:	e7e48493          	add	s1,s1,-386 # 80021c00 <disk>
    80005d8a:	6605                	lui	a2,0x1
    80005d8c:	4581                	li	a1,0
    80005d8e:	6488                	ld	a0,8(s1)
    80005d90:	ffffb097          	auipc	ra,0xffffb
    80005d94:	f3c080e7          	jalr	-196(ra) # 80000ccc <memset>
  memset(disk.used, 0, PGSIZE);
    80005d98:	6605                	lui	a2,0x1
    80005d9a:	4581                	li	a1,0
    80005d9c:	6888                	ld	a0,16(s1)
    80005d9e:	ffffb097          	auipc	ra,0xffffb
    80005da2:	f2e080e7          	jalr	-210(ra) # 80000ccc <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005da6:	100017b7          	lui	a5,0x10001
    80005daa:	4721                	li	a4,8
    80005dac:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80005dae:	4098                	lw	a4,0(s1)
    80005db0:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80005db4:	40d8                	lw	a4,4(s1)
    80005db6:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    80005dba:	6498                	ld	a4,8(s1)
    80005dbc:	0007069b          	sext.w	a3,a4
    80005dc0:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80005dc4:	9701                	sra	a4,a4,0x20
    80005dc6:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    80005dca:	6898                	ld	a4,16(s1)
    80005dcc:	0007069b          	sext.w	a3,a4
    80005dd0:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80005dd4:	9701                	sra	a4,a4,0x20
    80005dd6:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    80005dda:	4705                	li	a4,1
    80005ddc:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80005dde:	00e48c23          	sb	a4,24(s1)
    80005de2:	00e48ca3          	sb	a4,25(s1)
    80005de6:	00e48d23          	sb	a4,26(s1)
    80005dea:	00e48da3          	sb	a4,27(s1)
    80005dee:	00e48e23          	sb	a4,28(s1)
    80005df2:	00e48ea3          	sb	a4,29(s1)
    80005df6:	00e48f23          	sb	a4,30(s1)
    80005dfa:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80005dfe:	00496913          	or	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e02:	0727a823          	sw	s2,112(a5)
}
    80005e06:	60e2                	ld	ra,24(sp)
    80005e08:	6442                	ld	s0,16(sp)
    80005e0a:	64a2                	ld	s1,8(sp)
    80005e0c:	6902                	ld	s2,0(sp)
    80005e0e:	6105                	add	sp,sp,32
    80005e10:	8082                	ret
    panic("could not find virtio disk");
    80005e12:	00003517          	auipc	a0,0x3
    80005e16:	95e50513          	add	a0,a0,-1698 # 80008770 <syscalls+0x320>
    80005e1a:	ffffa097          	auipc	ra,0xffffa
    80005e1e:	720080e7          	jalr	1824(ra) # 8000053a <panic>
    panic("virtio disk FEATURES_OK unset");
    80005e22:	00003517          	auipc	a0,0x3
    80005e26:	96e50513          	add	a0,a0,-1682 # 80008790 <syscalls+0x340>
    80005e2a:	ffffa097          	auipc	ra,0xffffa
    80005e2e:	710080e7          	jalr	1808(ra) # 8000053a <panic>
    panic("virtio disk should not be ready");
    80005e32:	00003517          	auipc	a0,0x3
    80005e36:	97e50513          	add	a0,a0,-1666 # 800087b0 <syscalls+0x360>
    80005e3a:	ffffa097          	auipc	ra,0xffffa
    80005e3e:	700080e7          	jalr	1792(ra) # 8000053a <panic>
    panic("virtio disk has no queue 0");
    80005e42:	00003517          	auipc	a0,0x3
    80005e46:	98e50513          	add	a0,a0,-1650 # 800087d0 <syscalls+0x380>
    80005e4a:	ffffa097          	auipc	ra,0xffffa
    80005e4e:	6f0080e7          	jalr	1776(ra) # 8000053a <panic>
    panic("virtio disk max queue too short");
    80005e52:	00003517          	auipc	a0,0x3
    80005e56:	99e50513          	add	a0,a0,-1634 # 800087f0 <syscalls+0x3a0>
    80005e5a:	ffffa097          	auipc	ra,0xffffa
    80005e5e:	6e0080e7          	jalr	1760(ra) # 8000053a <panic>
    panic("virtio disk kalloc");
    80005e62:	00003517          	auipc	a0,0x3
    80005e66:	9ae50513          	add	a0,a0,-1618 # 80008810 <syscalls+0x3c0>
    80005e6a:	ffffa097          	auipc	ra,0xffffa
    80005e6e:	6d0080e7          	jalr	1744(ra) # 8000053a <panic>

0000000080005e72 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005e72:	7159                	add	sp,sp,-112
    80005e74:	f486                	sd	ra,104(sp)
    80005e76:	f0a2                	sd	s0,96(sp)
    80005e78:	eca6                	sd	s1,88(sp)
    80005e7a:	e8ca                	sd	s2,80(sp)
    80005e7c:	e4ce                	sd	s3,72(sp)
    80005e7e:	e0d2                	sd	s4,64(sp)
    80005e80:	fc56                	sd	s5,56(sp)
    80005e82:	f85a                	sd	s6,48(sp)
    80005e84:	f45e                	sd	s7,40(sp)
    80005e86:	f062                	sd	s8,32(sp)
    80005e88:	ec66                	sd	s9,24(sp)
    80005e8a:	e86a                	sd	s10,16(sp)
    80005e8c:	1880                	add	s0,sp,112
    80005e8e:	8a2a                	mv	s4,a0
    80005e90:	8bae                	mv	s7,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005e92:	00c52c83          	lw	s9,12(a0)
    80005e96:	001c9c9b          	sllw	s9,s9,0x1
    80005e9a:	1c82                	sll	s9,s9,0x20
    80005e9c:	020cdc93          	srl	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005ea0:	0001c517          	auipc	a0,0x1c
    80005ea4:	e8850513          	add	a0,a0,-376 # 80021d28 <disk+0x128>
    80005ea8:	ffffb097          	auipc	ra,0xffffb
    80005eac:	d28080e7          	jalr	-728(ra) # 80000bd0 <acquire>
  for(int i = 0; i < 3; i++){
    80005eb0:	4901                	li	s2,0
  for(int i = 0; i < NUM; i++){
    80005eb2:	44a1                	li	s1,8
      disk.free[i] = 0;
    80005eb4:	0001cb17          	auipc	s6,0x1c
    80005eb8:	d4cb0b13          	add	s6,s6,-692 # 80021c00 <disk>
  for(int i = 0; i < 3; i++){
    80005ebc:	4a8d                	li	s5,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005ebe:	0001cc17          	auipc	s8,0x1c
    80005ec2:	e6ac0c13          	add	s8,s8,-406 # 80021d28 <disk+0x128>
    80005ec6:	a095                	j	80005f2a <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    80005ec8:	00fb0733          	add	a4,s6,a5
    80005ecc:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80005ed0:	c11c                	sw	a5,0(a0)
    if(idx[i] < 0){
    80005ed2:	0207c563          	bltz	a5,80005efc <virtio_disk_rw+0x8a>
  for(int i = 0; i < 3; i++){
    80005ed6:	2605                	addw	a2,a2,1 # 1001 <_entry-0x7fffefff>
    80005ed8:	0591                	add	a1,a1,4
    80005eda:	05560d63          	beq	a2,s5,80005f34 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80005ede:	852e                	mv	a0,a1
  for(int i = 0; i < NUM; i++){
    80005ee0:	0001c717          	auipc	a4,0x1c
    80005ee4:	d2070713          	add	a4,a4,-736 # 80021c00 <disk>
    80005ee8:	87ca                	mv	a5,s2
    if(disk.free[i]){
    80005eea:	01874683          	lbu	a3,24(a4)
    80005eee:	fee9                	bnez	a3,80005ec8 <virtio_disk_rw+0x56>
  for(int i = 0; i < NUM; i++){
    80005ef0:	2785                	addw	a5,a5,1
    80005ef2:	0705                	add	a4,a4,1
    80005ef4:	fe979be3          	bne	a5,s1,80005eea <virtio_disk_rw+0x78>
    idx[i] = alloc_desc();
    80005ef8:	57fd                	li	a5,-1
    80005efa:	c11c                	sw	a5,0(a0)
      for(int j = 0; j < i; j++)
    80005efc:	00c05e63          	blez	a2,80005f18 <virtio_disk_rw+0xa6>
    80005f00:	060a                	sll	a2,a2,0x2
    80005f02:	01360d33          	add	s10,a2,s3
        free_desc(idx[j]);
    80005f06:	0009a503          	lw	a0,0(s3)
    80005f0a:	00000097          	auipc	ra,0x0
    80005f0e:	cfc080e7          	jalr	-772(ra) # 80005c06 <free_desc>
      for(int j = 0; j < i; j++)
    80005f12:	0991                	add	s3,s3,4
    80005f14:	ffa999e3          	bne	s3,s10,80005f06 <virtio_disk_rw+0x94>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005f18:	85e2                	mv	a1,s8
    80005f1a:	0001c517          	auipc	a0,0x1c
    80005f1e:	cfe50513          	add	a0,a0,-770 # 80021c18 <disk+0x18>
    80005f22:	ffffc097          	auipc	ra,0xffffc
    80005f26:	12a080e7          	jalr	298(ra) # 8000204c <sleep>
  for(int i = 0; i < 3; i++){
    80005f2a:	f9040993          	add	s3,s0,-112
{
    80005f2e:	85ce                	mv	a1,s3
  for(int i = 0; i < 3; i++){
    80005f30:	864a                	mv	a2,s2
    80005f32:	b775                	j	80005ede <virtio_disk_rw+0x6c>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80005f34:	f9042503          	lw	a0,-112(s0)
    80005f38:	00a50713          	add	a4,a0,10
    80005f3c:	0712                	sll	a4,a4,0x4

  if(write)
    80005f3e:	0001c797          	auipc	a5,0x1c
    80005f42:	cc278793          	add	a5,a5,-830 # 80021c00 <disk>
    80005f46:	00e786b3          	add	a3,a5,a4
    80005f4a:	01703633          	snez	a2,s7
    80005f4e:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80005f50:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    80005f54:	0196b823          	sd	s9,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80005f58:	f6070613          	add	a2,a4,-160
    80005f5c:	6394                	ld	a3,0(a5)
    80005f5e:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80005f60:	00870593          	add	a1,a4,8
    80005f64:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80005f66:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80005f68:	0007b803          	ld	a6,0(a5)
    80005f6c:	9642                	add	a2,a2,a6
    80005f6e:	46c1                	li	a3,16
    80005f70:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80005f72:	4585                	li	a1,1
    80005f74:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    80005f78:	f9442683          	lw	a3,-108(s0)
    80005f7c:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80005f80:	0692                	sll	a3,a3,0x4
    80005f82:	9836                	add	a6,a6,a3
    80005f84:	058a0613          	add	a2,s4,88
    80005f88:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    80005f8c:	0007b803          	ld	a6,0(a5)
    80005f90:	96c2                	add	a3,a3,a6
    80005f92:	40000613          	li	a2,1024
    80005f96:	c690                	sw	a2,8(a3)
  if(write)
    80005f98:	001bb613          	seqz	a2,s7
    80005f9c:	0016161b          	sllw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80005fa0:	00166613          	or	a2,a2,1
    80005fa4:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80005fa8:	f9842603          	lw	a2,-104(s0)
    80005fac:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80005fb0:	00250693          	add	a3,a0,2
    80005fb4:	0692                	sll	a3,a3,0x4
    80005fb6:	96be                	add	a3,a3,a5
    80005fb8:	58fd                	li	a7,-1
    80005fba:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80005fbe:	0612                	sll	a2,a2,0x4
    80005fc0:	9832                	add	a6,a6,a2
    80005fc2:	f9070713          	add	a4,a4,-112
    80005fc6:	973e                	add	a4,a4,a5
    80005fc8:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    80005fcc:	6398                	ld	a4,0(a5)
    80005fce:	9732                	add	a4,a4,a2
    80005fd0:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80005fd2:	4609                	li	a2,2
    80005fd4:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    80005fd8:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80005fdc:	00ba2223          	sw	a1,4(s4)
  disk.info[idx[0]].b = b;
    80005fe0:	0146b423          	sd	s4,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80005fe4:	6794                	ld	a3,8(a5)
    80005fe6:	0026d703          	lhu	a4,2(a3)
    80005fea:	8b1d                	and	a4,a4,7
    80005fec:	0706                	sll	a4,a4,0x1
    80005fee:	96ba                	add	a3,a3,a4
    80005ff0:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80005ff4:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80005ff8:	6798                	ld	a4,8(a5)
    80005ffa:	00275783          	lhu	a5,2(a4)
    80005ffe:	2785                	addw	a5,a5,1
    80006000:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006004:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006008:	100017b7          	lui	a5,0x10001
    8000600c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006010:	004a2783          	lw	a5,4(s4)
    sleep(b, &disk.vdisk_lock);
    80006014:	0001c917          	auipc	s2,0x1c
    80006018:	d1490913          	add	s2,s2,-748 # 80021d28 <disk+0x128>
  while(b->disk == 1) {
    8000601c:	4485                	li	s1,1
    8000601e:	00b79c63          	bne	a5,a1,80006036 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006022:	85ca                	mv	a1,s2
    80006024:	8552                	mv	a0,s4
    80006026:	ffffc097          	auipc	ra,0xffffc
    8000602a:	026080e7          	jalr	38(ra) # 8000204c <sleep>
  while(b->disk == 1) {
    8000602e:	004a2783          	lw	a5,4(s4)
    80006032:	fe9788e3          	beq	a5,s1,80006022 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006036:	f9042903          	lw	s2,-112(s0)
    8000603a:	00290713          	add	a4,s2,2
    8000603e:	0712                	sll	a4,a4,0x4
    80006040:	0001c797          	auipc	a5,0x1c
    80006044:	bc078793          	add	a5,a5,-1088 # 80021c00 <disk>
    80006048:	97ba                	add	a5,a5,a4
    8000604a:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000604e:	0001c997          	auipc	s3,0x1c
    80006052:	bb298993          	add	s3,s3,-1102 # 80021c00 <disk>
    80006056:	00491713          	sll	a4,s2,0x4
    8000605a:	0009b783          	ld	a5,0(s3)
    8000605e:	97ba                	add	a5,a5,a4
    80006060:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006064:	854a                	mv	a0,s2
    80006066:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000606a:	00000097          	auipc	ra,0x0
    8000606e:	b9c080e7          	jalr	-1124(ra) # 80005c06 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006072:	8885                	and	s1,s1,1
    80006074:	f0ed                	bnez	s1,80006056 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006076:	0001c517          	auipc	a0,0x1c
    8000607a:	cb250513          	add	a0,a0,-846 # 80021d28 <disk+0x128>
    8000607e:	ffffb097          	auipc	ra,0xffffb
    80006082:	c06080e7          	jalr	-1018(ra) # 80000c84 <release>
}
    80006086:	70a6                	ld	ra,104(sp)
    80006088:	7406                	ld	s0,96(sp)
    8000608a:	64e6                	ld	s1,88(sp)
    8000608c:	6946                	ld	s2,80(sp)
    8000608e:	69a6                	ld	s3,72(sp)
    80006090:	6a06                	ld	s4,64(sp)
    80006092:	7ae2                	ld	s5,56(sp)
    80006094:	7b42                	ld	s6,48(sp)
    80006096:	7ba2                	ld	s7,40(sp)
    80006098:	7c02                	ld	s8,32(sp)
    8000609a:	6ce2                	ld	s9,24(sp)
    8000609c:	6d42                	ld	s10,16(sp)
    8000609e:	6165                	add	sp,sp,112
    800060a0:	8082                	ret

00000000800060a2 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800060a2:	1101                	add	sp,sp,-32
    800060a4:	ec06                	sd	ra,24(sp)
    800060a6:	e822                	sd	s0,16(sp)
    800060a8:	e426                	sd	s1,8(sp)
    800060aa:	1000                	add	s0,sp,32
  acquire(&disk.vdisk_lock);
    800060ac:	0001c497          	auipc	s1,0x1c
    800060b0:	b5448493          	add	s1,s1,-1196 # 80021c00 <disk>
    800060b4:	0001c517          	auipc	a0,0x1c
    800060b8:	c7450513          	add	a0,a0,-908 # 80021d28 <disk+0x128>
    800060bc:	ffffb097          	auipc	ra,0xffffb
    800060c0:	b14080e7          	jalr	-1260(ra) # 80000bd0 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800060c4:	10001737          	lui	a4,0x10001
    800060c8:	533c                	lw	a5,96(a4)
    800060ca:	8b8d                	and	a5,a5,3
    800060cc:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800060ce:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800060d2:	689c                	ld	a5,16(s1)
    800060d4:	0204d703          	lhu	a4,32(s1)
    800060d8:	0027d783          	lhu	a5,2(a5)
    800060dc:	04f70863          	beq	a4,a5,8000612c <virtio_disk_intr+0x8a>
    __sync_synchronize();
    800060e0:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800060e4:	6898                	ld	a4,16(s1)
    800060e6:	0204d783          	lhu	a5,32(s1)
    800060ea:	8b9d                	and	a5,a5,7
    800060ec:	078e                	sll	a5,a5,0x3
    800060ee:	97ba                	add	a5,a5,a4
    800060f0:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800060f2:	00278713          	add	a4,a5,2
    800060f6:	0712                	sll	a4,a4,0x4
    800060f8:	9726                	add	a4,a4,s1
    800060fa:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    800060fe:	e721                	bnez	a4,80006146 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006100:	0789                	add	a5,a5,2
    80006102:	0792                	sll	a5,a5,0x4
    80006104:	97a6                	add	a5,a5,s1
    80006106:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    80006108:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000610c:	ffffc097          	auipc	ra,0xffffc
    80006110:	fa4080e7          	jalr	-92(ra) # 800020b0 <wakeup>

    disk.used_idx += 1;
    80006114:	0204d783          	lhu	a5,32(s1)
    80006118:	2785                	addw	a5,a5,1
    8000611a:	17c2                	sll	a5,a5,0x30
    8000611c:	93c1                	srl	a5,a5,0x30
    8000611e:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006122:	6898                	ld	a4,16(s1)
    80006124:	00275703          	lhu	a4,2(a4)
    80006128:	faf71ce3          	bne	a4,a5,800060e0 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    8000612c:	0001c517          	auipc	a0,0x1c
    80006130:	bfc50513          	add	a0,a0,-1028 # 80021d28 <disk+0x128>
    80006134:	ffffb097          	auipc	ra,0xffffb
    80006138:	b50080e7          	jalr	-1200(ra) # 80000c84 <release>
}
    8000613c:	60e2                	ld	ra,24(sp)
    8000613e:	6442                	ld	s0,16(sp)
    80006140:	64a2                	ld	s1,8(sp)
    80006142:	6105                	add	sp,sp,32
    80006144:	8082                	ret
      panic("virtio_disk_intr status");
    80006146:	00002517          	auipc	a0,0x2
    8000614a:	6e250513          	add	a0,a0,1762 # 80008828 <syscalls+0x3d8>
    8000614e:	ffffa097          	auipc	ra,0xffffa
    80006152:	3ec080e7          	jalr	1004(ra) # 8000053a <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000700a:	0536                	sll	a0,a0,0xd
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
    800070ac:	357d                	addw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800070ae:	0536                	sll	a0,a0,0xd
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
