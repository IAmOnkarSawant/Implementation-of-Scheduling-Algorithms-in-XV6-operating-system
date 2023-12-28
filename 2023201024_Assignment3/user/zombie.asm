
user/_zombie:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:
#include "kernel/stat.h"
#include "user/user.h"

int
main(void)
{
   0:	1141                	addi	sp,sp,-16
   2:	e406                	sd	ra,8(sp)
   4:	e022                	sd	s0,0(sp)
   6:	0800                	addi	s0,sp,16
  if(fork() > 0)
   8:	00000097          	auipc	ra,0x0
   c:	2a0080e7          	jalr	672(ra) # 2a8 <fork>
  10:	00a04763          	bgtz	a0,1e <main+0x1e>
    sleep(5);  // Let child exit before parent.
  exit(0);
  14:	4501                	li	a0,0
  16:	00000097          	auipc	ra,0x0
  1a:	29a080e7          	jalr	666(ra) # 2b0 <exit>
    sleep(5);  // Let child exit before parent.
  1e:	4515                	li	a0,5
  20:	00000097          	auipc	ra,0x0
  24:	320080e7          	jalr	800(ra) # 340 <sleep>
  28:	b7f5                	j	14 <main+0x14>

000000000000002a <_main>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
_main()
{
  2a:	1141                	addi	sp,sp,-16
  2c:	e406                	sd	ra,8(sp)
  2e:	e022                	sd	s0,0(sp)
  30:	0800                	addi	s0,sp,16
  extern int main();
  main();
  32:	00000097          	auipc	ra,0x0
  36:	fce080e7          	jalr	-50(ra) # 0 <main>
  exit(0);
  3a:	4501                	li	a0,0
  3c:	00000097          	auipc	ra,0x0
  40:	274080e7          	jalr	628(ra) # 2b0 <exit>

0000000000000044 <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
  44:	1141                	addi	sp,sp,-16
  46:	e422                	sd	s0,8(sp)
  48:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  4a:	87aa                	mv	a5,a0
  4c:	0585                	addi	a1,a1,1
  4e:	0785                	addi	a5,a5,1
  50:	fff5c703          	lbu	a4,-1(a1)
  54:	fee78fa3          	sb	a4,-1(a5)
  58:	fb75                	bnez	a4,4c <strcpy+0x8>
    ;
  return os;
}
  5a:	6422                	ld	s0,8(sp)
  5c:	0141                	addi	sp,sp,16
  5e:	8082                	ret

0000000000000060 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  60:	1141                	addi	sp,sp,-16
  62:	e422                	sd	s0,8(sp)
  64:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
  66:	00054783          	lbu	a5,0(a0)
  6a:	cb91                	beqz	a5,7e <strcmp+0x1e>
  6c:	0005c703          	lbu	a4,0(a1)
  70:	00f71763          	bne	a4,a5,7e <strcmp+0x1e>
    p++, q++;
  74:	0505                	addi	a0,a0,1
  76:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
  78:	00054783          	lbu	a5,0(a0)
  7c:	fbe5                	bnez	a5,6c <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
  7e:	0005c503          	lbu	a0,0(a1)
}
  82:	40a7853b          	subw	a0,a5,a0
  86:	6422                	ld	s0,8(sp)
  88:	0141                	addi	sp,sp,16
  8a:	8082                	ret

000000000000008c <strlen>:

uint
strlen(const char *s)
{
  8c:	1141                	addi	sp,sp,-16
  8e:	e422                	sd	s0,8(sp)
  90:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
  92:	00054783          	lbu	a5,0(a0)
  96:	cf91                	beqz	a5,b2 <strlen+0x26>
  98:	0505                	addi	a0,a0,1
  9a:	87aa                	mv	a5,a0
  9c:	4685                	li	a3,1
  9e:	9e89                	subw	a3,a3,a0
  a0:	00f6853b          	addw	a0,a3,a5
  a4:	0785                	addi	a5,a5,1
  a6:	fff7c703          	lbu	a4,-1(a5)
  aa:	fb7d                	bnez	a4,a0 <strlen+0x14>
    ;
  return n;
}
  ac:	6422                	ld	s0,8(sp)
  ae:	0141                	addi	sp,sp,16
  b0:	8082                	ret
  for(n = 0; s[n]; n++)
  b2:	4501                	li	a0,0
  b4:	bfe5                	j	ac <strlen+0x20>

00000000000000b6 <memset>:

void*
memset(void *dst, int c, uint n)
{
  b6:	1141                	addi	sp,sp,-16
  b8:	e422                	sd	s0,8(sp)
  ba:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
  bc:	ca19                	beqz	a2,d2 <memset+0x1c>
  be:	87aa                	mv	a5,a0
  c0:	1602                	slli	a2,a2,0x20
  c2:	9201                	srli	a2,a2,0x20
  c4:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
  c8:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
  cc:	0785                	addi	a5,a5,1
  ce:	fee79de3          	bne	a5,a4,c8 <memset+0x12>
  }
  return dst;
}
  d2:	6422                	ld	s0,8(sp)
  d4:	0141                	addi	sp,sp,16
  d6:	8082                	ret

00000000000000d8 <strchr>:

