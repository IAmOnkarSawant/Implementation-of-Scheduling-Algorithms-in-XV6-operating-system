
user/_kill:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:
#include "kernel/stat.h"
#include "user/user.h"

int
main(int argc, char **argv)
{
   0:	1101                	addi	sp,sp,-32
   2:	ec06                	sd	ra,24(sp)
   4:	e822                	sd	s0,16(sp)
   6:	e426                	sd	s1,8(sp)
   8:	e04a                	sd	s2,0(sp)
   a:	1000                	addi	s0,sp,32
  int i;

  if(argc < 2){
   c:	4785                	li	a5,1
   e:	02a7dd63          	bge	a5,a0,48 <main+0x48>
  12:	00858493          	addi	s1,a1,8
  16:	ffe5091b          	addiw	s2,a0,-2
  1a:	02091793          	slli	a5,s2,0x20
  1e:	01d7d913          	srli	s2,a5,0x1d
  22:	05c1                	addi	a1,a1,16
  24:	992e                	add	s2,s2,a1
    fprintf(2, "usage: kill pid...\n");
    exit(1);
  }
  for(i=1; i<argc; i++)
    kill(atoi(argv[i]));
  26:	6088                	ld	a0,0(s1)
  28:	00000097          	auipc	ra,0x0
  2c:	1c8080e7          	jalr	456(ra) # 1f0 <atoi>
  30:	00000097          	auipc	ra,0x0
  34:	2ea080e7          	jalr	746(ra) # 31a <kill>
  for(i=1; i<argc; i++)
  38:	04a1                	addi	s1,s1,8
  3a:	ff2496e3          	bne	s1,s2,26 <main+0x26>
  exit(0);
  3e:	4501                	li	a0,0
  40:	00000097          	auipc	ra,0x0
  44:	2aa080e7          	jalr	682(ra) # 2ea <exit>
    fprintf(2, "usage: kill pid...\n");
  48:	00000597          	auipc	a1,0x0
  4c:	7d858593          	addi	a1,a1,2008 # 820 <malloc+0xec>
  50:	4509                	li	a0,2
  52:	00000097          	auipc	ra,0x0
  56:	5fc080e7          	jalr	1532(ra) # 64e <fprintf>
    exit(1);
  5a:	4505                	li	a0,1
  5c:	00000097          	auipc	ra,0x0
  60:	28e080e7          	jalr	654(ra) # 2ea <exit>

0000000000000064 <_main>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
_main()
{
  64:	1141                	addi	sp,sp,-16
  66:	e406                	sd	ra,8(sp)
  68:	e022                	sd	s0,0(sp)
  6a:	0800                	addi	s0,sp,16
  extern int main();
  main();
  6c:	00000097          	auipc	ra,0x0
  70:	f94080e7          	jalr	-108(ra) # 0 <main>
  exit(0);
  74:	4501                	li	a0,0
  76:	00000097          	auipc	ra,0x0
  7a:	274080e7          	jalr	628(ra) # 2ea <exit>

000000000000007e <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
  7e:	1141                	addi	sp,sp,-16
  80:	e422                	sd	s0,8(sp)
  82:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  84:	87aa                	mv	a5,a0
  86:	0585                	addi	a1,a1,1
  88:	0785                	addi	a5,a5,1
  8a:	fff5c703          	lbu	a4,-1(a1)
  8e:	fee78fa3          	sb	a4,-1(a5)
  92:	fb75                	bnez	a4,86 <strcpy+0x8>
    ;
  return os;
}
  94:	6422                	ld	s0,8(sp)
  96:	0141                	addi	sp,sp,16
  98:	8082                	ret

000000000000009a <strcmp>:

int
strcmp(const char *p, const char *q)
{
  9a:	1141                	addi	sp,sp,-16
  9c:	e422                	sd	s0,8(sp)
  9e:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
  a0:	00054783          	lbu	a5,0(a0)
  a4:	cb91                	beqz	a5,b8 <strcmp+0x1e>
  a6:	0005c703          	lbu	a4,0(a1)
  aa:	00f71763          	bne	a4,a5,b8 <strcmp+0x1e>
    p++, q++;
  ae:	0505                	addi	a0,a0,1
  b0:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
  b2:	00054783          	lbu	a5,0(a0)
  b6:	fbe5                	bnez	a5,a6 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
  b8:	0005c503          	lbu	a0,0(a1)
}
  bc:	40a7853b          	subw	a0,a5,a0
  c0:	6422                	ld	s0,8(sp)
  c2:	0141                	addi	sp,sp,16
  c4:	8082                	ret

00000000000000c6 <strlen>:

uint
strlen(const char *s)
{
  c6:	1141                	addi	sp,sp,-16
  c8:	e422                	sd	s0,8(sp)
  ca:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
  cc:	00054783          	lbu	a5,0(a0)
  d0:	cf91                	beqz	a5,ec <strlen+0x26>
  d2:	0505                	addi	a0,a0,1
  d4:	87aa                	mv	a5,a0
  d6:	4685                	li	a3,1
  d8:	9e89                	subw	a3,a3,a0
  da:	00f6853b          	addw	a0,a3,a5
  de:	0785                	addi	a5,a5,1
  e0:	fff7c703          	lbu	a4,-1(a5)
  e4:	fb7d                	bnez	a4,da <strlen+0x14>
    ;
  return n;
}
  e6:	6422                	ld	s0,8(sp)
  e8:	0141                	addi	sp,sp,16
  ea:	8082                	ret
  for(n = 0; s[n]; n++)
  ec:	4501                	li	a0,0
  ee:	bfe5                	j	e6 <strlen+0x20>

00000000000000f0 <memset>:

void*
memset(void *dst, int c, uint n)
{
  f0:	1141                	addi	sp,sp,-16
  f2:	e422                	sd	s0,8(sp)
  f4:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
  f6:	ca19                	beqz	a2,10c <memset+0x1c>
  f8:	87aa                	mv	a5,a0
  fa:	1602                	slli	a2,a2,0x20
  fc:	9201                	srli	a2,a2,0x20
  fe:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 102:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 106:	0785                	addi	a5,a5,1
 108:	fee79de3          	bne	a5,a4,102 <memset+0x12>
  }
  return dst;
}
 10c:	6422                	ld	s0,8(sp)
 10e:	0141                	addi	sp,sp,16
 110:	8082                	ret

