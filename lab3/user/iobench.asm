
user/_iobench:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <io_ops>:
static char data[IO_OPSIZE];


int
io_ops()
{
   0:	7139                	add	sp,sp,-64
   2:	fc06                	sd	ra,56(sp)
   4:	f822                	sd	s0,48(sp)
   6:	f426                	sd	s1,40(sp)
   8:	f04a                	sd	s2,32(sp)
   a:	ec4e                	sd	s3,24(sp)
   c:	0080                	add	s0,sp,64
    int rfd, wfd;

    int pid = getpid();
   e:	00000097          	auipc	ra,0x0
  12:	4cc080e7          	jalr	1228(ra) # 4da <getpid>

    // Crear un path unico de archivo
    char path[] = "12iops";
  16:	6f6937b7          	lui	a5,0x6f693
  1a:	23178793          	add	a5,a5,561 # 6f693231 <base+0x6f6921e1>
  1e:	fcf42423          	sw	a5,-56(s0)
  22:	679d                	lui	a5,0x7
  24:	37078793          	add	a5,a5,880 # 7370 <base+0x6320>
  28:	fcf41623          	sh	a5,-52(s0)
  2c:	fc040723          	sb	zero,-50(s0)
    path[0] = '0' + (pid / 10);
  30:	4729                	li	a4,10
  32:	02e547bb          	divw	a5,a0,a4
  36:	0307879b          	addw	a5,a5,48
  3a:	fcf40423          	sb	a5,-56(s0)
    path[1] = '0' + (pid % 10);
  3e:	02e567bb          	remw	a5,a0,a4
  42:	0307879b          	addw	a5,a5,48
  46:	fcf404a3          	sb	a5,-55(s0)

    wfd = open(path, O_CREATE | O_WRONLY);
  4a:	20100593          	li	a1,513
  4e:	fc840513          	add	a0,s0,-56
  52:	00000097          	auipc	ra,0x0
  56:	448080e7          	jalr	1096(ra) # 49a <open>
  5a:	892a                	mv	s2,a0
  5c:	20000493          	li	s1,512

    for(int i = 0; i < IO_EXPERIMENT_LEN; ++i){
      write(wfd, data, IO_OPSIZE);
  60:	00001997          	auipc	s3,0x1
  64:	fb098993          	add	s3,s3,-80 # 1010 <data>
  68:	04000613          	li	a2,64
  6c:	85ce                	mv	a1,s3
  6e:	854a                	mv	a0,s2
  70:	00000097          	auipc	ra,0x0
  74:	40a080e7          	jalr	1034(ra) # 47a <write>
    for(int i = 0; i < IO_EXPERIMENT_LEN; ++i){
  78:	34fd                	addw	s1,s1,-1
  7a:	f4fd                	bnez	s1,68 <io_ops+0x68>
    }

    close(wfd);
  7c:	854a                	mv	a0,s2
  7e:	00000097          	auipc	ra,0x0
  82:	404080e7          	jalr	1028(ra) # 482 <close>

    rfd = open(path, O_RDONLY);
  86:	4581                	li	a1,0
  88:	fc840513          	add	a0,s0,-56
  8c:	00000097          	auipc	ra,0x0
  90:	40e080e7          	jalr	1038(ra) # 49a <open>
  94:	892a                	mv	s2,a0
  96:	20000493          	li	s1,512

    for(int i = 0; i < IO_EXPERIMENT_LEN; ++i){
      read(rfd, data, IO_OPSIZE);
  9a:	00001997          	auipc	s3,0x1
  9e:	f7698993          	add	s3,s3,-138 # 1010 <data>
  a2:	04000613          	li	a2,64
  a6:	85ce                	mv	a1,s3
  a8:	854a                	mv	a0,s2
  aa:	00000097          	auipc	ra,0x0
  ae:	3c8080e7          	jalr	968(ra) # 472 <read>
    for(int i = 0; i < IO_EXPERIMENT_LEN; ++i){
  b2:	34fd                	addw	s1,s1,-1
  b4:	f4fd                	bnez	s1,a2 <io_ops+0xa2>
    }

    close(rfd);
  b6:	854a                	mv	a0,s2
  b8:	00000097          	auipc	ra,0x0
  bc:	3ca080e7          	jalr	970(ra) # 482 <close>
    return 2 * IO_EXPERIMENT_LEN;
}
  c0:	40000513          	li	a0,1024
  c4:	70e2                	ld	ra,56(sp)
  c6:	7442                	ld	s0,48(sp)
  c8:	74a2                	ld	s1,40(sp)
  ca:	7902                	ld	s2,32(sp)
  cc:	69e2                	ld	s3,24(sp)
  ce:	6121                	add	sp,sp,64
  d0:	8082                	ret

00000000000000d2 <iobench>:

void
iobench(int N, int pid)
{
  d2:	715d                	add	sp,sp,-80
  d4:	e486                	sd	ra,72(sp)
  d6:	e0a2                	sd	s0,64(sp)
  d8:	fc26                	sd	s1,56(sp)
  da:	f84a                	sd	s2,48(sp)
  dc:	f44e                	sd	s3,40(sp)
  de:	f052                	sd	s4,32(sp)
  e0:	ec56                	sd	s5,24(sp)
  e2:	e85a                	sd	s6,16(sp)
  e4:	e45e                	sd	s7,8(sp)
  e6:	0880                	add	s0,sp,80
  e8:	84aa                	mv	s1,a0
  ea:	8aae                	mv	s5,a1
  memset(data, 'a', sizeof(data));
  ec:	04000613          	li	a2,64
  f0:	06100593          	li	a1,97
  f4:	00001517          	auipc	a0,0x1
  f8:	f1c50513          	add	a0,a0,-228 # 1010 <data>
  fc:	00000097          	auipc	ra,0x0
 100:	164080e7          	jalr	356(ra) # 260 <memset>
  uint64 start_tick, end_tick, elapsed_ticks, metric;
  int total_iops;

  int *measurements = malloc(sizeof(int) * N);
 104:	0024951b          	sllw	a0,s1,0x2
 108:	00000097          	auipc	ra,0x0
 10c:	772080e7          	jalr	1906(ra) # 87a <malloc>

  for (int i = 0; i < N; i++){
 110:	04905d63          	blez	s1,16a <iobench+0x98>
 114:	89aa                	mv	s3,a0
 116:	048a                	sll	s1,s1,0x2
 118:	00950a33          	add	s4,a0,s1
    // Realizar escrituras y lecturas de archivos
    total_iops = io_ops();

    end_tick = uptime();
    elapsed_ticks = end_tick - start_tick;
    metric = (total_iops * 10000)/elapsed_ticks;  // Cambiar esto por la métrica adecuada
 11c:	6b09                	lui	s6,0x2
 11e:	710b0b1b          	addw	s6,s6,1808 # 2710 <base+0x16c0>
    measurements[i] = metric;
    printf("%d\t[iobench]\t%d\t%d\t%d\n",
 122:	00001b97          	auipc	s7,0x1
 126:	83eb8b93          	add	s7,s7,-1986 # 960 <malloc+0xe6>
    start_tick = uptime();
 12a:	00000097          	auipc	ra,0x0
 12e:	3c8080e7          	jalr	968(ra) # 4f2 <uptime>
 132:	892a                	mv	s2,a0
    total_iops = io_ops();
 134:	00000097          	auipc	ra,0x0
 138:	ecc080e7          	jalr	-308(ra) # 0 <io_ops>
 13c:	84aa                	mv	s1,a0
    end_tick = uptime();
 13e:	00000097          	auipc	ra,0x0
 142:	3b4080e7          	jalr	948(ra) # 4f2 <uptime>
    elapsed_ticks = end_tick - start_tick;
 146:	41250733          	sub	a4,a0,s2
    metric = (total_iops * 10000)/elapsed_ticks;  // Cambiar esto por la métrica adecuada
 14a:	029b063b          	mulw	a2,s6,s1
 14e:	02e65633          	divu	a2,a2,a4
    measurements[i] = metric;
 152:	00c9a023          	sw	a2,0(s3)
    printf("%d\t[iobench]\t%d\t%d\t%d\n",
 156:	86ca                	mv	a3,s2
 158:	85d6                	mv	a1,s5
 15a:	855e                	mv	a0,s7
 15c:	00000097          	auipc	ra,0x0
 160:	666080e7          	jalr	1638(ra) # 7c2 <printf>
  for (int i = 0; i < N; i++){
 164:	0991                	add	s3,s3,4
 166:	fd4992e3          	bne	s3,s4,12a <iobench+0x58>
           pid, metric, start_tick, elapsed_ticks);
  }
}
 16a:	60a6                	ld	ra,72(sp)
 16c:	6406                	ld	s0,64(sp)
 16e:	74e2                	ld	s1,56(sp)
 170:	7942                	ld	s2,48(sp)
 172:	79a2                	ld	s3,40(sp)
 174:	7a02                	ld	s4,32(sp)
 176:	6ae2                	ld	s5,24(sp)
 178:	6b42                	ld	s6,16(sp)
 17a:	6ba2                	ld	s7,8(sp)
 17c:	6161                	add	sp,sp,80
 17e:	8082                	ret

0000000000000180 <main>:

int
main(int argc, char *argv[])
{
 180:	1101                	add	sp,sp,-32
 182:	ec06                	sd	ra,24(sp)
 184:	e822                	sd	s0,16(sp)
 186:	e426                	sd	s1,8(sp)
 188:	1000                	add	s0,sp,32
  int N, pid;
  if (argc != 2) {
 18a:	4789                	li	a5,2
 18c:	00f50f63          	beq	a0,a5,1aa <main+0x2a>
    printf("Uso: benchmark N\n");
 190:	00000517          	auipc	a0,0x0
 194:	7e850513          	add	a0,a0,2024 # 978 <malloc+0xfe>
 198:	00000097          	auipc	ra,0x0
 19c:	62a080e7          	jalr	1578(ra) # 7c2 <printf>
    exit(1);
 1a0:	4505                	li	a0,1
 1a2:	00000097          	auipc	ra,0x0
 1a6:	2b8080e7          	jalr	696(ra) # 45a <exit>
  }

  N = atoi(argv[1]);  // Número de repeticiones para los benchmarks
 1aa:	6588                	ld	a0,8(a1)
 1ac:	00000097          	auipc	ra,0x0
 1b0:	1b4080e7          	jalr	436(ra) # 360 <atoi>
 1b4:	84aa                	mv	s1,a0
  pid = getpid();
 1b6:	00000097          	auipc	ra,0x0
 1ba:	324080e7          	jalr	804(ra) # 4da <getpid>
 1be:	85aa                	mv	a1,a0
  iobench(N, pid);
 1c0:	8526                	mv	a0,s1
 1c2:	00000097          	auipc	ra,0x0
 1c6:	f10080e7          	jalr	-240(ra) # d2 <iobench>

  exit(0);
 1ca:	4501                	li	a0,0
 1cc:	00000097          	auipc	ra,0x0
 1d0:	28e080e7          	jalr	654(ra) # 45a <exit>

00000000000001d4 <_main>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
_main()
{
 1d4:	1141                	add	sp,sp,-16
 1d6:	e406                	sd	ra,8(sp)
 1d8:	e022                	sd	s0,0(sp)
 1da:	0800                	add	s0,sp,16
  extern int main();
  main();
 1dc:	00000097          	auipc	ra,0x0
 1e0:	fa4080e7          	jalr	-92(ra) # 180 <main>
  exit(0);
 1e4:	4501                	li	a0,0
 1e6:	00000097          	auipc	ra,0x0
 1ea:	274080e7          	jalr	628(ra) # 45a <exit>

00000000000001ee <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
 1ee:	1141                	add	sp,sp,-16
 1f0:	e422                	sd	s0,8(sp)
 1f2:	0800                	add	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 1f4:	87aa                	mv	a5,a0
 1f6:	0585                	add	a1,a1,1
 1f8:	0785                	add	a5,a5,1
 1fa:	fff5c703          	lbu	a4,-1(a1)
 1fe:	fee78fa3          	sb	a4,-1(a5)
 202:	fb75                	bnez	a4,1f6 <strcpy+0x8>
    ;
  return os;
}
 204:	6422                	ld	s0,8(sp)
 206:	0141                	add	sp,sp,16
 208:	8082                	ret

000000000000020a <strcmp>:

int
strcmp(const char *p, const char *q)
{
 20a:	1141                	add	sp,sp,-16
 20c:	e422                	sd	s0,8(sp)
 20e:	0800                	add	s0,sp,16
  while(*p && *p == *q)
 210:	00054783          	lbu	a5,0(a0)
 214:	cb91                	beqz	a5,228 <strcmp+0x1e>
 216:	0005c703          	lbu	a4,0(a1)
 21a:	00f71763          	bne	a4,a5,228 <strcmp+0x1e>
    p++, q++;
 21e:	0505                	add	a0,a0,1
 220:	0585                	add	a1,a1,1
  while(*p && *p == *q)
 222:	00054783          	lbu	a5,0(a0)
 226:	fbe5                	bnez	a5,216 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 228:	0005c503          	lbu	a0,0(a1)
}
 22c:	40a7853b          	subw	a0,a5,a0
 230:	6422                	ld	s0,8(sp)
 232:	0141                	add	sp,sp,16
 234:	8082                	ret

0000000000000236 <strlen>:

uint
strlen(const char *s)
{
 236:	1141                	add	sp,sp,-16
 238:	e422                	sd	s0,8(sp)
 23a:	0800                	add	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 23c:	00054783          	lbu	a5,0(a0)
 240:	cf91                	beqz	a5,25c <strlen+0x26>
 242:	0505                	add	a0,a0,1
 244:	87aa                	mv	a5,a0
 246:	86be                	mv	a3,a5
 248:	0785                	add	a5,a5,1
 24a:	fff7c703          	lbu	a4,-1(a5)
 24e:	ff65                	bnez	a4,246 <strlen+0x10>
 250:	40a6853b          	subw	a0,a3,a0
 254:	2505                	addw	a0,a0,1
    ;
  return n;
}
 256:	6422                	ld	s0,8(sp)
 258:	0141                	add	sp,sp,16
 25a:	8082                	ret
  for(n = 0; s[n]; n++)
 25c:	4501                	li	a0,0
 25e:	bfe5                	j	256 <strlen+0x20>

0000000000000260 <memset>:

void*
memset(void *dst, int c, uint n)
{
 260:	1141                	add	sp,sp,-16
 262:	e422                	sd	s0,8(sp)
 264:	0800                	add	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 266:	ca19                	beqz	a2,27c <memset+0x1c>
 268:	87aa                	mv	a5,a0
 26a:	1602                	sll	a2,a2,0x20
 26c:	9201                	srl	a2,a2,0x20
 26e:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 272:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 276:	0785                	add	a5,a5,1
 278:	fee79de3          	bne	a5,a4,272 <memset+0x12>
  }
  return dst;
}
 27c:	6422                	ld	s0,8(sp)
 27e:	0141                	add	sp,sp,16
 280:	8082                	ret

0000000000000282 <strchr>:

char*
strchr(const char *s, char c)
{
 282:	1141                	add	sp,sp,-16
 284:	e422                	sd	s0,8(sp)
 286:	0800                	add	s0,sp,16
  for(; *s; s++)
 288:	00054783          	lbu	a5,0(a0)
 28c:	cb99                	beqz	a5,2a2 <strchr+0x20>
    if(*s == c)
 28e:	00f58763          	beq	a1,a5,29c <strchr+0x1a>
  for(; *s; s++)
 292:	0505                	add	a0,a0,1
 294:	00054783          	lbu	a5,0(a0)
 298:	fbfd                	bnez	a5,28e <strchr+0xc>
      return (char*)s;
  return 0;
 29a:	4501                	li	a0,0
}
 29c:	6422                	ld	s0,8(sp)
 29e:	0141                	add	sp,sp,16
 2a0:	8082                	ret
  return 0;
 2a2:	4501                	li	a0,0
 2a4:	bfe5                	j	29c <strchr+0x1a>

00000000000002a6 <gets>:

char*
gets(char *buf, int max)
{
 2a6:	711d                	add	sp,sp,-96
 2a8:	ec86                	sd	ra,88(sp)
 2aa:	e8a2                	sd	s0,80(sp)
 2ac:	e4a6                	sd	s1,72(sp)
 2ae:	e0ca                	sd	s2,64(sp)
 2b0:	fc4e                	sd	s3,56(sp)
 2b2:	f852                	sd	s4,48(sp)
 2b4:	f456                	sd	s5,40(sp)
 2b6:	f05a                	sd	s6,32(sp)
 2b8:	ec5e                	sd	s7,24(sp)
 2ba:	1080                	add	s0,sp,96
 2bc:	8baa                	mv	s7,a0
 2be:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 2c0:	892a                	mv	s2,a0
 2c2:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 2c4:	4aa9                	li	s5,10
 2c6:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 2c8:	89a6                	mv	s3,s1
 2ca:	2485                	addw	s1,s1,1
 2cc:	0344d863          	bge	s1,s4,2fc <gets+0x56>
    cc = read(0, &c, 1);
 2d0:	4605                	li	a2,1
 2d2:	faf40593          	add	a1,s0,-81
 2d6:	4501                	li	a0,0
 2d8:	00000097          	auipc	ra,0x0
 2dc:	19a080e7          	jalr	410(ra) # 472 <read>
    if(cc < 1)
 2e0:	00a05e63          	blez	a0,2fc <gets+0x56>
    buf[i++] = c;
 2e4:	faf44783          	lbu	a5,-81(s0)
 2e8:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 2ec:	01578763          	beq	a5,s5,2fa <gets+0x54>
 2f0:	0905                	add	s2,s2,1
 2f2:	fd679be3          	bne	a5,s6,2c8 <gets+0x22>
  for(i=0; i+1 < max; ){
 2f6:	89a6                	mv	s3,s1
 2f8:	a011                	j	2fc <gets+0x56>
 2fa:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 2fc:	99de                	add	s3,s3,s7
 2fe:	00098023          	sb	zero,0(s3)
  return buf;
}
 302:	855e                	mv	a0,s7
 304:	60e6                	ld	ra,88(sp)
 306:	6446                	ld	s0,80(sp)
 308:	64a6                	ld	s1,72(sp)
 30a:	6906                	ld	s2,64(sp)
 30c:	79e2                	ld	s3,56(sp)
 30e:	7a42                	ld	s4,48(sp)
 310:	7aa2                	ld	s5,40(sp)
 312:	7b02                	ld	s6,32(sp)
 314:	6be2                	ld	s7,24(sp)
 316:	6125                	add	sp,sp,96
 318:	8082                	ret

000000000000031a <stat>:

int
stat(const char *n, struct stat *st)
{
 31a:	1101                	add	sp,sp,-32
 31c:	ec06                	sd	ra,24(sp)
 31e:	e822                	sd	s0,16(sp)
 320:	e426                	sd	s1,8(sp)
 322:	e04a                	sd	s2,0(sp)
 324:	1000                	add	s0,sp,32
 326:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 328:	4581                	li	a1,0
 32a:	00000097          	auipc	ra,0x0
 32e:	170080e7          	jalr	368(ra) # 49a <open>
  if(fd < 0)
 332:	02054563          	bltz	a0,35c <stat+0x42>
 336:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 338:	85ca                	mv	a1,s2
 33a:	00000097          	auipc	ra,0x0
 33e:	178080e7          	jalr	376(ra) # 4b2 <fstat>
 342:	892a                	mv	s2,a0
  close(fd);
 344:	8526                	mv	a0,s1
 346:	00000097          	auipc	ra,0x0
 34a:	13c080e7          	jalr	316(ra) # 482 <close>
  return r;
}
 34e:	854a                	mv	a0,s2
 350:	60e2                	ld	ra,24(sp)
 352:	6442                	ld	s0,16(sp)
 354:	64a2                	ld	s1,8(sp)
 356:	6902                	ld	s2,0(sp)
 358:	6105                	add	sp,sp,32
 35a:	8082                	ret
    return -1;
 35c:	597d                	li	s2,-1
 35e:	bfc5                	j	34e <stat+0x34>

0000000000000360 <atoi>:

int
atoi(const char *s)
{
 360:	1141                	add	sp,sp,-16
 362:	e422                	sd	s0,8(sp)
 364:	0800                	add	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 366:	00054683          	lbu	a3,0(a0)
 36a:	fd06879b          	addw	a5,a3,-48
 36e:	0ff7f793          	zext.b	a5,a5
 372:	4625                	li	a2,9
 374:	02f66863          	bltu	a2,a5,3a4 <atoi+0x44>
 378:	872a                	mv	a4,a0
  n = 0;
 37a:	4501                	li	a0,0
    n = n*10 + *s++ - '0';
 37c:	0705                	add	a4,a4,1
 37e:	0025179b          	sllw	a5,a0,0x2
 382:	9fa9                	addw	a5,a5,a0
 384:	0017979b          	sllw	a5,a5,0x1
 388:	9fb5                	addw	a5,a5,a3
 38a:	fd07851b          	addw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 38e:	00074683          	lbu	a3,0(a4)
 392:	fd06879b          	addw	a5,a3,-48
 396:	0ff7f793          	zext.b	a5,a5
 39a:	fef671e3          	bgeu	a2,a5,37c <atoi+0x1c>
  return n;
}
 39e:	6422                	ld	s0,8(sp)
 3a0:	0141                	add	sp,sp,16
 3a2:	8082                	ret
  n = 0;
 3a4:	4501                	li	a0,0
 3a6:	bfe5                	j	39e <atoi+0x3e>

00000000000003a8 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 3a8:	1141                	add	sp,sp,-16
 3aa:	e422                	sd	s0,8(sp)
 3ac:	0800                	add	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 3ae:	02b57463          	bgeu	a0,a1,3d6 <memmove+0x2e>
    while(n-- > 0)
 3b2:	00c05f63          	blez	a2,3d0 <memmove+0x28>
 3b6:	1602                	sll	a2,a2,0x20
 3b8:	9201                	srl	a2,a2,0x20
 3ba:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 3be:	872a                	mv	a4,a0
      *dst++ = *src++;
 3c0:	0585                	add	a1,a1,1
 3c2:	0705                	add	a4,a4,1
 3c4:	fff5c683          	lbu	a3,-1(a1)
 3c8:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 3cc:	fee79ae3          	bne	a5,a4,3c0 <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 3d0:	6422                	ld	s0,8(sp)
 3d2:	0141                	add	sp,sp,16
 3d4:	8082                	ret
    dst += n;
 3d6:	00c50733          	add	a4,a0,a2
    src += n;
 3da:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 3dc:	fec05ae3          	blez	a2,3d0 <memmove+0x28>
 3e0:	fff6079b          	addw	a5,a2,-1
 3e4:	1782                	sll	a5,a5,0x20
 3e6:	9381                	srl	a5,a5,0x20
 3e8:	fff7c793          	not	a5,a5
 3ec:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 3ee:	15fd                	add	a1,a1,-1
 3f0:	177d                	add	a4,a4,-1
 3f2:	0005c683          	lbu	a3,0(a1)
 3f6:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 3fa:	fee79ae3          	bne	a5,a4,3ee <memmove+0x46>
 3fe:	bfc9                	j	3d0 <memmove+0x28>

0000000000000400 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 400:	1141                	add	sp,sp,-16
 402:	e422                	sd	s0,8(sp)
 404:	0800                	add	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 406:	ca05                	beqz	a2,436 <memcmp+0x36>
 408:	fff6069b          	addw	a3,a2,-1
 40c:	1682                	sll	a3,a3,0x20
 40e:	9281                	srl	a3,a3,0x20
 410:	0685                	add	a3,a3,1
 412:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 414:	00054783          	lbu	a5,0(a0)
 418:	0005c703          	lbu	a4,0(a1)
 41c:	00e79863          	bne	a5,a4,42c <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 420:	0505                	add	a0,a0,1
    p2++;
 422:	0585                	add	a1,a1,1
  while (n-- > 0) {
 424:	fed518e3          	bne	a0,a3,414 <memcmp+0x14>
  }
  return 0;
 428:	4501                	li	a0,0
 42a:	a019                	j	430 <memcmp+0x30>
      return *p1 - *p2;
 42c:	40e7853b          	subw	a0,a5,a4
}
 430:	6422                	ld	s0,8(sp)
 432:	0141                	add	sp,sp,16
 434:	8082                	ret
  return 0;
 436:	4501                	li	a0,0
 438:	bfe5                	j	430 <memcmp+0x30>

000000000000043a <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 43a:	1141                	add	sp,sp,-16
 43c:	e406                	sd	ra,8(sp)
 43e:	e022                	sd	s0,0(sp)
 440:	0800                	add	s0,sp,16
  return memmove(dst, src, n);
 442:	00000097          	auipc	ra,0x0
 446:	f66080e7          	jalr	-154(ra) # 3a8 <memmove>
}
 44a:	60a2                	ld	ra,8(sp)
 44c:	6402                	ld	s0,0(sp)
 44e:	0141                	add	sp,sp,16
 450:	8082                	ret

0000000000000452 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 452:	4885                	li	a7,1
 ecall
 454:	00000073          	ecall
 ret
 458:	8082                	ret

000000000000045a <exit>:
.global exit
exit:
 li a7, SYS_exit
 45a:	4889                	li	a7,2
 ecall
 45c:	00000073          	ecall
 ret
 460:	8082                	ret

0000000000000462 <wait>:
.global wait
wait:
 li a7, SYS_wait
 462:	488d                	li	a7,3
 ecall
 464:	00000073          	ecall
 ret
 468:	8082                	ret

000000000000046a <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 46a:	4891                	li	a7,4
 ecall
 46c:	00000073          	ecall
 ret
 470:	8082                	ret

0000000000000472 <read>:
.global read
read:
 li a7, SYS_read
 472:	4895                	li	a7,5
 ecall
 474:	00000073          	ecall
 ret
 478:	8082                	ret

000000000000047a <write>:
.global write
write:
 li a7, SYS_write
 47a:	48c1                	li	a7,16
 ecall
 47c:	00000073          	ecall
 ret
 480:	8082                	ret

0000000000000482 <close>:
.global close
close:
 li a7, SYS_close
 482:	48d5                	li	a7,21
 ecall
 484:	00000073          	ecall
 ret
 488:	8082                	ret

000000000000048a <kill>:
.global kill
kill:
 li a7, SYS_kill
 48a:	4899                	li	a7,6
 ecall
 48c:	00000073          	ecall
 ret
 490:	8082                	ret

0000000000000492 <exec>:
.global exec
exec:
 li a7, SYS_exec
 492:	489d                	li	a7,7
 ecall
 494:	00000073          	ecall
 ret
 498:	8082                	ret

000000000000049a <open>:
.global open
open:
 li a7, SYS_open
 49a:	48bd                	li	a7,15
 ecall
 49c:	00000073          	ecall
 ret
 4a0:	8082                	ret

00000000000004a2 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 4a2:	48c5                	li	a7,17
 ecall
 4a4:	00000073          	ecall
 ret
 4a8:	8082                	ret

00000000000004aa <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 4aa:	48c9                	li	a7,18
 ecall
 4ac:	00000073          	ecall
 ret
 4b0:	8082                	ret

00000000000004b2 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 4b2:	48a1                	li	a7,8
 ecall
 4b4:	00000073          	ecall
 ret
 4b8:	8082                	ret

00000000000004ba <link>:
.global link
link:
 li a7, SYS_link
 4ba:	48cd                	li	a7,19
 ecall
 4bc:	00000073          	ecall
 ret
 4c0:	8082                	ret

00000000000004c2 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 4c2:	48d1                	li	a7,20
 ecall
 4c4:	00000073          	ecall
 ret
 4c8:	8082                	ret

00000000000004ca <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 4ca:	48a5                	li	a7,9
 ecall
 4cc:	00000073          	ecall
 ret
 4d0:	8082                	ret

00000000000004d2 <dup>:
.global dup
dup:
 li a7, SYS_dup
 4d2:	48a9                	li	a7,10
 ecall
 4d4:	00000073          	ecall
 ret
 4d8:	8082                	ret

00000000000004da <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 4da:	48ad                	li	a7,11
 ecall
 4dc:	00000073          	ecall
 ret
 4e0:	8082                	ret

00000000000004e2 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 4e2:	48b1                	li	a7,12
 ecall
 4e4:	00000073          	ecall
 ret
 4e8:	8082                	ret

00000000000004ea <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 4ea:	48b5                	li	a7,13
 ecall
 4ec:	00000073          	ecall
 ret
 4f0:	8082                	ret

00000000000004f2 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 4f2:	48b9                	li	a7,14
 ecall
 4f4:	00000073          	ecall
 ret
 4f8:	8082                	ret

00000000000004fa <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 4fa:	1101                	add	sp,sp,-32
 4fc:	ec06                	sd	ra,24(sp)
 4fe:	e822                	sd	s0,16(sp)
 500:	1000                	add	s0,sp,32
 502:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 506:	4605                	li	a2,1
 508:	fef40593          	add	a1,s0,-17
 50c:	00000097          	auipc	ra,0x0
 510:	f6e080e7          	jalr	-146(ra) # 47a <write>
}
 514:	60e2                	ld	ra,24(sp)
 516:	6442                	ld	s0,16(sp)
 518:	6105                	add	sp,sp,32
 51a:	8082                	ret

000000000000051c <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 51c:	7139                	add	sp,sp,-64
 51e:	fc06                	sd	ra,56(sp)
 520:	f822                	sd	s0,48(sp)
 522:	f426                	sd	s1,40(sp)
 524:	f04a                	sd	s2,32(sp)
 526:	ec4e                	sd	s3,24(sp)
 528:	0080                	add	s0,sp,64
 52a:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 52c:	c299                	beqz	a3,532 <printint+0x16>
 52e:	0805c963          	bltz	a1,5c0 <printint+0xa4>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 532:	2581                	sext.w	a1,a1
  neg = 0;
 534:	4881                	li	a7,0
 536:	fc040693          	add	a3,s0,-64
  }

  i = 0;
 53a:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 53c:	2601                	sext.w	a2,a2
 53e:	00000517          	auipc	a0,0x0
 542:	4b250513          	add	a0,a0,1202 # 9f0 <digits>
 546:	883a                	mv	a6,a4
 548:	2705                	addw	a4,a4,1
 54a:	02c5f7bb          	remuw	a5,a1,a2
 54e:	1782                	sll	a5,a5,0x20
 550:	9381                	srl	a5,a5,0x20
 552:	97aa                	add	a5,a5,a0
 554:	0007c783          	lbu	a5,0(a5)
 558:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 55c:	0005879b          	sext.w	a5,a1
 560:	02c5d5bb          	divuw	a1,a1,a2
 564:	0685                	add	a3,a3,1
 566:	fec7f0e3          	bgeu	a5,a2,546 <printint+0x2a>
  if(neg)
 56a:	00088c63          	beqz	a7,582 <printint+0x66>
    buf[i++] = '-';
 56e:	fd070793          	add	a5,a4,-48
 572:	00878733          	add	a4,a5,s0
 576:	02d00793          	li	a5,45
 57a:	fef70823          	sb	a5,-16(a4)
 57e:	0028071b          	addw	a4,a6,2

  while(--i >= 0)
 582:	02e05863          	blez	a4,5b2 <printint+0x96>
 586:	fc040793          	add	a5,s0,-64
 58a:	00e78933          	add	s2,a5,a4
 58e:	fff78993          	add	s3,a5,-1
 592:	99ba                	add	s3,s3,a4
 594:	377d                	addw	a4,a4,-1
 596:	1702                	sll	a4,a4,0x20
 598:	9301                	srl	a4,a4,0x20
 59a:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 59e:	fff94583          	lbu	a1,-1(s2)
 5a2:	8526                	mv	a0,s1
 5a4:	00000097          	auipc	ra,0x0
 5a8:	f56080e7          	jalr	-170(ra) # 4fa <putc>
  while(--i >= 0)
 5ac:	197d                	add	s2,s2,-1
 5ae:	ff3918e3          	bne	s2,s3,59e <printint+0x82>
}
 5b2:	70e2                	ld	ra,56(sp)
 5b4:	7442                	ld	s0,48(sp)
 5b6:	74a2                	ld	s1,40(sp)
 5b8:	7902                	ld	s2,32(sp)
 5ba:	69e2                	ld	s3,24(sp)
 5bc:	6121                	add	sp,sp,64
 5be:	8082                	ret
    x = -xx;
 5c0:	40b005bb          	negw	a1,a1
    neg = 1;
 5c4:	4885                	li	a7,1
    x = -xx;
 5c6:	bf85                	j	536 <printint+0x1a>