char*
strchr(const char *s, char c)
{
  d8:	1141                	addi	sp,sp,-16
  da:	e422                	sd	s0,8(sp)
  dc:	0800                	addi	s0,sp,16
  for(; *s; s++)
  de:	00054783          	lbu	a5,0(a0)
  e2:	cb99                	beqz	a5,f8 <strchr+0x20>
    if(*s == c)
  e4:	00f58763          	beq	a1,a5,f2 <strchr+0x1a>
  for(; *s; s++)
  e8:	0505                	addi	a0,a0,1
  ea:	00054783          	lbu	a5,0(a0)
  ee:	fbfd                	bnez	a5,e4 <strchr+0xc>
      return (char*)s;
  return 0;
  f0:	4501                	li	a0,0
}
  f2:	6422                	ld	s0,8(sp)
  f4:	0141                	addi	sp,sp,16
  f6:	8082                	ret
  return 0;
  f8:	4501                	li	a0,0
  fa:	bfe5                	j	f2 <strchr+0x1a>

00000000000000fc <gets>:

char*
gets(char *buf, int max)
{
  fc:	711d                	addi	sp,sp,-96
  fe:	ec86                	sd	ra,88(sp)
 100:	e8a2                	sd	s0,80(sp)
 102:	e4a6                	sd	s1,72(sp)
 104:	e0ca                	sd	s2,64(sp)
 106:	fc4e                	sd	s3,56(sp)
 108:	f852                	sd	s4,48(sp)
 10a:	f456                	sd	s5,40(sp)
 10c:	f05a                	sd	s6,32(sp)
 10e:	ec5e                	sd	s7,24(sp)
 110:	1080                	addi	s0,sp,96
 112:	8baa                	mv	s7,a0
 114:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 116:	892a                	mv	s2,a0
 118:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 11a:	4aa9                	li	s5,10
 11c:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 11e:	89a6                	mv	s3,s1
 120:	2485                	addiw	s1,s1,1
 122:	0344d863          	bge	s1,s4,152 <gets+0x56>
    cc = read(0, &c, 1);
 126:	4605                	li	a2,1
 128:	faf40593          	addi	a1,s0,-81
 12c:	4501                	li	a0,0
 12e:	00000097          	auipc	ra,0x0
 132:	19a080e7          	jalr	410(ra) # 2c8 <read>
    if(cc < 1)
 136:	00a05e63          	blez	a0,152 <gets+0x56>
    buf[i++] = c;
 13a:	faf44783          	lbu	a5,-81(s0)
 13e:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 142:	01578763          	beq	a5,s5,150 <gets+0x54>
 146:	0905                	addi	s2,s2,1
 148:	fd679be3          	bne	a5,s6,11e <gets+0x22>
  for(i=0; i+1 < max; ){
 14c:	89a6                	mv	s3,s1
 14e:	a011                	j	152 <gets+0x56>
 150:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 152:	99de                	add	s3,s3,s7
 154:	00098023          	sb	zero,0(s3)
  return buf;
}
 158:	855e                	mv	a0,s7
 15a:	60e6                	ld	ra,88(sp)
 15c:	6446                	ld	s0,80(sp)
 15e:	64a6                	ld	s1,72(sp)
 160:	6906                	ld	s2,64(sp)
 162:	79e2                	ld	s3,56(sp)
 164:	7a42                	ld	s4,48(sp)
 166:	7aa2                	ld	s5,40(sp)
 168:	7b02                	ld	s6,32(sp)
 16a:	6be2                	ld	s7,24(sp)
 16c:	6125                	addi	sp,sp,96
 16e:	8082                	ret

0000000000000170 <stat>:

int
stat(const char *n, struct stat *st)
{
 170:	1101                	addi	sp,sp,-32
 172:	ec06                	sd	ra,24(sp)
 174:	e822                	sd	s0,16(sp)
 176:	e426                	sd	s1,8(sp)
 178:	e04a                	sd	s2,0(sp)
 17a:	1000                	addi	s0,sp,32
 17c:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 17e:	4581                	li	a1,0
 180:	00000097          	auipc	ra,0x0
 184:	170080e7          	jalr	368(ra) # 2f0 <open>
  if(fd < 0)
 188:	02054563          	bltz	a0,1b2 <stat+0x42>
 18c:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 18e:	85ca                	mv	a1,s2
 190:	00000097          	auipc	ra,0x0
 194:	178080e7          	jalr	376(ra) # 308 <fstat>
 198:	892a                	mv	s2,a0
  close(fd);
 19a:	8526                	mv	a0,s1
 19c:	00000097          	auipc	ra,0x0
 1a0:	13c080e7          	jalr	316(ra) # 2d8 <close>
  return r;
}
 1a4:	854a                	mv	a0,s2
 1a6:	60e2                	ld	ra,24(sp)
 1a8:	6442                	ld	s0,16(sp)
 1aa:	64a2                	ld	s1,8(sp)
 1ac:	6902                	ld	s2,0(sp)
 1ae:	6105                	addi	sp,sp,32
 1b0:	8082                	ret
    return -1;
 1b2:	597d                	li	s2,-1
 1b4:	bfc5                	j	1a4 <stat+0x34>

00000000000001b6 <atoi>:

int
atoi(const char *s)
{
 1b6:	1141                	addi	sp,sp,-16
 1b8:	e422                	sd	s0,8(sp)
 1ba:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 1bc:	00054683          	lbu	a3,0(a0)
 1c0:	fd06879b          	addiw	a5,a3,-48
 1c4:	0ff7f793          	zext.b	a5,a5
 1c8:	4625                	li	a2,9
 1ca:	02f66863          	bltu	a2,a5,1fa <atoi+0x44>
 1ce:	872a                	mv	a4,a0
  n = 0;
 1d0:	4501                	li	a0,0
    n = n*10 + *s++ - '0';
 1d2:	0705                	addi	a4,a4,1
 1d4:	0025179b          	slliw	a5,a0,0x2
 1d8:	9fa9                	addw	a5,a5,a0
 1da:	0017979b          	slliw	a5,a5,0x1
 1de:	9fb5                	addw	a5,a5,a3
 1e0:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 1e4:	00074683          	lbu	a3,0(a4)
 1e8:	fd06879b          	addiw	a5,a3,-48
 1ec:	0ff7f793          	zext.b	a5,a5
 1f0:	fef671e3          	bgeu	a2,a5,1d2 <atoi+0x1c>
  return n;
}
 1f4:	6422                	ld	s0,8(sp)
 1f6:	0141                	addi	sp,sp,16
 1f8:	8082                	ret
  n = 0;
 1fa:	4501                	li	a0,0
 1fc:	bfe5                	j	1f4 <atoi+0x3e>

00000000000001fe <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 1fe:	1141                	addi	sp,sp,-16
 200:	e422                	sd	s0,8(sp)
 202:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 204:	02b57463          	bgeu	a0,a1,22c <memmove+0x2e>
    while(n-- > 0)
 208:	00c05f63          	blez	a2,226 <memmove+0x28>
 20c:	1602                	slli	a2,a2,0x20
 20e:	9201                	srli	a2,a2,0x20
 210:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 214:	872a                	mv	a4,a0
      *dst++ = *src++;
 216:	0585                	addi	a1,a1,1
 218:	0705                	addi	a4,a4,1
 21a:	fff5c683          	lbu	a3,-1(a1)
 21e:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 222:	fee79ae3          	bne	a5,a4,216 <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 226:	6422                	ld	s0,8(sp)
 228:	0141                	addi	sp,sp,16
 22a:	8082                	ret
    dst += n;
 22c:	00c50733          	add	a4,a0,a2
    src += n;
 230:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 232:	fec05ae3          	blez	a2,226 <memmove+0x28>
 236:	fff6079b          	addiw	a5,a2,-1
 23a:	1782                	slli	a5,a5,0x20
 23c:	9381                	srli	a5,a5,0x20
 23e:	fff7c793          	not	a5,a5
 242:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 244:	15fd                	addi	a1,a1,-1
 246:	177d                	addi	a4,a4,-1
 248:	0005c683          	lbu	a3,0(a1)
 24c:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 250:	fee79ae3          	bne	a5,a4,244 <memmove+0x46>
 254:	bfc9                	j	226 <memmove+0x28>

0000000000000256 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 256:	1141                	addi	sp,sp,-16
 258:	e422                	sd	s0,8(sp)
 25a:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 25c:	ca05                	beqz	a2,28c <memcmp+0x36>
 25e:	fff6069b          	addiw	a3,a2,-1
 262:	1682                	slli	a3,a3,0x20
 264:	9281                	srli	a3,a3,0x20
 266:	0685                	addi	a3,a3,1
 268:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 26a:	00054783          	lbu	a5,0(a0)
 26e:	0005c703          	lbu	a4,0(a1)
 272:	00e79863          	bne	a5,a4,282 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 276:	0505                	addi	a0,a0,1
    p2++;
 278:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 27a:	fed518e3          	bne	a0,a3,26a <memcmp+0x14>
  }
  return 0;
 27e:	4501                	li	a0,0
 280:	a019                	j	286 <memcmp+0x30>
      return *p1 - *p2;
 282:	40e7853b          	subw	a0,a5,a4
}
 286:	6422                	ld	s0,8(sp)
 288:	0141                	addi	sp,sp,16
 28a:	8082                	ret
  return 0;
 28c:	4501                	li	a0,0
 28e:	bfe5                	j	286 <memcmp+0x30>