0000000000000112 <strchr>:

char*
strchr(const char *s, char c)
{
 112:	1141                	addi	sp,sp,-16
 114:	e422                	sd	s0,8(sp)
 116:	0800                	addi	s0,sp,16
  for(; *s; s++)
 118:	00054783          	lbu	a5,0(a0)
 11c:	cb99                	beqz	a5,132 <strchr+0x20>
    if(*s == c)
 11e:	00f58763          	beq	a1,a5,12c <strchr+0x1a>
  for(; *s; s++)
 122:	0505                	addi	a0,a0,1
 124:	00054783          	lbu	a5,0(a0)
 128:	fbfd                	bnez	a5,11e <strchr+0xc>
      return (char*)s;
  return 0;
 12a:	4501                	li	a0,0
}
 12c:	6422                	ld	s0,8(sp)
 12e:	0141                	addi	sp,sp,16
 130:	8082                	ret
  return 0;
 132:	4501                	li	a0,0
 134:	bfe5                	j	12c <strchr+0x1a>

0000000000000136 <gets>:

char*
gets(char *buf, int max)
{
 136:	711d                	addi	sp,sp,-96
 138:	ec86                	sd	ra,88(sp)
 13a:	e8a2                	sd	s0,80(sp)
 13c:	e4a6                	sd	s1,72(sp)
 13e:	e0ca                	sd	s2,64(sp)
 140:	fc4e                	sd	s3,56(sp)
 142:	f852                	sd	s4,48(sp)
 144:	f456                	sd	s5,40(sp)
 146:	f05a                	sd	s6,32(sp)
 148:	ec5e                	sd	s7,24(sp)
 14a:	1080                	addi	s0,sp,96
 14c:	8baa                	mv	s7,a0
 14e:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 150:	892a                	mv	s2,a0
 152:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 154:	4aa9                	li	s5,10
 156:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 158:	89a6                	mv	s3,s1
 15a:	2485                	addiw	s1,s1,1
 15c:	0344d863          	bge	s1,s4,18c <gets+0x56>
    cc = read(0, &c, 1);
 160:	4605                	li	a2,1
 162:	faf40593          	addi	a1,s0,-81
 166:	4501                	li	a0,0
 168:	00000097          	auipc	ra,0x0
 16c:	19a080e7          	jalr	410(ra) # 302 <read>
    if(cc < 1)
 170:	00a05e63          	blez	a0,18c <gets+0x56>
    buf[i++] = c;
 174:	faf44783          	lbu	a5,-81(s0)
 178:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 17c:	01578763          	beq	a5,s5,18a <gets+0x54>
 180:	0905                	addi	s2,s2,1
 182:	fd679be3          	bne	a5,s6,158 <gets+0x22>
  for(i=0; i+1 < max; ){
 186:	89a6                	mv	s3,s1
 188:	a011                	j	18c <gets+0x56>
 18a:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 18c:	99de                	add	s3,s3,s7
 18e:	00098023          	sb	zero,0(s3)
  return buf;
}
 192:	855e                	mv	a0,s7
 194:	60e6                	ld	ra,88(sp)
 196:	6446                	ld	s0,80(sp)
 198:	64a6                	ld	s1,72(sp)
 19a:	6906                	ld	s2,64(sp)
 19c:	79e2                	ld	s3,56(sp)
 19e:	7a42                	ld	s4,48(sp)
 1a0:	7aa2                	ld	s5,40(sp)
 1a2:	7b02                	ld	s6,32(sp)
 1a4:	6be2                	ld	s7,24(sp)
 1a6:	6125                	addi	sp,sp,96
 1a8:	8082                	ret

00000000000001aa <stat>:

int
stat(const char *n, struct stat *st)
{
 1aa:	1101                	addi	sp,sp,-32
 1ac:	ec06                	sd	ra,24(sp)
 1ae:	e822                	sd	s0,16(sp)
 1b0:	e426                	sd	s1,8(sp)
 1b2:	e04a                	sd	s2,0(sp)
 1b4:	1000                	addi	s0,sp,32
 1b6:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 1b8:	4581                	li	a1,0
 1ba:	00000097          	auipc	ra,0x0
 1be:	170080e7          	jalr	368(ra) # 32a <open>
  if(fd < 0)
 1c2:	02054563          	bltz	a0,1ec <stat+0x42>
 1c6:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 1c8:	85ca                	mv	a1,s2
 1ca:	00000097          	auipc	ra,0x0
 1ce:	178080e7          	jalr	376(ra) # 342 <fstat>
 1d2:	892a                	mv	s2,a0
  close(fd);
 1d4:	8526                	mv	a0,s1
 1d6:	00000097          	auipc	ra,0x0
 1da:	13c080e7          	jalr	316(ra) # 312 <close>
  return r;
}
 1de:	854a                	mv	a0,s2
 1e0:	60e2                	ld	ra,24(sp)
 1e2:	6442                	ld	s0,16(sp)
 1e4:	64a2                	ld	s1,8(sp)
 1e6:	6902                	ld	s2,0(sp)
 1e8:	6105                	addi	sp,sp,32
 1ea:	8082                	ret
    return -1;
 1ec:	597d                	li	s2,-1
 1ee:	bfc5                	j	1de <stat+0x34>

00000000000001f0 <atoi>:

int
atoi(const char *s)
{
 1f0:	1141                	addi	sp,sp,-16
 1f2:	e422                	sd	s0,8(sp)
 1f4:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 1f6:	00054683          	lbu	a3,0(a0)
 1fa:	fd06879b          	addiw	a5,a3,-48
 1fe:	0ff7f793          	zext.b	a5,a5
 202:	4625                	li	a2,9
 204:	02f66863          	bltu	a2,a5,234 <atoi+0x44>
 208:	872a                	mv	a4,a0
  n = 0;
 20a:	4501                	li	a0,0
    n = n*10 + *s++ - '0';
 20c:	0705                	addi	a4,a4,1
 20e:	0025179b          	slliw	a5,a0,0x2
 212:	9fa9                	addw	a5,a5,a0
 214:	0017979b          	slliw	a5,a5,0x1
 218:	9fb5                	addw	a5,a5,a3
 21a:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 21e:	00074683          	lbu	a3,0(a4)
 222:	fd06879b          	addiw	a5,a3,-48
 226:	0ff7f793          	zext.b	a5,a5
 22a:	fef671e3          	bgeu	a2,a5,20c <atoi+0x1c>
  return n;
}
 22e:	6422                	ld	s0,8(sp)
 230:	0141                	addi	sp,sp,16
 232:	8082                	ret
  n = 0;
 234:	4501                	li	a0,0
 236:	bfe5                	j	22e <atoi+0x3e>

0000000000000238 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 238:	1141                	addi	sp,sp,-16
 23a:	e422                	sd	s0,8(sp)
 23c:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 23e:	02b57463          	bgeu	a0,a1,266 <memmove+0x2e>
    while(n-- > 0)
 242:	00c05f63          	blez	a2,260 <memmove+0x28>
 246:	1602                	slli	a2,a2,0x20
 248:	9201                	srli	a2,a2,0x20
 24a:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 24e:	872a                	mv	a4,a0
      *dst++ = *src++;
 250:	0585                	addi	a1,a1,1
 252:	0705                	addi	a4,a4,1
 254:	fff5c683          	lbu	a3,-1(a1)
 258:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 25c:	fee79ae3          	bne	a5,a4,250 <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 260:	6422                	ld	s0,8(sp)
 262:	0141                	addi	sp,sp,16
 264:	8082                	ret
    dst += n;
 266:	00c50733          	add	a4,a0,a2
    src += n;
 26a:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 26c:	fec05ae3          	blez	a2,260 <memmove+0x28>
 270:	fff6079b          	addiw	a5,a2,-1
 274:	1782                	slli	a5,a5,0x20
 276:	9381                	srli	a5,a5,0x20
 278:	fff7c793          	not	a5,a5
 27c:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 27e:	15fd                	addi	a1,a1,-1
 280:	177d                	addi	a4,a4,-1
 282:	0005c683          	lbu	a3,0(a1)
 286:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 28a:	fee79ae3          	bne	a5,a4,27e <memmove+0x46>
 28e:	bfc9                	j	260 <memmove+0x28>

0000000000000290 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 290:	1141                	addi	sp,sp,-16
 292:	e422                	sd	s0,8(sp)
 294:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 296:	ca05                	beqz	a2,2c6 <memcmp+0x36>
 298:	fff6069b          	addiw	a3,a2,-1
 29c:	1682                	slli	a3,a3,0x20
 29e:	9281                	srli	a3,a3,0x20
 2a0:	0685                	addi	a3,a3,1
 2a2:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 2a4:	00054783          	lbu	a5,0(a0)
 2a8:	0005c703          	lbu	a4,0(a1)
 2ac:	00e79863          	bne	a5,a4,2bc <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 2b0:	0505                	addi	a0,a0,1
    p2++;
 2b2:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 2b4:	fed518e3          	bne	a0,a3,2a4 <memcmp+0x14>
  }
  return 0;
 2b8:	4501                	li	a0,0
 2ba:	a019                	j	2c0 <memcmp+0x30>
      return *p1 - *p2;
 2bc:	40e7853b          	subw	a0,a5,a4
}
 2c0:	6422                	ld	s0,8(sp)
 2c2:	0141                	addi	sp,sp,16
 2c4:	8082                	ret
  return 0;
 2c6:	4501                	li	a0,0
 2c8:	bfe5                	j	2c0 <memcmp+0x30>