00000000000005c8 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 5c8:	715d                	add	sp,sp,-80
 5ca:	e486                	sd	ra,72(sp)
 5cc:	e0a2                	sd	s0,64(sp)
 5ce:	fc26                	sd	s1,56(sp)
 5d0:	f84a                	sd	s2,48(sp)
 5d2:	f44e                	sd	s3,40(sp)
 5d4:	f052                	sd	s4,32(sp)
 5d6:	ec56                	sd	s5,24(sp)
 5d8:	e85a                	sd	s6,16(sp)
 5da:	e45e                	sd	s7,8(sp)
 5dc:	e062                	sd	s8,0(sp)
 5de:	0880                	add	s0,sp,80
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 5e0:	0005c903          	lbu	s2,0(a1)
 5e4:	18090c63          	beqz	s2,77c <vprintf+0x1b4>
 5e8:	8aaa                	mv	s5,a0
 5ea:	8bb2                	mv	s7,a2
 5ec:	00158493          	add	s1,a1,1
  state = 0;
 5f0:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 5f2:	02500a13          	li	s4,37
 5f6:	4b55                	li	s6,21
 5f8:	a839                	j	616 <vprintf+0x4e>
        putc(fd, c);
 5fa:	85ca                	mv	a1,s2
 5fc:	8556                	mv	a0,s5
 5fe:	00000097          	auipc	ra,0x0
 602:	efc080e7          	jalr	-260(ra) # 4fa <putc>
 606:	a019                	j	60c <vprintf+0x44>
    } else if(state == '%'){
 608:	01498d63          	beq	s3,s4,622 <vprintf+0x5a>
  for(i = 0; fmt[i]; i++){
 60c:	0485                	add	s1,s1,1
 60e:	fff4c903          	lbu	s2,-1(s1)
 612:	16090563          	beqz	s2,77c <vprintf+0x1b4>
    if(state == 0){
 616:	fe0999e3          	bnez	s3,608 <vprintf+0x40>
      if(c == '%'){
 61a:	ff4910e3          	bne	s2,s4,5fa <vprintf+0x32>
        state = '%';
 61e:	89d2                	mv	s3,s4
 620:	b7f5                	j	60c <vprintf+0x44>
      if(c == 'd'){
 622:	13490263          	beq	s2,s4,746 <vprintf+0x17e>
 626:	f9d9079b          	addw	a5,s2,-99
 62a:	0ff7f793          	zext.b	a5,a5
 62e:	12fb6563          	bltu	s6,a5,758 <vprintf+0x190>
 632:	f9d9079b          	addw	a5,s2,-99
 636:	0ff7f713          	zext.b	a4,a5
 63a:	10eb6f63          	bltu	s6,a4,758 <vprintf+0x190>
 63e:	00271793          	sll	a5,a4,0x2
 642:	00000717          	auipc	a4,0x0
 646:	35670713          	add	a4,a4,854 # 998 <malloc+0x11e>
 64a:	97ba                	add	a5,a5,a4
 64c:	439c                	lw	a5,0(a5)
 64e:	97ba                	add	a5,a5,a4
 650:	8782                	jr	a5
        printint(fd, va_arg(ap, int), 10, 1);
 652:	008b8913          	add	s2,s7,8
 656:	4685                	li	a3,1
 658:	4629                	li	a2,10
 65a:	000ba583          	lw	a1,0(s7)
 65e:	8556                	mv	a0,s5
 660:	00000097          	auipc	ra,0x0
 664:	ebc080e7          	jalr	-324(ra) # 51c <printint>
 668:	8bca                	mv	s7,s2
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
        putc(fd, c);
      }
      state = 0;
 66a:	4981                	li	s3,0
 66c:	b745                	j	60c <vprintf+0x44>
        printint(fd, va_arg(ap, uint64), 10, 0);
 66e:	008b8913          	add	s2,s7,8
 672:	4681                	li	a3,0
 674:	4629                	li	a2,10
 676:	000ba583          	lw	a1,0(s7)
 67a:	8556                	mv	a0,s5
 67c:	00000097          	auipc	ra,0x0
 680:	ea0080e7          	jalr	-352(ra) # 51c <printint>
 684:	8bca                	mv	s7,s2
      state = 0;
 686:	4981                	li	s3,0
 688:	b751                	j	60c <vprintf+0x44>
        printint(fd, va_arg(ap, int), 16, 0);
 68a:	008b8913          	add	s2,s7,8
 68e:	4681                	li	a3,0
 690:	4641                	li	a2,16
 692:	000ba583          	lw	a1,0(s7)
 696:	8556                	mv	a0,s5
 698:	00000097          	auipc	ra,0x0
 69c:	e84080e7          	jalr	-380(ra) # 51c <printint>
 6a0:	8bca                	mv	s7,s2
      state = 0;
 6a2:	4981                	li	s3,0
 6a4:	b7a5                	j	60c <vprintf+0x44>
        printptr(fd, va_arg(ap, uint64));
 6a6:	008b8c13          	add	s8,s7,8
 6aa:	000bb983          	ld	s3,0(s7)
  putc(fd, '0');
 6ae:	03000593          	li	a1,48
 6b2:	8556                	mv	a0,s5
 6b4:	00000097          	auipc	ra,0x0
 6b8:	e46080e7          	jalr	-442(ra) # 4fa <putc>
  putc(fd, 'x');
 6bc:	07800593          	li	a1,120
 6c0:	8556                	mv	a0,s5
 6c2:	00000097          	auipc	ra,0x0
 6c6:	e38080e7          	jalr	-456(ra) # 4fa <putc>
 6ca:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 6cc:	00000b97          	auipc	s7,0x0
 6d0:	324b8b93          	add	s7,s7,804 # 9f0 <digits>
 6d4:	03c9d793          	srl	a5,s3,0x3c
 6d8:	97de                	add	a5,a5,s7
 6da:	0007c583          	lbu	a1,0(a5)
 6de:	8556                	mv	a0,s5
 6e0:	00000097          	auipc	ra,0x0
 6e4:	e1a080e7          	jalr	-486(ra) # 4fa <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 6e8:	0992                	sll	s3,s3,0x4
 6ea:	397d                	addw	s2,s2,-1
 6ec:	fe0914e3          	bnez	s2,6d4 <vprintf+0x10c>
        printptr(fd, va_arg(ap, uint64));
 6f0:	8be2                	mv	s7,s8
      state = 0;
 6f2:	4981                	li	s3,0
 6f4:	bf21                	j	60c <vprintf+0x44>
        s = va_arg(ap, char*);
 6f6:	008b8993          	add	s3,s7,8
 6fa:	000bb903          	ld	s2,0(s7)
        if(s == 0)
 6fe:	02090163          	beqz	s2,720 <vprintf+0x158>
        while(*s != 0){
 702:	00094583          	lbu	a1,0(s2)
 706:	c9a5                	beqz	a1,776 <vprintf+0x1ae>
          putc(fd, *s);
 708:	8556                	mv	a0,s5
 70a:	00000097          	auipc	ra,0x0
 70e:	df0080e7          	jalr	-528(ra) # 4fa <putc>
          s++;
 712:	0905                	add	s2,s2,1
        while(*s != 0){
 714:	00094583          	lbu	a1,0(s2)
 718:	f9e5                	bnez	a1,708 <vprintf+0x140>
        s = va_arg(ap, char*);
 71a:	8bce                	mv	s7,s3
      state = 0;
 71c:	4981                	li	s3,0
 71e:	b5fd                	j	60c <vprintf+0x44>
          s = "(null)";
 720:	00000917          	auipc	s2,0x0
 724:	27090913          	add	s2,s2,624 # 990 <malloc+0x116>
        while(*s != 0){
 728:	02800593          	li	a1,40
 72c:	bff1                	j	708 <vprintf+0x140>
        putc(fd, va_arg(ap, uint));
 72e:	008b8913          	add	s2,s7,8
 732:	000bc583          	lbu	a1,0(s7)
 736:	8556                	mv	a0,s5
 738:	00000097          	auipc	ra,0x0
 73c:	dc2080e7          	jalr	-574(ra) # 4fa <putc>
 740:	8bca                	mv	s7,s2
      state = 0;
 742:	4981                	li	s3,0
 744:	b5e1                	j	60c <vprintf+0x44>
        putc(fd, c);
 746:	02500593          	li	a1,37
 74a:	8556                	mv	a0,s5
 74c:	00000097          	auipc	ra,0x0
 750:	dae080e7          	jalr	-594(ra) # 4fa <putc>
      state = 0;
 754:	4981                	li	s3,0
 756:	bd5d                	j	60c <vprintf+0x44>
        putc(fd, '%');
 758:	02500593          	li	a1,37
 75c:	8556                	mv	a0,s5
 75e:	00000097          	auipc	ra,0x0
 762:	d9c080e7          	jalr	-612(ra) # 4fa <putc>
        putc(fd, c);
 766:	85ca                	mv	a1,s2
 768:	8556                	mv	a0,s5
 76a:	00000097          	auipc	ra,0x0
 76e:	d90080e7          	jalr	-624(ra) # 4fa <putc>
      state = 0;
 772:	4981                	li	s3,0
 774:	bd61                	j	60c <vprintf+0x44>
        s = va_arg(ap, char*);
 776:	8bce                	mv	s7,s3
      state = 0;
 778:	4981                	li	s3,0
 77a:	bd49                	j	60c <vprintf+0x44>
    }
  }
}
 77c:	60a6                	ld	ra,72(sp)
 77e:	6406                	ld	s0,64(sp)
 780:	74e2                	ld	s1,56(sp)
 782:	7942                	ld	s2,48(sp)
 784:	79a2                	ld	s3,40(sp)
 786:	7a02                	ld	s4,32(sp)
 788:	6ae2                	ld	s5,24(sp)
 78a:	6b42                	ld	s6,16(sp)
 78c:	6ba2                	ld	s7,8(sp)
 78e:	6c02                	ld	s8,0(sp)
 790:	6161                	add	sp,sp,80
 792:	8082                	ret

0000000000000794 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 794:	715d                	add	sp,sp,-80
 796:	ec06                	sd	ra,24(sp)
 798:	e822                	sd	s0,16(sp)
 79a:	1000                	add	s0,sp,32
 79c:	e010                	sd	a2,0(s0)
 79e:	e414                	sd	a3,8(s0)
 7a0:	e818                	sd	a4,16(s0)
 7a2:	ec1c                	sd	a5,24(s0)
 7a4:	03043023          	sd	a6,32(s0)
 7a8:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 7ac:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 7b0:	8622                	mv	a2,s0
 7b2:	00000097          	auipc	ra,0x0
 7b6:	e16080e7          	jalr	-490(ra) # 5c8 <vprintf>
}
 7ba:	60e2                	ld	ra,24(sp)
 7bc:	6442                	ld	s0,16(sp)
 7be:	6161                	add	sp,sp,80
 7c0:	8082                	ret

00000000000007c2 <printf>:

void
printf(const char *fmt, ...)
{
 7c2:	711d                	add	sp,sp,-96
 7c4:	ec06                	sd	ra,24(sp)
 7c6:	e822                	sd	s0,16(sp)
 7c8:	1000                	add	s0,sp,32
 7ca:	e40c                	sd	a1,8(s0)
 7cc:	e810                	sd	a2,16(s0)
 7ce:	ec14                	sd	a3,24(s0)
 7d0:	f018                	sd	a4,32(s0)
 7d2:	f41c                	sd	a5,40(s0)
 7d4:	03043823          	sd	a6,48(s0)
 7d8:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 7dc:	00840613          	add	a2,s0,8
 7e0:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 7e4:	85aa                	mv	a1,a0
 7e6:	4505                	li	a0,1
 7e8:	00000097          	auipc	ra,0x0
 7ec:	de0080e7          	jalr	-544(ra) # 5c8 <vprintf>
}
 7f0:	60e2                	ld	ra,24(sp)
 7f2:	6442                	ld	s0,16(sp)
 7f4:	6125                	add	sp,sp,96
 7f6:	8082                	ret

00000000000007f8 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 7f8:	1141                	add	sp,sp,-16
 7fa:	e422                	sd	s0,8(sp)
 7fc:	0800                	add	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 7fe:	ff050693          	add	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 802:	00000797          	auipc	a5,0x0
 806:	7fe7b783          	ld	a5,2046(a5) # 1000 <freep>
 80a:	a02d                	j	834 <free+0x3c>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 80c:	4618                	lw	a4,8(a2)
 80e:	9f2d                	addw	a4,a4,a1
 810:	fee52c23          	sw	a4,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 814:	6398                	ld	a4,0(a5)
 816:	6310                	ld	a2,0(a4)
 818:	a83d                	j	856 <free+0x5e>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 81a:	ff852703          	lw	a4,-8(a0)
 81e:	9f31                	addw	a4,a4,a2
 820:	c798                	sw	a4,8(a5)
    p->s.ptr = bp->s.ptr;
 822:	ff053683          	ld	a3,-16(a0)
 826:	a091                	j	86a <free+0x72>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 828:	6398                	ld	a4,0(a5)
 82a:	00e7e463          	bltu	a5,a4,832 <free+0x3a>
 82e:	00e6ea63          	bltu	a3,a4,842 <free+0x4a>
{
 832:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 834:	fed7fae3          	bgeu	a5,a3,828 <free+0x30>
 838:	6398                	ld	a4,0(a5)
 83a:	00e6e463          	bltu	a3,a4,842 <free+0x4a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 83e:	fee7eae3          	bltu	a5,a4,832 <free+0x3a>
  if(bp + bp->s.size == p->s.ptr){
 842:	ff852583          	lw	a1,-8(a0)
 846:	6390                	ld	a2,0(a5)
 848:	02059813          	sll	a6,a1,0x20
 84c:	01c85713          	srl	a4,a6,0x1c
 850:	9736                	add	a4,a4,a3
 852:	fae60de3          	beq	a2,a4,80c <free+0x14>
    bp->s.ptr = p->s.ptr->s.ptr;
 856:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 85a:	4790                	lw	a2,8(a5)
 85c:	02061593          	sll	a1,a2,0x20
 860:	01c5d713          	srl	a4,a1,0x1c
 864:	973e                	add	a4,a4,a5
 866:	fae68ae3          	beq	a3,a4,81a <free+0x22>
    p->s.ptr = bp->s.ptr;
 86a:	e394                	sd	a3,0(a5)
  } else
    p->s.ptr = bp;
  freep = p;
 86c:	00000717          	auipc	a4,0x0
 870:	78f73a23          	sd	a5,1940(a4) # 1000 <freep>
}
 874:	6422                	ld	s0,8(sp)
 876:	0141                	add	sp,sp,16
 878:	8082                	ret

000000000000087a <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 87a:	7139                	add	sp,sp,-64
 87c:	fc06                	sd	ra,56(sp)
 87e:	f822                	sd	s0,48(sp)
 880:	f426                	sd	s1,40(sp)
 882:	f04a                	sd	s2,32(sp)
 884:	ec4e                	sd	s3,24(sp)
 886:	e852                	sd	s4,16(sp)
 888:	e456                	sd	s5,8(sp)
 88a:	e05a                	sd	s6,0(sp)
 88c:	0080                	add	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 88e:	02051493          	sll	s1,a0,0x20
 892:	9081                	srl	s1,s1,0x20
 894:	04bd                	add	s1,s1,15
 896:	8091                	srl	s1,s1,0x4
 898:	0014899b          	addw	s3,s1,1
 89c:	0485                	add	s1,s1,1
  if((prevp = freep) == 0){
 89e:	00000517          	auipc	a0,0x0
 8a2:	76253503          	ld	a0,1890(a0) # 1000 <freep>
 8a6:	c515                	beqz	a0,8d2 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 8a8:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 8aa:	4798                	lw	a4,8(a5)
 8ac:	02977f63          	bgeu	a4,s1,8ea <malloc+0x70>
  if(nu < 4096)
 8b0:	8a4e                	mv	s4,s3
 8b2:	0009871b          	sext.w	a4,s3
 8b6:	6685                	lui	a3,0x1
 8b8:	00d77363          	bgeu	a4,a3,8be <malloc+0x44>
 8bc:	6a05                	lui	s4,0x1
 8be:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 8c2:	004a1a1b          	sllw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 8c6:	00000917          	auipc	s2,0x0
 8ca:	73a90913          	add	s2,s2,1850 # 1000 <freep>
  if(p == (char*)-1)
 8ce:	5afd                	li	s5,-1
 8d0:	a895                	j	944 <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 8d2:	00000797          	auipc	a5,0x0
 8d6:	77e78793          	add	a5,a5,1918 # 1050 <base>
 8da:	00000717          	auipc	a4,0x0
 8de:	72f73323          	sd	a5,1830(a4) # 1000 <freep>
 8e2:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 8e4:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 8e8:	b7e1                	j	8b0 <malloc+0x36>
      if(p->s.size == nunits)
 8ea:	02e48c63          	beq	s1,a4,922 <malloc+0xa8>
        p->s.size -= nunits;
 8ee:	4137073b          	subw	a4,a4,s3
 8f2:	c798                	sw	a4,8(a5)
        p += p->s.size;
 8f4:	02071693          	sll	a3,a4,0x20
 8f8:	01c6d713          	srl	a4,a3,0x1c
 8fc:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 8fe:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 902:	00000717          	auipc	a4,0x0
 906:	6ea73f23          	sd	a0,1790(a4) # 1000 <freep>
      return (void*)(p + 1);
 90a:	01078513          	add	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 90e:	70e2                	ld	ra,56(sp)
 910:	7442                	ld	s0,48(sp)
 912:	74a2                	ld	s1,40(sp)
 914:	7902                	ld	s2,32(sp)
 916:	69e2                	ld	s3,24(sp)
 918:	6a42                	ld	s4,16(sp)
 91a:	6aa2                	ld	s5,8(sp)
 91c:	6b02                	ld	s6,0(sp)
 91e:	6121                	add	sp,sp,64
 920:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 922:	6398                	ld	a4,0(a5)
 924:	e118                	sd	a4,0(a0)
 926:	bff1                	j	902 <malloc+0x88>
  hp->s.size = nu;
 928:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 92c:	0541                	add	a0,a0,16
 92e:	00000097          	auipc	ra,0x0
 932:	eca080e7          	jalr	-310(ra) # 7f8 <free>
  return freep;
 936:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 93a:	d971                	beqz	a0,90e <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 93c:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 93e:	4798                	lw	a4,8(a5)
 940:	fa9775e3          	bgeu	a4,s1,8ea <malloc+0x70>
    if(p == freep)
 944:	00093703          	ld	a4,0(s2)
 948:	853e                	mv	a0,a5
 94a:	fef719e3          	bne	a4,a5,93c <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 94e:	8552                	mv	a0,s4
 950:	00000097          	auipc	ra,0x0
 954:	b92080e7          	jalr	-1134(ra) # 4e2 <sbrk>
  if(p == (char*)-1)
 958:	fd5518e3          	bne	a0,s5,928 <malloc+0xae>
        return 0;
 95c:	4501                	li	a0,0
 95e:	bf45                	j	90e <malloc+0x94>