0000000000000290 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 290:	1141                	addi	sp,sp,-16
 292:	e406                	sd	ra,8(sp)
 294:	e022                	sd	s0,0(sp)
 296:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 298:	00000097          	auipc	ra,0x0
 29c:	f66080e7          	jalr	-154(ra) # 1fe <memmove>
}
 2a0:	60a2                	ld	ra,8(sp)
 2a2:	6402                	ld	s0,0(sp)
 2a4:	0141                	addi	sp,sp,16
 2a6:	8082                	ret

00000000000002a8 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 2a8:	4885                	li	a7,1
 ecall
 2aa:	00000073          	ecall
 ret
 2ae:	8082                	ret

00000000000002b0 <exit>:
.global exit
exit:
 li a7, SYS_exit
 2b0:	4889                	li	a7,2
 ecall
 2b2:	00000073          	ecall
 ret
 2b6:	8082                	ret

00000000000002b8 <wait>:
.global wait
wait:
 li a7, SYS_wait
 2b8:	488d                	li	a7,3
 ecall
 2ba:	00000073          	ecall
 ret
 2be:	8082                	ret

00000000000002c0 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 2c0:	4891                	li	a7,4
 ecall
 2c2:	00000073          	ecall
 ret
 2c6:	8082                	ret

00000000000002c8 <read>:
.global read
read:
 li a7, SYS_read
 2c8:	4895                	li	a7,5
 ecall
 2ca:	00000073          	ecall
 ret
 2ce:	8082                	ret