00000000000002ca <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 2ca:	1141                	addi	sp,sp,-16
 2cc:	e406                	sd	ra,8(sp)
 2ce:	e022                	sd	s0,0(sp)
 2d0:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 2d2:	00000097          	auipc	ra,0x0
 2d6:	f66080e7          	jalr	-154(ra) # 238 <memmove>
}
 2da:	60a2                	ld	ra,8(sp)
 2dc:	6402                	ld	s0,0(sp)
 2de:	0141                	addi	sp,sp,16
 2e0:	8082                	ret

00000000000002e2 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 2e2:	4885                	li	a7,1
 ecall
 2e4:	00000073          	ecall
 ret
 2e8:	8082                	ret

00000000000002ea <exit>:
.global exit
exit:
 li a7, SYS_exit
 2ea:	4889                	li	a7,2
 ecall
 2ec:	00000073          	ecall
 ret
 2f0:	8082                	ret

00000000000002f2 <wait>:
.global wait
wait:
 li a7, SYS_wait
 2f2:	488d                	li	a7,3
 ecall
 2f4:	00000073          	ecall
 ret
 2f8:	8082                	ret

00000000000002fa <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 2fa:	4891                	li	a7,4
 ecall
 2fc:	00000073          	ecall
 ret
 300:	8082                	ret

0000000000000302 <read>:
.global read
read:
 li a7, SYS_read
 302:	4895                	li	a7,5
 ecall
 304:	00000073          	ecall
 ret
 308:	8082                	ret

000000000000030a <write>:
.global write
write:
 li a7, SYS_write
 30a:	48c1                	li	a7,16
 ecall
 30c:	00000073          	ecall
 ret
 310:	8082                	ret

0000000000000312 <close>:
.global close
close:
 li a7, SYS_close
 312:	48d5                	li	a7,21
 ecall
 314:	00000073          	ecall
 ret
 318:	8082                	ret

000000000000031a <kill>:
.global kill
kill:
 li a7, SYS_kill
 31a:	4899                	li	a7,6
 ecall
 31c:	00000073          	ecall
 ret
 320:	8082                	ret

0000000000000322 <exec>:
.global exec
exec:
 li a7, SYS_exec
 322:	489d                	li	a7,7
 ecall
 324:	00000073          	ecall
 ret
 328:	8082                	ret

000000000000032a <open>:
.global open
open:
 li a7, SYS_open
 32a:	48bd                	li	a7,15
 ecall
 32c:	00000073          	ecall
 ret
 330:	8082                	ret

0000000000000332 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 332:	48c5                	li	a7,17
 ecall
 334:	00000073          	ecall
 ret
 338:	8082                	ret

000000000000033a <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 33a:	48c9                	li	a7,18
 ecall
 33c:	00000073          	ecall
 ret
 340:	8082                	ret

0000000000000342 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 342:	48a1                	li	a7,8
 ecall
 344:	00000073          	ecall
 ret
 348:	8082                	ret

000000000000034a <link>:
.global link
link:
 li a7, SYS_link
 34a:	48cd                	li	a7,19
 ecall
 34c:	00000073          	ecall
 ret
 350:	8082                	ret

0000000000000352 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 352:	48d1                	li	a7,20
 ecall
 354:	00000073          	ecall
 ret
 358:	8082                	ret

000000000000035a <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 35a:	48a5                	li	a7,9
 ecall
 35c:	00000073          	ecall
 ret
 360:	8082                	ret

0000000000000362 <dup>:
.global dup
dup:
 li a7, SYS_dup
 362:	48a9                	li	a7,10
 ecall
 364:	00000073          	ecall
 ret
 368:	8082                	ret

000000000000036a <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 36a:	48ad                	li	a7,11
 ecall
 36c:	00000073          	ecall
 ret
 370:	8082                	ret

0000000000000372 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 372:	48b1                	li	a7,12
 ecall
 374:	00000073          	ecall
 ret
 378:	8082                	ret

000000000000037a <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 37a:	48b5                	li	a7,13
 ecall
 37c:	00000073          	ecall
 ret
 380:	8082                	ret

0000000000000382 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 382:	48b9                	li	a7,14
 ecall
 384:	00000073          	ecall
 ret
 388:	8082                	ret

000000000000038a <strace>:
.global strace
strace:
 li a7, SYS_strace
 38a:	48d9                	li	a7,22
 ecall
 38c:	00000073          	ecall
 ret
 390:	8082                	ret

0000000000000392 <waitx>:
.global waitx
waitx:
 li a7, SYS_waitx
 392:	48dd                	li	a7,23
 ecall
 394:	00000073          	ecall
 ret
 398:	8082                	ret

000000000000039a <set_priority>:
.global set_priority
set_priority:
 li a7, SYS_set_priority
 39a:	48e1                	li	a7,24
 ecall
 39c:	00000073          	ecall
 ret
 3a0:	8082                	ret

00000000000003a2 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 3a2:	1101                	addi	sp,sp,-32
 3a4:	ec06                	sd	ra,24(sp)
 3a6:	e822                	sd	s0,16(sp)
 3a8:	1000                	addi	s0,sp,32
 3aa:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 3ae:	4605                	li	a2,1
 3b0:	fef40593          	addi	a1,s0,-17
 3b4:	00000097          	auipc	ra,0x0
 3b8:	f56080e7          	jalr	-170(ra) # 30a <write>
}
 3bc:	60e2                	ld	ra,24(sp)
 3be:	6442                	ld	s0,16(sp)
 3c0:	6105                	addi	sp,sp,32
 3c2:	8082                	ret