00000000000002d0 <write>:
.global write
write:
 li a7, SYS_write
 2d0:	48c1                	li	a7,16
 ecall
 2d2:	00000073          	ecall
 ret
 2d6:	8082                	ret

00000000000002d8 <close>:
.global close
close:
 li a7, SYS_close
 2d8:	48d5                	li	a7,21
 ecall
 2da:	00000073          	ecall
 ret
 2de:	8082                	ret

00000000000002e0 <kill>:
.global kill
kill:
 li a7, SYS_kill
 2e0:	4899                	li	a7,6
 ecall
 2e2:	00000073          	ecall
 ret
 2e6:	8082                	ret

00000000000002e8 <exec>:
.global exec
exec:
 li a7, SYS_exec
 2e8:	489d                	li	a7,7
 ecall
 2ea:	00000073          	ecall
 ret
 2ee:	8082                	ret

00000000000002f0 <open>:
.global open
open:
 li a7, SYS_open
 2f0:	48bd                	li	a7,15
 ecall
 2f2:	00000073          	ecall
 ret
 2f6:	8082                	ret

00000000000002f8 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 2f8:	48c5                	li	a7,17
 ecall
 2fa:	00000073          	ecall
 ret
 2fe:	8082                	ret

0000000000000300 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 300:	48c9                	li	a7,18
 ecall
 302:	00000073          	ecall
 ret
 306:	8082                	ret

0000000000000308 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 308:	48a1                	li	a7,8
 ecall
 30a:	00000073          	ecall
 ret
 30e:	8082                	ret

0000000000000310 <link>:
.global link
link:
 li a7, SYS_link
 310:	48cd                	li	a7,19
 ecall
 312:	00000073          	ecall
 ret
 316:	8082                	ret

0000000000000318 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 318:	48d1                	li	a7,20
 ecall
 31a:	00000073          	ecall
 ret
 31e:	8082                	ret

0000000000000320 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 320:	48a5                	li	a7,9
 ecall
 322:	00000073          	ecall
 ret
 326:	8082                	ret

0000000000000328 <dup>:
.global dup
dup:
 li a7, SYS_dup
 328:	48a9                	li	a7,10
 ecall
 32a:	00000073          	ecall
 ret
 32e:	8082                	ret

0000000000000330 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 330:	48ad                	li	a7,11
 ecall
 332:	00000073          	ecall
 ret
 336:	8082                	ret

0000000000000338 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 338:	48b1                	li	a7,12
 ecall
 33a:	00000073          	ecall
 ret
 33e:	8082                	ret

0000000000000340 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 340:	48b5                	li	a7,13
 ecall
 342:	00000073          	ecall
 ret
 346:	8082                	ret

0000000000000348 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 348:	48b9                	li	a7,14
 ecall
 34a:	00000073          	ecall
 ret
 34e:	8082                	ret

0000000000000350 <strace>:
.global strace
strace:
 li a7, SYS_strace
 350:	48d9                	li	a7,22
 ecall
 352:	00000073          	ecall
 ret
 356:	8082                	ret

0000000000000358 <waitx>:
.global waitx
waitx:
 li a7, SYS_waitx
 358:	48dd                	li	a7,23
 ecall
 35a:	00000073          	ecall
 ret
 35e:	8082                	ret

0000000000000360 <set_priority>:
.global set_priority
set_priority:
 li a7, SYS_set_priority
 360:	48e1                	li	a7,24
 ecall
 362:	00000073          	ecall
 ret
 366:	8082                	ret

0000000000000368 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 368:	1101                	addi	sp,sp,-32
 36a:	ec06                	sd	ra,24(sp)
 36c:	e822                	sd	s0,16(sp)
 36e:	1000                	addi	s0,sp,32
 370:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 374:	4605                	li	a2,1
 376:	fef40593          	addi	a1,s0,-17
 37a:	00000097          	auipc	ra,0x0
 37e:	f56080e7          	jalr	-170(ra) # 2d0 <write>
}
 382:	60e2                	ld	ra,24(sp)
 384:	6442                	ld	s0,16(sp)
 386:	6105                	addi	sp,sp,32
 388:	8082                	ret