00000000000003c4 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 3c4:	7139                	addi	sp,sp,-64
 3c6:	fc06                	sd	ra,56(sp)
 3c8:	f822                	sd	s0,48(sp)
 3ca:	f426                	sd	s1,40(sp)
 3cc:	f04a                	sd	s2,32(sp)
 3ce:	ec4e                	sd	s3,24(sp)
 3d0:	0080                	addi	s0,sp,64
 3d2:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 3d4:	c299                	beqz	a3,3da <printint+0x16>
 3d6:	0805c963          	bltz	a1,468 <printint+0xa4>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 3da:	2581                	sext.w	a1,a1
  neg = 0;
 3dc:	4881                	li	a7,0
 3de:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 3e2:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 3e4:	2601                	sext.w	a2,a2
 3e6:	00000517          	auipc	a0,0x0
 3ea:	4b250513          	addi	a0,a0,1202 # 898 <digits>
 3ee:	883a                	mv	a6,a4
 3f0:	2705                	addiw	a4,a4,1
 3f2:	02c5f7bb          	remuw	a5,a1,a2
 3f6:	1782                	slli	a5,a5,0x20
 3f8:	9381                	srli	a5,a5,0x20
 3fa:	97aa                	add	a5,a5,a0
 3fc:	0007c783          	lbu	a5,0(a5)
 400:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 404:	0005879b          	sext.w	a5,a1
 408:	02c5d5bb          	divuw	a1,a1,a2
 40c:	0685                	addi	a3,a3,1
 40e:	fec7f0e3          	bgeu	a5,a2,3ee <printint+0x2a>
  if(neg)
 412:	00088c63          	beqz	a7,42a <printint+0x66>
    buf[i++] = '-';
 416:	fd070793          	addi	a5,a4,-48
 41a:	00878733          	add	a4,a5,s0
 41e:	02d00793          	li	a5,45
 422:	fef70823          	sb	a5,-16(a4)
 426:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 42a:	02e05863          	blez	a4,45a <printint+0x96>
 42e:	fc040793          	addi	a5,s0,-64
 432:	00e78933          	add	s2,a5,a4
 436:	fff78993          	addi	s3,a5,-1
 43a:	99ba                	add	s3,s3,a4
 43c:	377d                	addiw	a4,a4,-1
 43e:	1702                	slli	a4,a4,0x20
 440:	9301                	srli	a4,a4,0x20
 442:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 446:	fff94583          	lbu	a1,-1(s2)
 44a:	8526                	mv	a0,s1
 44c:	00000097          	auipc	ra,0x0
 450:	f56080e7          	jalr	-170(ra) # 3a2 <putc>
  while(--i >= 0)
 454:	197d                	addi	s2,s2,-1
 456:	ff3918e3          	bne	s2,s3,446 <printint+0x82>
}
 45a:	70e2                	ld	ra,56(sp)
 45c:	7442                	ld	s0,48(sp)
 45e:	74a2                	ld	s1,40(sp)
 460:	7902                	ld	s2,32(sp)
 462:	69e2                	ld	s3,24(sp)
 464:	6121                	addi	sp,sp,64
 466:	8082                	ret
    x = -xx;
 468:	40b005bb          	negw	a1,a1
    neg = 1;
 46c:	4885                	li	a7,1
    x = -xx;
 46e:	bf85                	j	3de <printint+0x1a>