000000000000038a <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 38a:	7139                	addi	sp,sp,-64
 38c:	fc06                	sd	ra,56(sp)
 38e:	f822                	sd	s0,48(sp)
 390:	f426                	sd	s1,40(sp)
 392:	f04a                	sd	s2,32(sp)
 394:	ec4e                	sd	s3,24(sp)
 396:	0080                	addi	s0,sp,64
 398:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 39a:	c299                	beqz	a3,3a0 <printint+0x16>
 39c:	0805c963          	bltz	a1,42e <printint+0xa4>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 3a0:	2581                	sext.w	a1,a1
  neg = 0;
 3a2:	4881                	li	a7,0
 3a4:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 3a8:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 3aa:	2601                	sext.w	a2,a2
 3ac:	00000517          	auipc	a0,0x0
 3b0:	49450513          	addi	a0,a0,1172 # 840 <digits>
 3b4:	883a                	mv	a6,a4
 3b6:	2705                	addiw	a4,a4,1
 3b8:	02c5f7bb          	remuw	a5,a1,a2
 3bc:	1782                	slli	a5,a5,0x20
 3be:	9381                	srli	a5,a5,0x20
 3c0:	97aa                	add	a5,a5,a0
 3c2:	0007c783          	lbu	a5,0(a5)
 3c6:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 3ca:	0005879b          	sext.w	a5,a1
 3ce:	02c5d5bb          	divuw	a1,a1,a2
 3d2:	0685                	addi	a3,a3,1
 3d4:	fec7f0e3          	bgeu	a5,a2,3b4 <printint+0x2a>
  if(neg)
 3d8:	00088c63          	beqz	a7,3f0 <printint+0x66>
    buf[i++] = '-';
 3dc:	fd070793          	addi	a5,a4,-48
 3e0:	00878733          	add	a4,a5,s0
 3e4:	02d00793          	li	a5,45
 3e8:	fef70823          	sb	a5,-16(a4)
 3ec:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 3f0:	02e05863          	blez	a4,420 <printint+0x96>
 3f4:	fc040793          	addi	a5,s0,-64
 3f8:	00e78933          	add	s2,a5,a4
 3fc:	fff78993          	addi	s3,a5,-1
 400:	99ba                	add	s3,s3,a4
 402:	377d                	addiw	a4,a4,-1
 404:	1702                	slli	a4,a4,0x20
 406:	9301                	srli	a4,a4,0x20
 408:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 40c:	fff94583          	lbu	a1,-1(s2)
 410:	8526                	mv	a0,s1
 412:	00000097          	auipc	ra,0x0
 416:	f56080e7          	jalr	-170(ra) # 368 <putc>
  while(--i >= 0)
 41a:	197d                	addi	s2,s2,-1
 41c:	ff3918e3          	bne	s2,s3,40c <printint+0x82>
}
 420:	70e2                	ld	ra,56(sp)
 422:	7442                	ld	s0,48(sp)
 424:	74a2                	ld	s1,40(sp)
 426:	7902                	ld	s2,32(sp)
 428:	69e2                	ld	s3,24(sp)
 42a:	6121                	addi	sp,sp,64
 42c:	8082                	ret
    x = -xx;
 42e:	40b005bb          	negw	a1,a1
    neg = 1;
 432:	4885                	li	a7,1
    x = -xx;
 434:	bf85                	j	3a4 <printint+0x1a>

0000000000000436 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 436:	7119                	addi	sp,sp,-128
 438:	fc86                	sd	ra,120(sp)
 43a:	f8a2                	sd	s0,112(sp)
 43c:	f4a6                	sd	s1,104(sp)
 43e:	f0ca                	sd	s2,96(sp)
 440:	ecce                	sd	s3,88(sp)
 442:	e8d2                	sd	s4,80(sp)
 444:	e4d6                	sd	s5,72(sp)
 446:	e0da                	sd	s6,64(sp)
 448:	fc5e                	sd	s7,56(sp)
 44a:	f862                	sd	s8,48(sp)
 44c:	f466                	sd	s9,40(sp)
 44e:	f06a                	sd	s10,32(sp)
 450:	ec6e                	sd	s11,24(sp)
 452:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 454:	0005c903          	lbu	s2,0(a1)
 458:	18090f63          	beqz	s2,5f6 <vprintf+0x1c0>
 45c:	8aaa                	mv	s5,a0
 45e:	8b32                	mv	s6,a2
 460:	00158493          	addi	s1,a1,1
  state = 0;
 464:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 466:	02500a13          	li	s4,37
 46a:	4c55                	li	s8,21
 46c:	00000c97          	auipc	s9,0x0
 470:	37cc8c93          	addi	s9,s9,892 # 7e8 <malloc+0xee>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
        s = va_arg(ap, char*);
        if(s == 0)
          s = "(null)";
        while(*s != 0){
 474:	02800d93          	li	s11,40
  putc(fd, 'x');
 478:	4d41                	li	s10,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 47a:	00000b97          	auipc	s7,0x0
 47e:	3c6b8b93          	addi	s7,s7,966 # 840 <digits>
 482:	a839                	j	4a0 <vprintf+0x6a>
        putc(fd, c);
 484:	85ca                	mv	a1,s2
 486:	8556                	mv	a0,s5
 488:	00000097          	auipc	ra,0x0
 48c:	ee0080e7          	jalr	-288(ra) # 368 <putc>
 490:	a019                	j	496 <vprintf+0x60>
    } else if(state == '%'){
 492:	01498d63          	beq	s3,s4,4ac <vprintf+0x76>
  for(i = 0; fmt[i]; i++){
 496:	0485                	addi	s1,s1,1
 498:	fff4c903          	lbu	s2,-1(s1)
 49c:	14090d63          	beqz	s2,5f6 <vprintf+0x1c0>
    if(state == 0){
 4a0:	fe0999e3          	bnez	s3,492 <vprintf+0x5c>
      if(c == '%'){
 4a4:	ff4910e3          	bne	s2,s4,484 <vprintf+0x4e>
        state = '%';
 4a8:	89d2                	mv	s3,s4
 4aa:	b7f5                	j	496 <vprintf+0x60>
      if(c == 'd'){
 4ac:	11490c63          	beq	s2,s4,5c4 <vprintf+0x18e>
 4b0:	f9d9079b          	addiw	a5,s2,-99
 4b4:	0ff7f793          	zext.b	a5,a5
 4b8:	10fc6e63          	bltu	s8,a5,5d4 <vprintf+0x19e>
 4bc:	f9d9079b          	addiw	a5,s2,-99
 4c0:	0ff7f713          	zext.b	a4,a5
 4c4:	10ec6863          	bltu	s8,a4,5d4 <vprintf+0x19e>
 4c8:	00271793          	slli	a5,a4,0x2
 4cc:	97e6                	add	a5,a5,s9
 4ce:	439c                	lw	a5,0(a5)
 4d0:	97e6                	add	a5,a5,s9
 4d2:	8782                	jr	a5
        printint(fd, va_arg(ap, int), 10, 1);
 4d4:	008b0913          	addi	s2,s6,8
 4d8:	4685                	li	a3,1
 4da:	4629                	li	a2,10
 4dc:	000b2583          	lw	a1,0(s6)
 4e0:	8556                	mv	a0,s5
 4e2:	00000097          	auipc	ra,0x0
 4e6:	ea8080e7          	jalr	-344(ra) # 38a <printint>
 4ea:	8b4a                	mv	s6,s2
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
        putc(fd, c);
      }
      state = 0;
 4ec:	4981                	li	s3,0
 4ee:	b765                	j	496 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 4f0:	008b0913          	addi	s2,s6,8
 4f4:	4681                	li	a3,0
 4f6:	4629                	li	a2,10
 4f8:	000b2583          	lw	a1,0(s6)
 4fc:	8556                	mv	a0,s5
 4fe:	00000097          	auipc	ra,0x0
 502:	e8c080e7          	jalr	-372(ra) # 38a <printint>
 506:	8b4a                	mv	s6,s2
      state = 0;
 508:	4981                	li	s3,0
 50a:	b771                	j	496 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 50c:	008b0913          	addi	s2,s6,8
 510:	4681                	li	a3,0
 512:	866a                	mv	a2,s10
 514:	000b2583          	lw	a1,0(s6)
 518:	8556                	mv	a0,s5
 51a:	00000097          	auipc	ra,0x0
 51e:	e70080e7          	jalr	-400(ra) # 38a <printint>
 522:	8b4a                	mv	s6,s2
      state = 0;
 524:	4981                	li	s3,0
 526:	bf85                	j	496 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 528:	008b0793          	addi	a5,s6,8
 52c:	f8f43423          	sd	a5,-120(s0)
 530:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 534:	03000593          	li	a1,48
 538:	8556                	mv	a0,s5
 53a:	00000097          	auipc	ra,0x0
 53e:	e2e080e7          	jalr	-466(ra) # 368 <putc>
  putc(fd, 'x');
 542:	07800593          	li	a1,120
 546:	8556                	mv	a0,s5
 548:	00000097          	auipc	ra,0x0
 54c:	e20080e7          	jalr	-480(ra) # 368 <putc>
 550:	896a                	mv	s2,s10
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 552:	03c9d793          	srli	a5,s3,0x3c
 556:	97de                	add	a5,a5,s7
 558:	0007c583          	lbu	a1,0(a5)
 55c:	8556                	mv	a0,s5
 55e:	00000097          	auipc	ra,0x0
 562:	e0a080e7          	jalr	-502(ra) # 368 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 566:	0992                	slli	s3,s3,0x4
 568:	397d                	addiw	s2,s2,-1
 56a:	fe0914e3          	bnez	s2,552 <vprintf+0x11c>
        printptr(fd, va_arg(ap, uint64));
 56e:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 572:	4981                	li	s3,0
 574:	b70d                	j	496 <vprintf+0x60>
        s = va_arg(ap, char*);
 576:	008b0913          	addi	s2,s6,8
 57a:	000b3983          	ld	s3,0(s6)
        if(s == 0)
 57e:	02098163          	beqz	s3,5a0 <vprintf+0x16a>
        while(*s != 0){
 582:	0009c583          	lbu	a1,0(s3)
 586:	c5ad                	beqz	a1,5f0 <vprintf+0x1ba>
          putc(fd, *s);
 588:	8556                	mv	a0,s5
 58a:	00000097          	auipc	ra,0x0
 58e:	dde080e7          	jalr	-546(ra) # 368 <putc>
          s++;
 592:	0985                	addi	s3,s3,1
        while(*s != 0){
 594:	0009c583          	lbu	a1,0(s3)
 598:	f9e5                	bnez	a1,588 <vprintf+0x152>
        s = va_arg(ap, char*);
 59a:	8b4a                	mv	s6,s2
      state = 0;
 59c:	4981                	li	s3,0
 59e:	bde5                	j	496 <vprintf+0x60>
          s = "(null)";
 5a0:	00000997          	auipc	s3,0x0
 5a4:	24098993          	addi	s3,s3,576 # 7e0 <malloc+0xe6>
        while(*s != 0){
 5a8:	85ee                	mv	a1,s11
 5aa:	bff9                	j	588 <vprintf+0x152>
        putc(fd, va_arg(ap, uint));
 5ac:	008b0913          	addi	s2,s6,8
 5b0:	000b4583          	lbu	a1,0(s6)
 5b4:	8556                	mv	a0,s5
 5b6:	00000097          	auipc	ra,0x0
 5ba:	db2080e7          	jalr	-590(ra) # 368 <putc>
 5be:	8b4a                	mv	s6,s2
      state = 0;
 5c0:	4981                	li	s3,0
 5c2:	bdd1                	j	496 <vprintf+0x60>
        putc(fd, c);
 5c4:	85d2                	mv	a1,s4
 5c6:	8556                	mv	a0,s5
 5c8:	00000097          	auipc	ra,0x0
 5cc:	da0080e7          	jalr	-608(ra) # 368 <putc>
      state = 0;
 5d0:	4981                	li	s3,0
 5d2:	b5d1                	j	496 <vprintf+0x60>
        putc(fd, '%');
 5d4:	85d2                	mv	a1,s4
 5d6:	8556                	mv	a0,s5
 5d8:	00000097          	auipc	ra,0x0
 5dc:	d90080e7          	jalr	-624(ra) # 368 <putc>
        putc(fd, c);
 5e0:	85ca                	mv	a1,s2
 5e2:	8556                	mv	a0,s5
 5e4:	00000097          	auipc	ra,0x0
 5e8:	d84080e7          	jalr	-636(ra) # 368 <putc>
      state = 0;
 5ec:	4981                	li	s3,0
 5ee:	b565                	j	496 <vprintf+0x60>
        s = va_arg(ap, char*);
 5f0:	8b4a                	mv	s6,s2
      state = 0;
 5f2:	4981                	li	s3,0
 5f4:	b54d                	j	496 <vprintf+0x60>
    }
  }
}
 5f6:	70e6                	ld	ra,120(sp)
 5f8:	7446                	ld	s0,112(sp)
 5fa:	74a6                	ld	s1,104(sp)
 5fc:	7906                	ld	s2,96(sp)
 5fe:	69e6                	ld	s3,88(sp)
 600:	6a46                	ld	s4,80(sp)
 602:	6aa6                	ld	s5,72(sp)
 604:	6b06                	ld	s6,64(sp)
 606:	7be2                	ld	s7,56(sp)
 608:	7c42                	ld	s8,48(sp)
 60a:	7ca2                	ld	s9,40(sp)
 60c:	7d02                	ld	s10,32(sp)
 60e:	6de2                	ld	s11,24(sp)
 610:	6109                	addi	sp,sp,128
 612:	8082                	ret

0000000000000614 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 614:	715d                	addi	sp,sp,-80
 616:	ec06                	sd	ra,24(sp)
 618:	e822                	sd	s0,16(sp)
 61a:	1000                	addi	s0,sp,32
 61c:	e010                	sd	a2,0(s0)
 61e:	e414                	sd	a3,8(s0)
 620:	e818                	sd	a4,16(s0)
 622:	ec1c                	sd	a5,24(s0)
 624:	03043023          	sd	a6,32(s0)
 628:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 62c:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 630:	8622                	mv	a2,s0
 632:	00000097          	auipc	ra,0x0
 636:	e04080e7          	jalr	-508(ra) # 436 <vprintf>
}
 63a:	60e2                	ld	ra,24(sp)
 63c:	6442                	ld	s0,16(sp)
 63e:	6161                	addi	sp,sp,80
 640:	8082                	ret

0000000000000642 <printf>:

void
printf(const char *fmt, ...)
{
 642:	711d                	addi	sp,sp,-96
 644:	ec06                	sd	ra,24(sp)
 646:	e822                	sd	s0,16(sp)
 648:	1000                	addi	s0,sp,32
 64a:	e40c                	sd	a1,8(s0)
 64c:	e810                	sd	a2,16(s0)
 64e:	ec14                	sd	a3,24(s0)
 650:	f018                	sd	a4,32(s0)
 652:	f41c                	sd	a5,40(s0)
 654:	03043823          	sd	a6,48(s0)
 658:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 65c:	00840613          	addi	a2,s0,8
 660:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 664:	85aa                	mv	a1,a0
 666:	4505                	li	a0,1
 668:	00000097          	auipc	ra,0x0
 66c:	dce080e7          	jalr	-562(ra) # 436 <vprintf>
}
 670:	60e2                	ld	ra,24(sp)
 672:	6442                	ld	s0,16(sp)
 674:	6125                	addi	sp,sp,96
 676:	8082                	ret

0000000000000678 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 678:	1141                	addi	sp,sp,-16
 67a:	e422                	sd	s0,8(sp)
 67c:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 67e:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 682:	00001797          	auipc	a5,0x1
 686:	97e7b783          	ld	a5,-1666(a5) # 1000 <freep>
 68a:	a02d                	j	6b4 <free+0x3c>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 68c:	4618                	lw	a4,8(a2)
 68e:	9f2d                	addw	a4,a4,a1
 690:	fee52c23          	sw	a4,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 694:	6398                	ld	a4,0(a5)
 696:	6310                	ld	a2,0(a4)
 698:	a83d                	j	6d6 <free+0x5e>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 69a:	ff852703          	lw	a4,-8(a0)
 69e:	9f31                	addw	a4,a4,a2
 6a0:	c798                	sw	a4,8(a5)
    p->s.ptr = bp->s.ptr;
 6a2:	ff053683          	ld	a3,-16(a0)
 6a6:	a091                	j	6ea <free+0x72>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 6a8:	6398                	ld	a4,0(a5)
 6aa:	00e7e463          	bltu	a5,a4,6b2 <free+0x3a>
 6ae:	00e6ea63          	bltu	a3,a4,6c2 <free+0x4a>
{
 6b2:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 6b4:	fed7fae3          	bgeu	a5,a3,6a8 <free+0x30>
 6b8:	6398                	ld	a4,0(a5)
 6ba:	00e6e463          	bltu	a3,a4,6c2 <free+0x4a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 6be:	fee7eae3          	bltu	a5,a4,6b2 <free+0x3a>
  if(bp + bp->s.size == p->s.ptr){
 6c2:	ff852583          	lw	a1,-8(a0)
 6c6:	6390                	ld	a2,0(a5)
 6c8:	02059813          	slli	a6,a1,0x20
 6cc:	01c85713          	srli	a4,a6,0x1c
 6d0:	9736                	add	a4,a4,a3
 6d2:	fae60de3          	beq	a2,a4,68c <free+0x14>
    bp->s.ptr = p->s.ptr->s.ptr;
 6d6:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 6da:	4790                	lw	a2,8(a5)
 6dc:	02061593          	slli	a1,a2,0x20
 6e0:	01c5d713          	srli	a4,a1,0x1c
 6e4:	973e                	add	a4,a4,a5
 6e6:	fae68ae3          	beq	a3,a4,69a <free+0x22>
    p->s.ptr = bp->s.ptr;
 6ea:	e394                	sd	a3,0(a5)
  } else
    p->s.ptr = bp;
  freep = p;
 6ec:	00001717          	auipc	a4,0x1
 6f0:	90f73a23          	sd	a5,-1772(a4) # 1000 <freep>
}
 6f4:	6422                	ld	s0,8(sp)
 6f6:	0141                	addi	sp,sp,16
 6f8:	8082                	ret

00000000000006fa <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 6fa:	7139                	addi	sp,sp,-64
 6fc:	fc06                	sd	ra,56(sp)
 6fe:	f822                	sd	s0,48(sp)
 700:	f426                	sd	s1,40(sp)
 702:	f04a                	sd	s2,32(sp)
 704:	ec4e                	sd	s3,24(sp)
 706:	e852                	sd	s4,16(sp)
 708:	e456                	sd	s5,8(sp)
 70a:	e05a                	sd	s6,0(sp)
 70c:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 70e:	02051493          	slli	s1,a0,0x20
 712:	9081                	srli	s1,s1,0x20
 714:	04bd                	addi	s1,s1,15
 716:	8091                	srli	s1,s1,0x4
 718:	0014899b          	addiw	s3,s1,1
 71c:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 71e:	00001517          	auipc	a0,0x1
 722:	8e253503          	ld	a0,-1822(a0) # 1000 <freep>
 726:	c515                	beqz	a0,752 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 728:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 72a:	4798                	lw	a4,8(a5)
 72c:	02977f63          	bgeu	a4,s1,76a <malloc+0x70>
 730:	8a4e                	mv	s4,s3
 732:	0009871b          	sext.w	a4,s3
 736:	6685                	lui	a3,0x1
 738:	00d77363          	bgeu	a4,a3,73e <malloc+0x44>
 73c:	6a05                	lui	s4,0x1
 73e:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 742:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 746:	00001917          	auipc	s2,0x1
 74a:	8ba90913          	addi	s2,s2,-1862 # 1000 <freep>
  if(p == (char*)-1)
 74e:	5afd                	li	s5,-1
 750:	a895                	j	7c4 <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 752:	00001797          	auipc	a5,0x1
 756:	8be78793          	addi	a5,a5,-1858 # 1010 <base>
 75a:	00001717          	auipc	a4,0x1
 75e:	8af73323          	sd	a5,-1882(a4) # 1000 <freep>
 762:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 764:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 768:	b7e1                	j	730 <malloc+0x36>
      if(p->s.size == nunits)
 76a:	02e48c63          	beq	s1,a4,7a2 <malloc+0xa8>
        p->s.size -= nunits;
 76e:	4137073b          	subw	a4,a4,s3
 772:	c798                	sw	a4,8(a5)
        p += p->s.size;
 774:	02071693          	slli	a3,a4,0x20
 778:	01c6d713          	srli	a4,a3,0x1c
 77c:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 77e:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 782:	00001717          	auipc	a4,0x1
 786:	86a73f23          	sd	a0,-1922(a4) # 1000 <freep>
      return (void*)(p + 1);
 78a:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 78e:	70e2                	ld	ra,56(sp)
 790:	7442                	ld	s0,48(sp)
 792:	74a2                	ld	s1,40(sp)
 794:	7902                	ld	s2,32(sp)
 796:	69e2                	ld	s3,24(sp)
 798:	6a42                	ld	s4,16(sp)
 79a:	6aa2                	ld	s5,8(sp)
 79c:	6b02                	ld	s6,0(sp)
 79e:	6121                	addi	sp,sp,64
 7a0:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 7a2:	6398                	ld	a4,0(a5)
 7a4:	e118                	sd	a4,0(a0)
 7a6:	bff1                	j	782 <malloc+0x88>
  hp->s.size = nu;
 7a8:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 7ac:	0541                	addi	a0,a0,16
 7ae:	00000097          	auipc	ra,0x0
 7b2:	eca080e7          	jalr	-310(ra) # 678 <free>
  return freep;
 7b6:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 7ba:	d971                	beqz	a0,78e <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 7bc:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 7be:	4798                	lw	a4,8(a5)
 7c0:	fa9775e3          	bgeu	a4,s1,76a <malloc+0x70>
    if(p == freep)
 7c4:	00093703          	ld	a4,0(s2)
 7c8:	853e                	mv	a0,a5
 7ca:	fef719e3          	bne	a4,a5,7bc <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 7ce:	8552                	mv	a0,s4
 7d0:	00000097          	auipc	ra,0x0
 7d4:	b68080e7          	jalr	-1176(ra) # 338 <sbrk>
  if(p == (char*)-1)
 7d8:	fd5518e3          	bne	a0,s5,7a8 <malloc+0xae>
        return 0;
 7dc:	4501                	li	a0,0
 7de:	bf45                	j	78e <malloc+0x94>