0000000000000470 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 470:	7119                	addi	sp,sp,-128
 472:	fc86                	sd	ra,120(sp)
 474:	f8a2                	sd	s0,112(sp)
 476:	f4a6                	sd	s1,104(sp)
 478:	f0ca                	sd	s2,96(sp)
 47a:	ecce                	sd	s3,88(sp)
 47c:	e8d2                	sd	s4,80(sp)
 47e:	e4d6                	sd	s5,72(sp)
 480:	e0da                	sd	s6,64(sp)
 482:	fc5e                	sd	s7,56(sp)
 484:	f862                	sd	s8,48(sp)
 486:	f466                	sd	s9,40(sp)
 488:	f06a                	sd	s10,32(sp)
 48a:	ec6e                	sd	s11,24(sp)
 48c:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 48e:	0005c903          	lbu	s2,0(a1)
 492:	18090f63          	beqz	s2,630 <vprintf+0x1c0>
 496:	8aaa                	mv	s5,a0
 498:	8b32                	mv	s6,a2
 49a:	00158493          	addi	s1,a1,1
  state = 0;
 49e:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 4a0:	02500a13          	li	s4,37
 4a4:	4c55                	li	s8,21
 4a6:	00000c97          	auipc	s9,0x0
 4aa:	39ac8c93          	addi	s9,s9,922 # 840 <malloc+0x10c>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
        s = va_arg(ap, char*);
        if(s == 0)
          s = "(null)";
        while(*s != 0){
 4ae:	02800d93          	li	s11,40
  putc(fd, 'x');
 4b2:	4d41                	li	s10,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 4b4:	00000b97          	auipc	s7,0x0
 4b8:	3e4b8b93          	addi	s7,s7,996 # 898 <digits>
 4bc:	a839                	j	4da <vprintf+0x6a>
        putc(fd, c);
 4be:	85ca                	mv	a1,s2
 4c0:	8556                	mv	a0,s5
 4c2:	00000097          	auipc	ra,0x0
 4c6:	ee0080e7          	jalr	-288(ra) # 3a2 <putc>
 4ca:	a019                	j	4d0 <vprintf+0x60>
    } else if(state == '%'){
 4cc:	01498d63          	beq	s3,s4,4e6 <vprintf+0x76>
  for(i = 0; fmt[i]; i++){
 4d0:	0485                	addi	s1,s1,1
 4d2:	fff4c903          	lbu	s2,-1(s1)
 4d6:	14090d63          	beqz	s2,630 <vprintf+0x1c0>
    if(state == 0){
 4da:	fe0999e3          	bnez	s3,4cc <vprintf+0x5c>
      if(c == '%'){
 4de:	ff4910e3          	bne	s2,s4,4be <vprintf+0x4e>
        state = '%';
 4e2:	89d2                	mv	s3,s4
 4e4:	b7f5                	j	4d0 <vprintf+0x60>
      if(c == 'd'){
 4e6:	11490c63          	beq	s2,s4,5fe <vprintf+0x18e>
 4ea:	f9d9079b          	addiw	a5,s2,-99
 4ee:	0ff7f793          	zext.b	a5,a5
 4f2:	10fc6e63          	bltu	s8,a5,60e <vprintf+0x19e>
 4f6:	f9d9079b          	addiw	a5,s2,-99
 4fa:	0ff7f713          	zext.b	a4,a5
 4fe:	10ec6863          	bltu	s8,a4,60e <vprintf+0x19e>
 502:	00271793          	slli	a5,a4,0x2
 506:	97e6                	add	a5,a5,s9
 508:	439c                	lw	a5,0(a5)
 50a:	97e6                	add	a5,a5,s9
 50c:	8782                	jr	a5
        printint(fd, va_arg(ap, int), 10, 1);
 50e:	008b0913          	addi	s2,s6,8
 512:	4685                	li	a3,1
 514:	4629                	li	a2,10
 516:	000b2583          	lw	a1,0(s6)
 51a:	8556                	mv	a0,s5
 51c:	00000097          	auipc	ra,0x0
 520:	ea8080e7          	jalr	-344(ra) # 3c4 <printint>
 524:	8b4a                	mv	s6,s2
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
        putc(fd, c);
      }
      state = 0;
 526:	4981                	li	s3,0
 528:	b765                	j	4d0 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 52a:	008b0913          	addi	s2,s6,8
 52e:	4681                	li	a3,0
 530:	4629                	li	a2,10
 532:	000b2583          	lw	a1,0(s6)
 536:	8556                	mv	a0,s5
 538:	00000097          	auipc	ra,0x0
 53c:	e8c080e7          	jalr	-372(ra) # 3c4 <printint>
 540:	8b4a                	mv	s6,s2
      state = 0;
 542:	4981                	li	s3,0
 544:	b771                	j	4d0 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 546:	008b0913          	addi	s2,s6,8
 54a:	4681                	li	a3,0
 54c:	866a                	mv	a2,s10
 54e:	000b2583          	lw	a1,0(s6)
 552:	8556                	mv	a0,s5
 554:	00000097          	auipc	ra,0x0
 558:	e70080e7          	jalr	-400(ra) # 3c4 <printint>
 55c:	8b4a                	mv	s6,s2
      state = 0;
 55e:	4981                	li	s3,0
 560:	bf85                	j	4d0 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 562:	008b0793          	addi	a5,s6,8
 566:	f8f43423          	sd	a5,-120(s0)
 56a:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 56e:	03000593          	li	a1,48
 572:	8556                	mv	a0,s5
 574:	00000097          	auipc	ra,0x0
 578:	e2e080e7          	jalr	-466(ra) # 3a2 <putc>
  putc(fd, 'x');
 57c:	07800593          	li	a1,120
 580:	8556                	mv	a0,s5
 582:	00000097          	auipc	ra,0x0
 586:	e20080e7          	jalr	-480(ra) # 3a2 <putc>
 58a:	896a                	mv	s2,s10
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 58c:	03c9d793          	srli	a5,s3,0x3c
 590:	97de                	add	a5,a5,s7
 592:	0007c583          	lbu	a1,0(a5)
 596:	8556                	mv	a0,s5
 598:	00000097          	auipc	ra,0x0
 59c:	e0a080e7          	jalr	-502(ra) # 3a2 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 5a0:	0992                	slli	s3,s3,0x4
 5a2:	397d                	addiw	s2,s2,-1
 5a4:	fe0914e3          	bnez	s2,58c <vprintf+0x11c>
        printptr(fd, va_arg(ap, uint64));
 5a8:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 5ac:	4981                	li	s3,0
 5ae:	b70d                	j	4d0 <vprintf+0x60>
        s = va_arg(ap, char*);
 5b0:	008b0913          	addi	s2,s6,8
 5b4:	000b3983          	ld	s3,0(s6)
        if(s == 0)
 5b8:	02098163          	beqz	s3,5da <vprintf+0x16a>
        while(*s != 0){
 5bc:	0009c583          	lbu	a1,0(s3)
 5c0:	c5ad                	beqz	a1,62a <vprintf+0x1ba>
          putc(fd, *s);
 5c2:	8556                	mv	a0,s5
 5c4:	00000097          	auipc	ra,0x0
 5c8:	dde080e7          	jalr	-546(ra) # 3a2 <putc>
          s++;
 5cc:	0985                	addi	s3,s3,1
        while(*s != 0){
 5ce:	0009c583          	lbu	a1,0(s3)
 5d2:	f9e5                	bnez	a1,5c2 <vprintf+0x152>
        s = va_arg(ap, char*);
 5d4:	8b4a                	mv	s6,s2
      state = 0;
 5d6:	4981                	li	s3,0
 5d8:	bde5                	j	4d0 <vprintf+0x60>
          s = "(null)";
 5da:	00000997          	auipc	s3,0x0
 5de:	25e98993          	addi	s3,s3,606 # 838 <malloc+0x104>
        while(*s != 0){
 5e2:	85ee                	mv	a1,s11
 5e4:	bff9                	j	5c2 <vprintf+0x152>
        putc(fd, va_arg(ap, uint));
 5e6:	008b0913          	addi	s2,s6,8
 5ea:	000b4583          	lbu	a1,0(s6)
 5ee:	8556                	mv	a0,s5
 5f0:	00000097          	auipc	ra,0x0
 5f4:	db2080e7          	jalr	-590(ra) # 3a2 <putc>
 5f8:	8b4a                	mv	s6,s2
      state = 0;
 5fa:	4981                	li	s3,0
 5fc:	bdd1                	j	4d0 <vprintf+0x60>
        putc(fd, c);
 5fe:	85d2                	mv	a1,s4
 600:	8556                	mv	a0,s5
 602:	00000097          	auipc	ra,0x0
 606:	da0080e7          	jalr	-608(ra) # 3a2 <putc>
      state = 0;
 60a:	4981                	li	s3,0
 60c:	b5d1                	j	4d0 <vprintf+0x60>
        putc(fd, '%');
 60e:	85d2                	mv	a1,s4
 610:	8556                	mv	a0,s5
 612:	00000097          	auipc	ra,0x0
 616:	d90080e7          	jalr	-624(ra) # 3a2 <putc>
        putc(fd, c);
 61a:	85ca                	mv	a1,s2
 61c:	8556                	mv	a0,s5
 61e:	00000097          	auipc	ra,0x0
 622:	d84080e7          	jalr	-636(ra) # 3a2 <putc>
      state = 0;
 626:	4981                	li	s3,0
 628:	b565                	j	4d0 <vprintf+0x60>
        s = va_arg(ap, char*);
 62a:	8b4a                	mv	s6,s2
      state = 0;
 62c:	4981                	li	s3,0
 62e:	b54d                	j	4d0 <vprintf+0x60>
    }
  }
}
 630:	70e6                	ld	ra,120(sp)
 632:	7446                	ld	s0,112(sp)
 634:	74a6                	ld	s1,104(sp)
 636:	7906                	ld	s2,96(sp)
 638:	69e6                	ld	s3,88(sp)
 63a:	6a46                	ld	s4,80(sp)
 63c:	6aa6                	ld	s5,72(sp)
 63e:	6b06                	ld	s6,64(sp)
 640:	7be2                	ld	s7,56(sp)
 642:	7c42                	ld	s8,48(sp)
 644:	7ca2                	ld	s9,40(sp)
 646:	7d02                	ld	s10,32(sp)
 648:	6de2                	ld	s11,24(sp)
 64a:	6109                	addi	sp,sp,128
 64c:	8082                	ret

000000000000064e <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 64e:	715d                	addi	sp,sp,-80
 650:	ec06                	sd	ra,24(sp)
 652:	e822                	sd	s0,16(sp)
 654:	1000                	addi	s0,sp,32
 656:	e010                	sd	a2,0(s0)
 658:	e414                	sd	a3,8(s0)
 65a:	e818                	sd	a4,16(s0)
 65c:	ec1c                	sd	a5,24(s0)
 65e:	03043023          	sd	a6,32(s0)
 662:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 666:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 66a:	8622                	mv	a2,s0
 66c:	00000097          	auipc	ra,0x0
 670:	e04080e7          	jalr	-508(ra) # 470 <vprintf>
}
 674:	60e2                	ld	ra,24(sp)
 676:	6442                	ld	s0,16(sp)
 678:	6161                	addi	sp,sp,80
 67a:	8082                	ret

000000000000067c <printf>:

void
printf(const char *fmt, ...)
{
 67c:	711d                	addi	sp,sp,-96
 67e:	ec06                	sd	ra,24(sp)
 680:	e822                	sd	s0,16(sp)
 682:	1000                	addi	s0,sp,32
 684:	e40c                	sd	a1,8(s0)
 686:	e810                	sd	a2,16(s0)
 688:	ec14                	sd	a3,24(s0)
 68a:	f018                	sd	a4,32(s0)
 68c:	f41c                	sd	a5,40(s0)
 68e:	03043823          	sd	a6,48(s0)
 692:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 696:	00840613          	addi	a2,s0,8
 69a:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 69e:	85aa                	mv	a1,a0
 6a0:	4505                	li	a0,1
 6a2:	00000097          	auipc	ra,0x0
 6a6:	dce080e7          	jalr	-562(ra) # 470 <vprintf>
}
 6aa:	60e2                	ld	ra,24(sp)
 6ac:	6442                	ld	s0,16(sp)
 6ae:	6125                	addi	sp,sp,96
 6b0:	8082                	ret

00000000000006b2 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 6b2:	1141                	addi	sp,sp,-16
 6b4:	e422                	sd	s0,8(sp)
 6b6:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 6b8:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 6bc:	00001797          	auipc	a5,0x1
 6c0:	9447b783          	ld	a5,-1724(a5) # 1000 <freep>
 6c4:	a02d                	j	6ee <free+0x3c>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 6c6:	4618                	lw	a4,8(a2)
 6c8:	9f2d                	addw	a4,a4,a1
 6ca:	fee52c23          	sw	a4,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 6ce:	6398                	ld	a4,0(a5)
 6d0:	6310                	ld	a2,0(a4)
 6d2:	a83d                	j	710 <free+0x5e>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 6d4:	ff852703          	lw	a4,-8(a0)
 6d8:	9f31                	addw	a4,a4,a2
 6da:	c798                	sw	a4,8(a5)
    p->s.ptr = bp->s.ptr;
 6dc:	ff053683          	ld	a3,-16(a0)
 6e0:	a091                	j	724 <free+0x72>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 6e2:	6398                	ld	a4,0(a5)
 6e4:	00e7e463          	bltu	a5,a4,6ec <free+0x3a>
 6e8:	00e6ea63          	bltu	a3,a4,6fc <free+0x4a>
{
 6ec:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 6ee:	fed7fae3          	bgeu	a5,a3,6e2 <free+0x30>
 6f2:	6398                	ld	a4,0(a5)
 6f4:	00e6e463          	bltu	a3,a4,6fc <free+0x4a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 6f8:	fee7eae3          	bltu	a5,a4,6ec <free+0x3a>
  if(bp + bp->s.size == p->s.ptr){
 6fc:	ff852583          	lw	a1,-8(a0)
 700:	6390                	ld	a2,0(a5)
 702:	02059813          	slli	a6,a1,0x20
 706:	01c85713          	srli	a4,a6,0x1c
 70a:	9736                	add	a4,a4,a3
 70c:	fae60de3          	beq	a2,a4,6c6 <free+0x14>
    bp->s.ptr = p->s.ptr->s.ptr;
 710:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 714:	4790                	lw	a2,8(a5)
 716:	02061593          	slli	a1,a2,0x20
 71a:	01c5d713          	srli	a4,a1,0x1c
 71e:	973e                	add	a4,a4,a5
 720:	fae68ae3          	beq	a3,a4,6d4 <free+0x22>
    p->s.ptr = bp->s.ptr;
 724:	e394                	sd	a3,0(a5)
  } else
    p->s.ptr = bp;
  freep = p;
 726:	00001717          	auipc	a4,0x1
 72a:	8cf73d23          	sd	a5,-1830(a4) # 1000 <freep>
}
 72e:	6422                	ld	s0,8(sp)
 730:	0141                	addi	sp,sp,16
 732:	8082                	ret

0000000000000734 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 734:	7139                	addi	sp,sp,-64
 736:	fc06                	sd	ra,56(sp)
 738:	f822                	sd	s0,48(sp)
 73a:	f426                	sd	s1,40(sp)
 73c:	f04a                	sd	s2,32(sp)
 73e:	ec4e                	sd	s3,24(sp)
 740:	e852                	sd	s4,16(sp)
 742:	e456                	sd	s5,8(sp)
 744:	e05a                	sd	s6,0(sp)
 746:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 748:	02051493          	slli	s1,a0,0x20
 74c:	9081                	srli	s1,s1,0x20
 74e:	04bd                	addi	s1,s1,15
 750:	8091                	srli	s1,s1,0x4
 752:	0014899b          	addiw	s3,s1,1
 756:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 758:	00001517          	auipc	a0,0x1
 75c:	8a853503          	ld	a0,-1880(a0) # 1000 <freep>
 760:	c515                	beqz	a0,78c <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 762:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 764:	4798                	lw	a4,8(a5)
 766:	02977f63          	bgeu	a4,s1,7a4 <malloc+0x70>
 76a:	8a4e                	mv	s4,s3
 76c:	0009871b          	sext.w	a4,s3
 770:	6685                	lui	a3,0x1
 772:	00d77363          	bgeu	a4,a3,778 <malloc+0x44>
 776:	6a05                	lui	s4,0x1
 778:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 77c:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 780:	00001917          	auipc	s2,0x1
 784:	88090913          	addi	s2,s2,-1920 # 1000 <freep>
  if(p == (char*)-1)
 788:	5afd                	li	s5,-1
 78a:	a895                	j	7fe <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 78c:	00001797          	auipc	a5,0x1
 790:	88478793          	addi	a5,a5,-1916 # 1010 <base>
 794:	00001717          	auipc	a4,0x1
 798:	86f73623          	sd	a5,-1940(a4) # 1000 <freep>
 79c:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 79e:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 7a2:	b7e1                	j	76a <malloc+0x36>
      if(p->s.size == nunits)
 7a4:	02e48c63          	beq	s1,a4,7dc <malloc+0xa8>
        p->s.size -= nunits;
 7a8:	4137073b          	subw	a4,a4,s3
 7ac:	c798                	sw	a4,8(a5)
        p += p->s.size;
 7ae:	02071693          	slli	a3,a4,0x20
 7b2:	01c6d713          	srli	a4,a3,0x1c
 7b6:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 7b8:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 7bc:	00001717          	auipc	a4,0x1
 7c0:	84a73223          	sd	a0,-1980(a4) # 1000 <freep>
      return (void*)(p + 1);
 7c4:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 7c8:	70e2                	ld	ra,56(sp)
 7ca:	7442                	ld	s0,48(sp)
 7cc:	74a2                	ld	s1,40(sp)
 7ce:	7902                	ld	s2,32(sp)
 7d0:	69e2                	ld	s3,24(sp)
 7d2:	6a42                	ld	s4,16(sp)
 7d4:	6aa2                	ld	s5,8(sp)
 7d6:	6b02                	ld	s6,0(sp)
 7d8:	6121                	addi	sp,sp,64
 7da:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 7dc:	6398                	ld	a4,0(a5)
 7de:	e118                	sd	a4,0(a0)
 7e0:	bff1                	j	7bc <malloc+0x88>
  hp->s.size = nu;
 7e2:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 7e6:	0541                	addi	a0,a0,16
 7e8:	00000097          	auipc	ra,0x0
 7ec:	eca080e7          	jalr	-310(ra) # 6b2 <free>
  return freep;
 7f0:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 7f4:	d971                	beqz	a0,7c8 <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 7f6:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 7f8:	4798                	lw	a4,8(a5)
 7fa:	fa9775e3          	bgeu	a4,s1,7a4 <malloc+0x70>
    if(p == freep)
 7fe:	00093703          	ld	a4,0(s2)
 802:	853e                	mv	a0,a5
 804:	fef719e3          	bne	a4,a5,7f6 <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 808:	8552                	mv	a0,s4
 80a:	00000097          	auipc	ra,0x0
 80e:	b68080e7          	jalr	-1176(ra) # 372 <sbrk>
  if(p == (char*)-1)
 812:	fd5518e3          	bne	a0,s5,7e2 <malloc+0xae>
        return 0;
 816:	4501                	li	a0,0
 818:	bf45                	j	7c8 <malloc+0x94>
