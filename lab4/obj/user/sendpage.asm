
obj/user/sendpage:     file format elf32-i386


Disassembly of section .text:

00800020 <_start>:
// starts us running when we are initially loaded into a new environment.
.text
.globl _start
_start:
	// See if we were started with arguments on the stack
	cmpl $USTACKTOP, %esp
  800020:	81 fc 00 e0 bf ee    	cmp    $0xeebfe000,%esp
	jne args_exist
  800026:	75 04                	jne    80002c <args_exist>

	// If not, push dummy argc/argv arguments.
	// This happens when we are loaded by the kernel,
	// because the kernel does not know about passing arguments.
	pushl $0
  800028:	6a 00                	push   $0x0
	pushl $0
  80002a:	6a 00                	push   $0x0

0080002c <args_exist>:

args_exist:
	call libmain
  80002c:	e8 82 01 00 00       	call   8001b3 <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <umain>:
#define TEMP_ADDR	((char*)0xa00000)
#define TEMP_ADDR_CHILD	((char*)0xb00000)

void
umain(int argc, char **argv)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
  800036:	83 ec 18             	sub    $0x18,%esp
	envid_t who;

	if ((who = fork()) == 0) {
  800039:	e8 32 0f 00 00       	call   800f70 <fork>
  80003e:	89 45 f4             	mov    %eax,-0xc(%ebp)
  800041:	85 c0                	test   %eax,%eax
  800043:	0f 85 ac 00 00 00    	jne    8000f5 <umain+0xc2>
		// Child
		cprintf("child\n");
  800049:	83 ec 0c             	sub    $0xc,%esp
  80004c:	68 20 16 80 00       	push   $0x801620
  800051:	e8 48 02 00 00       	call   80029e <cprintf>
		ipc_recv(&who, (void*)TEMP_ADDR_CHILD, 0);
  800056:	83 c4 0c             	add    $0xc,%esp
  800059:	6a 00                	push   $0x0
  80005b:	68 00 00 b0 00       	push   $0xb00000
  800060:	8d 45 f4             	lea    -0xc(%ebp),%eax
  800063:	50                   	push   %eax
  800064:	e8 cb 10 00 00       	call   801134 <ipc_recv>
		cprintf("%x got message: %s\n", who, TEMP_ADDR_CHILD);
  800069:	83 c4 0c             	add    $0xc,%esp
  80006c:	68 00 00 b0 00       	push   $0xb00000
  800071:	ff 75 f4             	pushl  -0xc(%ebp)
  800074:	68 27 16 80 00       	push   $0x801627
  800079:	e8 20 02 00 00       	call   80029e <cprintf>
		if (strncmp(TEMP_ADDR_CHILD, str1, strlen(str1)) == 0)
  80007e:	83 c4 04             	add    $0x4,%esp
  800081:	ff 35 04 20 80 00    	pushl  0x802004
  800087:	e8 dd 07 00 00       	call   800869 <strlen>
  80008c:	83 c4 0c             	add    $0xc,%esp
  80008f:	50                   	push   %eax
  800090:	ff 35 04 20 80 00    	pushl  0x802004
  800096:	68 00 00 b0 00       	push   $0xb00000
  80009b:	e8 d2 08 00 00       	call   800972 <strncmp>
  8000a0:	83 c4 10             	add    $0x10,%esp
  8000a3:	85 c0                	test   %eax,%eax
  8000a5:	75 10                	jne    8000b7 <umain+0x84>
			cprintf("child received correct message\n");
  8000a7:	83 ec 0c             	sub    $0xc,%esp
  8000aa:	68 44 16 80 00       	push   $0x801644
  8000af:	e8 ea 01 00 00       	call   80029e <cprintf>
  8000b4:	83 c4 10             	add    $0x10,%esp

		memcpy(TEMP_ADDR_CHILD, str2, strlen(str2) + 1);
  8000b7:	83 ec 0c             	sub    $0xc,%esp
  8000ba:	ff 35 00 20 80 00    	pushl  0x802000
  8000c0:	e8 a4 07 00 00       	call   800869 <strlen>
  8000c5:	83 c4 0c             	add    $0xc,%esp
  8000c8:	83 c0 01             	add    $0x1,%eax
  8000cb:	50                   	push   %eax
  8000cc:	ff 35 00 20 80 00    	pushl  0x802000
  8000d2:	68 00 00 b0 00       	push   $0xb00000
  8000d7:	e8 c0 09 00 00       	call   800a9c <memcpy>
		ipc_send(who, 0, TEMP_ADDR_CHILD, PTE_P | PTE_W | PTE_U);
  8000dc:	6a 07                	push   $0x7
  8000de:	68 00 00 b0 00       	push   $0xb00000
  8000e3:	6a 00                	push   $0x0
  8000e5:	ff 75 f4             	pushl  -0xc(%ebp)
  8000e8:	e8 da 10 00 00       	call   8011c7 <ipc_send>
		return;
  8000ed:	83 c4 20             	add    $0x20,%esp
  8000f0:	e9 bc 00 00 00       	jmp    8001b1 <umain+0x17e>
	}

	// Parent

	sys_page_alloc(thisenv->env_id, TEMP_ADDR, PTE_P | PTE_W | PTE_U);
  8000f5:	a1 0c 20 80 00       	mov    0x80200c,%eax
  8000fa:	8b 40 48             	mov    0x48(%eax),%eax
  8000fd:	83 ec 04             	sub    $0x4,%esp
  800100:	6a 07                	push   $0x7
  800102:	68 00 00 a0 00       	push   $0xa00000
  800107:	50                   	push   %eax
  800108:	e8 98 0b 00 00       	call   800ca5 <sys_page_alloc>
	memcpy(TEMP_ADDR, str1, strlen(str1) + 1);
  80010d:	83 c4 04             	add    $0x4,%esp
  800110:	ff 35 04 20 80 00    	pushl  0x802004
  800116:	e8 4e 07 00 00       	call   800869 <strlen>
  80011b:	83 c4 0c             	add    $0xc,%esp
  80011e:	83 c0 01             	add    $0x1,%eax
  800121:	50                   	push   %eax
  800122:	ff 35 04 20 80 00    	pushl  0x802004
  800128:	68 00 00 a0 00       	push   $0xa00000
  80012d:	e8 6a 09 00 00       	call   800a9c <memcpy>
	ipc_send(who, 0, TEMP_ADDR, PTE_P | PTE_W | PTE_U);
  800132:	6a 07                	push   $0x7
  800134:	68 00 00 a0 00       	push   $0xa00000
  800139:	6a 00                	push   $0x0
  80013b:	ff 75 f4             	pushl  -0xc(%ebp)
  80013e:	e8 84 10 00 00       	call   8011c7 <ipc_send>
	cprintf("parent\n");
  800143:	83 c4 14             	add    $0x14,%esp
  800146:	68 3b 16 80 00       	push   $0x80163b
  80014b:	e8 4e 01 00 00       	call   80029e <cprintf>
	ipc_recv(&who, TEMP_ADDR, 0);
  800150:	83 c4 0c             	add    $0xc,%esp
  800153:	6a 00                	push   $0x0
  800155:	68 00 00 a0 00       	push   $0xa00000
  80015a:	8d 45 f4             	lea    -0xc(%ebp),%eax
  80015d:	50                   	push   %eax
  80015e:	e8 d1 0f 00 00       	call   801134 <ipc_recv>

	cprintf("%x got message: %s\n", who, TEMP_ADDR);
  800163:	83 c4 0c             	add    $0xc,%esp
  800166:	68 00 00 a0 00       	push   $0xa00000
  80016b:	ff 75 f4             	pushl  -0xc(%ebp)
  80016e:	68 27 16 80 00       	push   $0x801627
  800173:	e8 26 01 00 00       	call   80029e <cprintf>

	if (strncmp(TEMP_ADDR, str2, strlen(str2)) == 0)
  800178:	83 c4 04             	add    $0x4,%esp
  80017b:	ff 35 00 20 80 00    	pushl  0x802000
  800181:	e8 e3 06 00 00       	call   800869 <strlen>
  800186:	83 c4 0c             	add    $0xc,%esp
  800189:	50                   	push   %eax
  80018a:	ff 35 00 20 80 00    	pushl  0x802000
  800190:	68 00 00 a0 00       	push   $0xa00000
  800195:	e8 d8 07 00 00       	call   800972 <strncmp>
  80019a:	83 c4 10             	add    $0x10,%esp
  80019d:	85 c0                	test   %eax,%eax
  80019f:	75 10                	jne    8001b1 <umain+0x17e>
		cprintf("parent received correct message\n");
  8001a1:	83 ec 0c             	sub    $0xc,%esp
  8001a4:	68 64 16 80 00       	push   $0x801664
  8001a9:	e8 f0 00 00 00       	call   80029e <cprintf>
  8001ae:	83 c4 10             	add    $0x10,%esp
	return;
}
  8001b1:	c9                   	leave  
  8001b2:	c3                   	ret    

008001b3 <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  8001b3:	55                   	push   %ebp
  8001b4:	89 e5                	mov    %esp,%ebp
  8001b6:	56                   	push   %esi
  8001b7:	53                   	push   %ebx
  8001b8:	8b 5d 08             	mov    0x8(%ebp),%ebx
  8001bb:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	//thisenv = 0;
	envid_t envid = sys_getenvid();
  8001be:	e8 a4 0a 00 00       	call   800c67 <sys_getenvid>
	thisenv = &envs[ENVX(envid)];
  8001c3:	25 ff 03 00 00       	and    $0x3ff,%eax
  8001c8:	6b c0 7c             	imul   $0x7c,%eax,%eax
  8001cb:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  8001d0:	a3 0c 20 80 00       	mov    %eax,0x80200c
	// save the name of the program so that panic() can use it
	if (argc > 0)
  8001d5:	85 db                	test   %ebx,%ebx
  8001d7:	7e 07                	jle    8001e0 <libmain+0x2d>
		binaryname = argv[0];
  8001d9:	8b 06                	mov    (%esi),%eax
  8001db:	a3 08 20 80 00       	mov    %eax,0x802008

	// call user main routine
	umain(argc, argv);
  8001e0:	83 ec 08             	sub    $0x8,%esp
  8001e3:	56                   	push   %esi
  8001e4:	53                   	push   %ebx
  8001e5:	e8 49 fe ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  8001ea:	e8 0a 00 00 00       	call   8001f9 <exit>
}
  8001ef:	83 c4 10             	add    $0x10,%esp
  8001f2:	8d 65 f8             	lea    -0x8(%ebp),%esp
  8001f5:	5b                   	pop    %ebx
  8001f6:	5e                   	pop    %esi
  8001f7:	5d                   	pop    %ebp
  8001f8:	c3                   	ret    

008001f9 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  8001f9:	55                   	push   %ebp
  8001fa:	89 e5                	mov    %esp,%ebp
  8001fc:	83 ec 14             	sub    $0x14,%esp
	sys_env_destroy(0);
  8001ff:	6a 00                	push   $0x0
  800201:	e8 20 0a 00 00       	call   800c26 <sys_env_destroy>
}
  800206:	83 c4 10             	add    $0x10,%esp
  800209:	c9                   	leave  
  80020a:	c3                   	ret    

0080020b <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  80020b:	55                   	push   %ebp
  80020c:	89 e5                	mov    %esp,%ebp
  80020e:	53                   	push   %ebx
  80020f:	83 ec 04             	sub    $0x4,%esp
  800212:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  800215:	8b 13                	mov    (%ebx),%edx
  800217:	8d 42 01             	lea    0x1(%edx),%eax
  80021a:	89 03                	mov    %eax,(%ebx)
  80021c:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80021f:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  800223:	3d ff 00 00 00       	cmp    $0xff,%eax
  800228:	75 1a                	jne    800244 <putch+0x39>
		sys_cputs(b->buf, b->idx);
  80022a:	83 ec 08             	sub    $0x8,%esp
  80022d:	68 ff 00 00 00       	push   $0xff
  800232:	8d 43 08             	lea    0x8(%ebx),%eax
  800235:	50                   	push   %eax
  800236:	e8 ae 09 00 00       	call   800be9 <sys_cputs>
		b->idx = 0;
  80023b:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  800241:	83 c4 10             	add    $0x10,%esp
	}
	b->cnt++;
  800244:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  800248:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  80024b:	c9                   	leave  
  80024c:	c3                   	ret    

0080024d <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  80024d:	55                   	push   %ebp
  80024e:	89 e5                	mov    %esp,%ebp
  800250:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  800256:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  80025d:	00 00 00 
	b.cnt = 0;
  800260:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  800267:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  80026a:	ff 75 0c             	pushl  0xc(%ebp)
  80026d:	ff 75 08             	pushl  0x8(%ebp)
  800270:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  800276:	50                   	push   %eax
  800277:	68 0b 02 80 00       	push   $0x80020b
  80027c:	e8 1a 01 00 00       	call   80039b <vprintfmt>
	sys_cputs(b.buf, b.idx);
  800281:	83 c4 08             	add    $0x8,%esp
  800284:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
  80028a:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  800290:	50                   	push   %eax
  800291:	e8 53 09 00 00       	call   800be9 <sys_cputs>

	return b.cnt;
}
  800296:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  80029c:	c9                   	leave  
  80029d:	c3                   	ret    

0080029e <cprintf>:

int
cprintf(const char *fmt, ...)
{
  80029e:	55                   	push   %ebp
  80029f:	89 e5                	mov    %esp,%ebp
  8002a1:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  8002a4:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  8002a7:	50                   	push   %eax
  8002a8:	ff 75 08             	pushl  0x8(%ebp)
  8002ab:	e8 9d ff ff ff       	call   80024d <vcprintf>
	va_end(ap);

	return cnt;
}
  8002b0:	c9                   	leave  
  8002b1:	c3                   	ret    

008002b2 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  8002b2:	55                   	push   %ebp
  8002b3:	89 e5                	mov    %esp,%ebp
  8002b5:	57                   	push   %edi
  8002b6:	56                   	push   %esi
  8002b7:	53                   	push   %ebx
  8002b8:	83 ec 1c             	sub    $0x1c,%esp
  8002bb:	89 c7                	mov    %eax,%edi
  8002bd:	89 d6                	mov    %edx,%esi
  8002bf:	8b 45 08             	mov    0x8(%ebp),%eax
  8002c2:	8b 55 0c             	mov    0xc(%ebp),%edx
  8002c5:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8002c8:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  8002cb:	8b 4d 10             	mov    0x10(%ebp),%ecx
  8002ce:	bb 00 00 00 00       	mov    $0x0,%ebx
  8002d3:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  8002d6:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  8002d9:	39 d3                	cmp    %edx,%ebx
  8002db:	72 05                	jb     8002e2 <printnum+0x30>
  8002dd:	39 45 10             	cmp    %eax,0x10(%ebp)
  8002e0:	77 45                	ja     800327 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  8002e2:	83 ec 0c             	sub    $0xc,%esp
  8002e5:	ff 75 18             	pushl  0x18(%ebp)
  8002e8:	8b 45 14             	mov    0x14(%ebp),%eax
  8002eb:	8d 58 ff             	lea    -0x1(%eax),%ebx
  8002ee:	53                   	push   %ebx
  8002ef:	ff 75 10             	pushl  0x10(%ebp)
  8002f2:	83 ec 08             	sub    $0x8,%esp
  8002f5:	ff 75 e4             	pushl  -0x1c(%ebp)
  8002f8:	ff 75 e0             	pushl  -0x20(%ebp)
  8002fb:	ff 75 dc             	pushl  -0x24(%ebp)
  8002fe:	ff 75 d8             	pushl  -0x28(%ebp)
  800301:	e8 7a 10 00 00       	call   801380 <__udivdi3>
  800306:	83 c4 18             	add    $0x18,%esp
  800309:	52                   	push   %edx
  80030a:	50                   	push   %eax
  80030b:	89 f2                	mov    %esi,%edx
  80030d:	89 f8                	mov    %edi,%eax
  80030f:	e8 9e ff ff ff       	call   8002b2 <printnum>
  800314:	83 c4 20             	add    $0x20,%esp
  800317:	eb 18                	jmp    800331 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  800319:	83 ec 08             	sub    $0x8,%esp
  80031c:	56                   	push   %esi
  80031d:	ff 75 18             	pushl  0x18(%ebp)
  800320:	ff d7                	call   *%edi
  800322:	83 c4 10             	add    $0x10,%esp
  800325:	eb 03                	jmp    80032a <printnum+0x78>
  800327:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  80032a:	83 eb 01             	sub    $0x1,%ebx
  80032d:	85 db                	test   %ebx,%ebx
  80032f:	7f e8                	jg     800319 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  800331:	83 ec 08             	sub    $0x8,%esp
  800334:	56                   	push   %esi
  800335:	83 ec 04             	sub    $0x4,%esp
  800338:	ff 75 e4             	pushl  -0x1c(%ebp)
  80033b:	ff 75 e0             	pushl  -0x20(%ebp)
  80033e:	ff 75 dc             	pushl  -0x24(%ebp)
  800341:	ff 75 d8             	pushl  -0x28(%ebp)
  800344:	e8 67 11 00 00       	call   8014b0 <__umoddi3>
  800349:	83 c4 14             	add    $0x14,%esp
  80034c:	0f be 80 dc 16 80 00 	movsbl 0x8016dc(%eax),%eax
  800353:	50                   	push   %eax
  800354:	ff d7                	call   *%edi
}
  800356:	83 c4 10             	add    $0x10,%esp
  800359:	8d 65 f4             	lea    -0xc(%ebp),%esp
  80035c:	5b                   	pop    %ebx
  80035d:	5e                   	pop    %esi
  80035e:	5f                   	pop    %edi
  80035f:	5d                   	pop    %ebp
  800360:	c3                   	ret    

00800361 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  800361:	55                   	push   %ebp
  800362:	89 e5                	mov    %esp,%ebp
  800364:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  800367:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  80036b:	8b 10                	mov    (%eax),%edx
  80036d:	3b 50 04             	cmp    0x4(%eax),%edx
  800370:	73 0a                	jae    80037c <sprintputch+0x1b>
		*b->buf++ = ch;
  800372:	8d 4a 01             	lea    0x1(%edx),%ecx
  800375:	89 08                	mov    %ecx,(%eax)
  800377:	8b 45 08             	mov    0x8(%ebp),%eax
  80037a:	88 02                	mov    %al,(%edx)
}
  80037c:	5d                   	pop    %ebp
  80037d:	c3                   	ret    

0080037e <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  80037e:	55                   	push   %ebp
  80037f:	89 e5                	mov    %esp,%ebp
  800381:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
  800384:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  800387:	50                   	push   %eax
  800388:	ff 75 10             	pushl  0x10(%ebp)
  80038b:	ff 75 0c             	pushl  0xc(%ebp)
  80038e:	ff 75 08             	pushl  0x8(%ebp)
  800391:	e8 05 00 00 00       	call   80039b <vprintfmt>
	va_end(ap);
}
  800396:	83 c4 10             	add    $0x10,%esp
  800399:	c9                   	leave  
  80039a:	c3                   	ret    

0080039b <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  80039b:	55                   	push   %ebp
  80039c:	89 e5                	mov    %esp,%ebp
  80039e:	57                   	push   %edi
  80039f:	56                   	push   %esi
  8003a0:	53                   	push   %ebx
  8003a1:	83 ec 2c             	sub    $0x2c,%esp
  8003a4:	8b 75 08             	mov    0x8(%ebp),%esi
  8003a7:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8003aa:	8b 7d 10             	mov    0x10(%ebp),%edi
  8003ad:	eb 12                	jmp    8003c1 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  8003af:	85 c0                	test   %eax,%eax
  8003b1:	0f 84 42 04 00 00    	je     8007f9 <vprintfmt+0x45e>
				return;
			putch(ch, putdat);
  8003b7:	83 ec 08             	sub    $0x8,%esp
  8003ba:	53                   	push   %ebx
  8003bb:	50                   	push   %eax
  8003bc:	ff d6                	call   *%esi
  8003be:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  8003c1:	83 c7 01             	add    $0x1,%edi
  8003c4:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  8003c8:	83 f8 25             	cmp    $0x25,%eax
  8003cb:	75 e2                	jne    8003af <vprintfmt+0x14>
  8003cd:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
  8003d1:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  8003d8:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  8003df:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
  8003e6:	b9 00 00 00 00       	mov    $0x0,%ecx
  8003eb:	eb 07                	jmp    8003f4 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003ed:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  8003f0:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003f4:	8d 47 01             	lea    0x1(%edi),%eax
  8003f7:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  8003fa:	0f b6 07             	movzbl (%edi),%eax
  8003fd:	0f b6 d0             	movzbl %al,%edx
  800400:	83 e8 23             	sub    $0x23,%eax
  800403:	3c 55                	cmp    $0x55,%al
  800405:	0f 87 d3 03 00 00    	ja     8007de <vprintfmt+0x443>
  80040b:	0f b6 c0             	movzbl %al,%eax
  80040e:	ff 24 85 a0 17 80 00 	jmp    *0x8017a0(,%eax,4)
  800415:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  800418:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  80041c:	eb d6                	jmp    8003f4 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80041e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800421:	b8 00 00 00 00       	mov    $0x0,%eax
  800426:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  800429:	8d 04 80             	lea    (%eax,%eax,4),%eax
  80042c:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
  800430:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
  800433:	8d 4a d0             	lea    -0x30(%edx),%ecx
  800436:	83 f9 09             	cmp    $0x9,%ecx
  800439:	77 3f                	ja     80047a <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  80043b:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  80043e:	eb e9                	jmp    800429 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  800440:	8b 45 14             	mov    0x14(%ebp),%eax
  800443:	8b 00                	mov    (%eax),%eax
  800445:	89 45 d0             	mov    %eax,-0x30(%ebp)
  800448:	8b 45 14             	mov    0x14(%ebp),%eax
  80044b:	8d 40 04             	lea    0x4(%eax),%eax
  80044e:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800451:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  800454:	eb 2a                	jmp    800480 <vprintfmt+0xe5>
  800456:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800459:	85 c0                	test   %eax,%eax
  80045b:	ba 00 00 00 00       	mov    $0x0,%edx
  800460:	0f 49 d0             	cmovns %eax,%edx
  800463:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800466:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800469:	eb 89                	jmp    8003f4 <vprintfmt+0x59>
  80046b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  80046e:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  800475:	e9 7a ff ff ff       	jmp    8003f4 <vprintfmt+0x59>
  80047a:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  80047d:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
  800480:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800484:	0f 89 6a ff ff ff    	jns    8003f4 <vprintfmt+0x59>
				width = precision, precision = -1;
  80048a:	8b 45 d0             	mov    -0x30(%ebp),%eax
  80048d:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800490:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  800497:	e9 58 ff ff ff       	jmp    8003f4 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  80049c:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80049f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  8004a2:	e9 4d ff ff ff       	jmp    8003f4 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  8004a7:	8b 45 14             	mov    0x14(%ebp),%eax
  8004aa:	8d 78 04             	lea    0x4(%eax),%edi
  8004ad:	83 ec 08             	sub    $0x8,%esp
  8004b0:	53                   	push   %ebx
  8004b1:	ff 30                	pushl  (%eax)
  8004b3:	ff d6                	call   *%esi
			break;
  8004b5:	83 c4 10             	add    $0x10,%esp
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  8004b8:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004bb:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  8004be:	e9 fe fe ff ff       	jmp    8003c1 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
  8004c3:	8b 45 14             	mov    0x14(%ebp),%eax
  8004c6:	8d 78 04             	lea    0x4(%eax),%edi
  8004c9:	8b 00                	mov    (%eax),%eax
  8004cb:	99                   	cltd   
  8004cc:	31 d0                	xor    %edx,%eax
  8004ce:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  8004d0:	83 f8 09             	cmp    $0x9,%eax
  8004d3:	7f 0b                	jg     8004e0 <vprintfmt+0x145>
  8004d5:	8b 14 85 00 19 80 00 	mov    0x801900(,%eax,4),%edx
  8004dc:	85 d2                	test   %edx,%edx
  8004de:	75 1b                	jne    8004fb <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
  8004e0:	50                   	push   %eax
  8004e1:	68 f4 16 80 00       	push   $0x8016f4
  8004e6:	53                   	push   %ebx
  8004e7:	56                   	push   %esi
  8004e8:	e8 91 fe ff ff       	call   80037e <printfmt>
  8004ed:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
  8004f0:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004f3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  8004f6:	e9 c6 fe ff ff       	jmp    8003c1 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
  8004fb:	52                   	push   %edx
  8004fc:	68 fd 16 80 00       	push   $0x8016fd
  800501:	53                   	push   %ebx
  800502:	56                   	push   %esi
  800503:	e8 76 fe ff ff       	call   80037e <printfmt>
  800508:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
  80050b:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80050e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800511:	e9 ab fe ff ff       	jmp    8003c1 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  800516:	8b 45 14             	mov    0x14(%ebp),%eax
  800519:	83 c0 04             	add    $0x4,%eax
  80051c:	89 45 cc             	mov    %eax,-0x34(%ebp)
  80051f:	8b 45 14             	mov    0x14(%ebp),%eax
  800522:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  800524:	85 ff                	test   %edi,%edi
  800526:	b8 ed 16 80 00       	mov    $0x8016ed,%eax
  80052b:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  80052e:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800532:	0f 8e 94 00 00 00    	jle    8005cc <vprintfmt+0x231>
  800538:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  80053c:	0f 84 98 00 00 00    	je     8005da <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
  800542:	83 ec 08             	sub    $0x8,%esp
  800545:	ff 75 d0             	pushl  -0x30(%ebp)
  800548:	57                   	push   %edi
  800549:	e8 33 03 00 00       	call   800881 <strnlen>
  80054e:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  800551:	29 c1                	sub    %eax,%ecx
  800553:	89 4d c8             	mov    %ecx,-0x38(%ebp)
  800556:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  800559:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  80055d:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800560:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  800563:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800565:	eb 0f                	jmp    800576 <vprintfmt+0x1db>
					putch(padc, putdat);
  800567:	83 ec 08             	sub    $0x8,%esp
  80056a:	53                   	push   %ebx
  80056b:	ff 75 e0             	pushl  -0x20(%ebp)
  80056e:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800570:	83 ef 01             	sub    $0x1,%edi
  800573:	83 c4 10             	add    $0x10,%esp
  800576:	85 ff                	test   %edi,%edi
  800578:	7f ed                	jg     800567 <vprintfmt+0x1cc>
  80057a:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  80057d:	8b 4d c8             	mov    -0x38(%ebp),%ecx
  800580:	85 c9                	test   %ecx,%ecx
  800582:	b8 00 00 00 00       	mov    $0x0,%eax
  800587:	0f 49 c1             	cmovns %ecx,%eax
  80058a:	29 c1                	sub    %eax,%ecx
  80058c:	89 75 08             	mov    %esi,0x8(%ebp)
  80058f:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800592:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800595:	89 cb                	mov    %ecx,%ebx
  800597:	eb 4d                	jmp    8005e6 <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  800599:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  80059d:	74 1b                	je     8005ba <vprintfmt+0x21f>
  80059f:	0f be c0             	movsbl %al,%eax
  8005a2:	83 e8 20             	sub    $0x20,%eax
  8005a5:	83 f8 5e             	cmp    $0x5e,%eax
  8005a8:	76 10                	jbe    8005ba <vprintfmt+0x21f>
					putch('?', putdat);
  8005aa:	83 ec 08             	sub    $0x8,%esp
  8005ad:	ff 75 0c             	pushl  0xc(%ebp)
  8005b0:	6a 3f                	push   $0x3f
  8005b2:	ff 55 08             	call   *0x8(%ebp)
  8005b5:	83 c4 10             	add    $0x10,%esp
  8005b8:	eb 0d                	jmp    8005c7 <vprintfmt+0x22c>
				else
					putch(ch, putdat);
  8005ba:	83 ec 08             	sub    $0x8,%esp
  8005bd:	ff 75 0c             	pushl  0xc(%ebp)
  8005c0:	52                   	push   %edx
  8005c1:	ff 55 08             	call   *0x8(%ebp)
  8005c4:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  8005c7:	83 eb 01             	sub    $0x1,%ebx
  8005ca:	eb 1a                	jmp    8005e6 <vprintfmt+0x24b>
  8005cc:	89 75 08             	mov    %esi,0x8(%ebp)
  8005cf:	8b 75 d0             	mov    -0x30(%ebp),%esi
  8005d2:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  8005d5:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  8005d8:	eb 0c                	jmp    8005e6 <vprintfmt+0x24b>
  8005da:	89 75 08             	mov    %esi,0x8(%ebp)
  8005dd:	8b 75 d0             	mov    -0x30(%ebp),%esi
  8005e0:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  8005e3:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  8005e6:	83 c7 01             	add    $0x1,%edi
  8005e9:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  8005ed:	0f be d0             	movsbl %al,%edx
  8005f0:	85 d2                	test   %edx,%edx
  8005f2:	74 23                	je     800617 <vprintfmt+0x27c>
  8005f4:	85 f6                	test   %esi,%esi
  8005f6:	78 a1                	js     800599 <vprintfmt+0x1fe>
  8005f8:	83 ee 01             	sub    $0x1,%esi
  8005fb:	79 9c                	jns    800599 <vprintfmt+0x1fe>
  8005fd:	89 df                	mov    %ebx,%edi
  8005ff:	8b 75 08             	mov    0x8(%ebp),%esi
  800602:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800605:	eb 18                	jmp    80061f <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  800607:	83 ec 08             	sub    $0x8,%esp
  80060a:	53                   	push   %ebx
  80060b:	6a 20                	push   $0x20
  80060d:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  80060f:	83 ef 01             	sub    $0x1,%edi
  800612:	83 c4 10             	add    $0x10,%esp
  800615:	eb 08                	jmp    80061f <vprintfmt+0x284>
  800617:	89 df                	mov    %ebx,%edi
  800619:	8b 75 08             	mov    0x8(%ebp),%esi
  80061c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  80061f:	85 ff                	test   %edi,%edi
  800621:	7f e4                	jg     800607 <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  800623:	8b 45 cc             	mov    -0x34(%ebp),%eax
  800626:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800629:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80062c:	e9 90 fd ff ff       	jmp    8003c1 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  800631:	83 f9 01             	cmp    $0x1,%ecx
  800634:	7e 19                	jle    80064f <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
  800636:	8b 45 14             	mov    0x14(%ebp),%eax
  800639:	8b 50 04             	mov    0x4(%eax),%edx
  80063c:	8b 00                	mov    (%eax),%eax
  80063e:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800641:	89 55 dc             	mov    %edx,-0x24(%ebp)
  800644:	8b 45 14             	mov    0x14(%ebp),%eax
  800647:	8d 40 08             	lea    0x8(%eax),%eax
  80064a:	89 45 14             	mov    %eax,0x14(%ebp)
  80064d:	eb 38                	jmp    800687 <vprintfmt+0x2ec>
	else if (lflag)
  80064f:	85 c9                	test   %ecx,%ecx
  800651:	74 1b                	je     80066e <vprintfmt+0x2d3>
		return va_arg(*ap, long);
  800653:	8b 45 14             	mov    0x14(%ebp),%eax
  800656:	8b 00                	mov    (%eax),%eax
  800658:	89 45 d8             	mov    %eax,-0x28(%ebp)
  80065b:	89 c1                	mov    %eax,%ecx
  80065d:	c1 f9 1f             	sar    $0x1f,%ecx
  800660:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  800663:	8b 45 14             	mov    0x14(%ebp),%eax
  800666:	8d 40 04             	lea    0x4(%eax),%eax
  800669:	89 45 14             	mov    %eax,0x14(%ebp)
  80066c:	eb 19                	jmp    800687 <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
  80066e:	8b 45 14             	mov    0x14(%ebp),%eax
  800671:	8b 00                	mov    (%eax),%eax
  800673:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800676:	89 c1                	mov    %eax,%ecx
  800678:	c1 f9 1f             	sar    $0x1f,%ecx
  80067b:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  80067e:	8b 45 14             	mov    0x14(%ebp),%eax
  800681:	8d 40 04             	lea    0x4(%eax),%eax
  800684:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  800687:	8b 55 d8             	mov    -0x28(%ebp),%edx
  80068a:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  80068d:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  800692:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  800696:	0f 89 0e 01 00 00    	jns    8007aa <vprintfmt+0x40f>
				putch('-', putdat);
  80069c:	83 ec 08             	sub    $0x8,%esp
  80069f:	53                   	push   %ebx
  8006a0:	6a 2d                	push   $0x2d
  8006a2:	ff d6                	call   *%esi
				num = -(long long) num;
  8006a4:	8b 55 d8             	mov    -0x28(%ebp),%edx
  8006a7:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  8006aa:	f7 da                	neg    %edx
  8006ac:	83 d1 00             	adc    $0x0,%ecx
  8006af:	f7 d9                	neg    %ecx
  8006b1:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
  8006b4:	b8 0a 00 00 00       	mov    $0xa,%eax
  8006b9:	e9 ec 00 00 00       	jmp    8007aa <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  8006be:	83 f9 01             	cmp    $0x1,%ecx
  8006c1:	7e 18                	jle    8006db <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
  8006c3:	8b 45 14             	mov    0x14(%ebp),%eax
  8006c6:	8b 10                	mov    (%eax),%edx
  8006c8:	8b 48 04             	mov    0x4(%eax),%ecx
  8006cb:	8d 40 08             	lea    0x8(%eax),%eax
  8006ce:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  8006d1:	b8 0a 00 00 00       	mov    $0xa,%eax
  8006d6:	e9 cf 00 00 00       	jmp    8007aa <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
  8006db:	85 c9                	test   %ecx,%ecx
  8006dd:	74 1a                	je     8006f9 <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
  8006df:	8b 45 14             	mov    0x14(%ebp),%eax
  8006e2:	8b 10                	mov    (%eax),%edx
  8006e4:	b9 00 00 00 00       	mov    $0x0,%ecx
  8006e9:	8d 40 04             	lea    0x4(%eax),%eax
  8006ec:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  8006ef:	b8 0a 00 00 00       	mov    $0xa,%eax
  8006f4:	e9 b1 00 00 00       	jmp    8007aa <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
  8006f9:	8b 45 14             	mov    0x14(%ebp),%eax
  8006fc:	8b 10                	mov    (%eax),%edx
  8006fe:	b9 00 00 00 00       	mov    $0x0,%ecx
  800703:	8d 40 04             	lea    0x4(%eax),%eax
  800706:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  800709:	b8 0a 00 00 00       	mov    $0xa,%eax
  80070e:	e9 97 00 00 00       	jmp    8007aa <vprintfmt+0x40f>
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
  800713:	83 ec 08             	sub    $0x8,%esp
  800716:	53                   	push   %ebx
  800717:	6a 58                	push   $0x58
  800719:	ff d6                	call   *%esi
			putch('X', putdat);
  80071b:	83 c4 08             	add    $0x8,%esp
  80071e:	53                   	push   %ebx
  80071f:	6a 58                	push   $0x58
  800721:	ff d6                	call   *%esi
			putch('X', putdat);
  800723:	83 c4 08             	add    $0x8,%esp
  800726:	53                   	push   %ebx
  800727:	6a 58                	push   $0x58
  800729:	ff d6                	call   *%esi
			break;
  80072b:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80072e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
  800731:	e9 8b fc ff ff       	jmp    8003c1 <vprintfmt+0x26>

		// pointer
		case 'p':
			putch('0', putdat);
  800736:	83 ec 08             	sub    $0x8,%esp
  800739:	53                   	push   %ebx
  80073a:	6a 30                	push   $0x30
  80073c:	ff d6                	call   *%esi
			putch('x', putdat);
  80073e:	83 c4 08             	add    $0x8,%esp
  800741:	53                   	push   %ebx
  800742:	6a 78                	push   $0x78
  800744:	ff d6                	call   *%esi
			num = (unsigned long long)
  800746:	8b 45 14             	mov    0x14(%ebp),%eax
  800749:	8b 10                	mov    (%eax),%edx
  80074b:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
  800750:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  800753:	8d 40 04             	lea    0x4(%eax),%eax
  800756:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
  800759:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
  80075e:	eb 4a                	jmp    8007aa <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  800760:	83 f9 01             	cmp    $0x1,%ecx
  800763:	7e 15                	jle    80077a <vprintfmt+0x3df>
		return va_arg(*ap, unsigned long long);
  800765:	8b 45 14             	mov    0x14(%ebp),%eax
  800768:	8b 10                	mov    (%eax),%edx
  80076a:	8b 48 04             	mov    0x4(%eax),%ecx
  80076d:	8d 40 08             	lea    0x8(%eax),%eax
  800770:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  800773:	b8 10 00 00 00       	mov    $0x10,%eax
  800778:	eb 30                	jmp    8007aa <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
  80077a:	85 c9                	test   %ecx,%ecx
  80077c:	74 17                	je     800795 <vprintfmt+0x3fa>
		return va_arg(*ap, unsigned long);
  80077e:	8b 45 14             	mov    0x14(%ebp),%eax
  800781:	8b 10                	mov    (%eax),%edx
  800783:	b9 00 00 00 00       	mov    $0x0,%ecx
  800788:	8d 40 04             	lea    0x4(%eax),%eax
  80078b:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  80078e:	b8 10 00 00 00       	mov    $0x10,%eax
  800793:	eb 15                	jmp    8007aa <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
  800795:	8b 45 14             	mov    0x14(%ebp),%eax
  800798:	8b 10                	mov    (%eax),%edx
  80079a:	b9 00 00 00 00       	mov    $0x0,%ecx
  80079f:	8d 40 04             	lea    0x4(%eax),%eax
  8007a2:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  8007a5:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
  8007aa:	83 ec 0c             	sub    $0xc,%esp
  8007ad:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  8007b1:	57                   	push   %edi
  8007b2:	ff 75 e0             	pushl  -0x20(%ebp)
  8007b5:	50                   	push   %eax
  8007b6:	51                   	push   %ecx
  8007b7:	52                   	push   %edx
  8007b8:	89 da                	mov    %ebx,%edx
  8007ba:	89 f0                	mov    %esi,%eax
  8007bc:	e8 f1 fa ff ff       	call   8002b2 <printnum>
			break;
  8007c1:	83 c4 20             	add    $0x20,%esp
  8007c4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8007c7:	e9 f5 fb ff ff       	jmp    8003c1 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  8007cc:	83 ec 08             	sub    $0x8,%esp
  8007cf:	53                   	push   %ebx
  8007d0:	52                   	push   %edx
  8007d1:	ff d6                	call   *%esi
			break;
  8007d3:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8007d6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  8007d9:	e9 e3 fb ff ff       	jmp    8003c1 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  8007de:	83 ec 08             	sub    $0x8,%esp
  8007e1:	53                   	push   %ebx
  8007e2:	6a 25                	push   $0x25
  8007e4:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  8007e6:	83 c4 10             	add    $0x10,%esp
  8007e9:	eb 03                	jmp    8007ee <vprintfmt+0x453>
  8007eb:	83 ef 01             	sub    $0x1,%edi
  8007ee:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  8007f2:	75 f7                	jne    8007eb <vprintfmt+0x450>
  8007f4:	e9 c8 fb ff ff       	jmp    8003c1 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
  8007f9:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8007fc:	5b                   	pop    %ebx
  8007fd:	5e                   	pop    %esi
  8007fe:	5f                   	pop    %edi
  8007ff:	5d                   	pop    %ebp
  800800:	c3                   	ret    

00800801 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  800801:	55                   	push   %ebp
  800802:	89 e5                	mov    %esp,%ebp
  800804:	83 ec 18             	sub    $0x18,%esp
  800807:	8b 45 08             	mov    0x8(%ebp),%eax
  80080a:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  80080d:	89 45 ec             	mov    %eax,-0x14(%ebp)
  800810:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  800814:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  800817:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  80081e:	85 c0                	test   %eax,%eax
  800820:	74 26                	je     800848 <vsnprintf+0x47>
  800822:	85 d2                	test   %edx,%edx
  800824:	7e 22                	jle    800848 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  800826:	ff 75 14             	pushl  0x14(%ebp)
  800829:	ff 75 10             	pushl  0x10(%ebp)
  80082c:	8d 45 ec             	lea    -0x14(%ebp),%eax
  80082f:	50                   	push   %eax
  800830:	68 61 03 80 00       	push   $0x800361
  800835:	e8 61 fb ff ff       	call   80039b <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  80083a:	8b 45 ec             	mov    -0x14(%ebp),%eax
  80083d:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  800840:	8b 45 f4             	mov    -0xc(%ebp),%eax
  800843:	83 c4 10             	add    $0x10,%esp
  800846:	eb 05                	jmp    80084d <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  800848:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  80084d:	c9                   	leave  
  80084e:	c3                   	ret    

0080084f <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  80084f:	55                   	push   %ebp
  800850:	89 e5                	mov    %esp,%ebp
  800852:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  800855:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  800858:	50                   	push   %eax
  800859:	ff 75 10             	pushl  0x10(%ebp)
  80085c:	ff 75 0c             	pushl  0xc(%ebp)
  80085f:	ff 75 08             	pushl  0x8(%ebp)
  800862:	e8 9a ff ff ff       	call   800801 <vsnprintf>
	va_end(ap);

	return rc;
}
  800867:	c9                   	leave  
  800868:	c3                   	ret    

00800869 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  800869:	55                   	push   %ebp
  80086a:	89 e5                	mov    %esp,%ebp
  80086c:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  80086f:	b8 00 00 00 00       	mov    $0x0,%eax
  800874:	eb 03                	jmp    800879 <strlen+0x10>
		n++;
  800876:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  800879:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  80087d:	75 f7                	jne    800876 <strlen+0xd>
		n++;
	return n;
}
  80087f:	5d                   	pop    %ebp
  800880:	c3                   	ret    

00800881 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  800881:	55                   	push   %ebp
  800882:	89 e5                	mov    %esp,%ebp
  800884:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800887:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  80088a:	ba 00 00 00 00       	mov    $0x0,%edx
  80088f:	eb 03                	jmp    800894 <strnlen+0x13>
		n++;
  800891:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800894:	39 c2                	cmp    %eax,%edx
  800896:	74 08                	je     8008a0 <strnlen+0x1f>
  800898:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  80089c:	75 f3                	jne    800891 <strnlen+0x10>
  80089e:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
  8008a0:	5d                   	pop    %ebp
  8008a1:	c3                   	ret    

008008a2 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  8008a2:	55                   	push   %ebp
  8008a3:	89 e5                	mov    %esp,%ebp
  8008a5:	53                   	push   %ebx
  8008a6:	8b 45 08             	mov    0x8(%ebp),%eax
  8008a9:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  8008ac:	89 c2                	mov    %eax,%edx
  8008ae:	83 c2 01             	add    $0x1,%edx
  8008b1:	83 c1 01             	add    $0x1,%ecx
  8008b4:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  8008b8:	88 5a ff             	mov    %bl,-0x1(%edx)
  8008bb:	84 db                	test   %bl,%bl
  8008bd:	75 ef                	jne    8008ae <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  8008bf:	5b                   	pop    %ebx
  8008c0:	5d                   	pop    %ebp
  8008c1:	c3                   	ret    

008008c2 <strcat>:

char *
strcat(char *dst, const char *src)
{
  8008c2:	55                   	push   %ebp
  8008c3:	89 e5                	mov    %esp,%ebp
  8008c5:	53                   	push   %ebx
  8008c6:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  8008c9:	53                   	push   %ebx
  8008ca:	e8 9a ff ff ff       	call   800869 <strlen>
  8008cf:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  8008d2:	ff 75 0c             	pushl  0xc(%ebp)
  8008d5:	01 d8                	add    %ebx,%eax
  8008d7:	50                   	push   %eax
  8008d8:	e8 c5 ff ff ff       	call   8008a2 <strcpy>
	return dst;
}
  8008dd:	89 d8                	mov    %ebx,%eax
  8008df:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8008e2:	c9                   	leave  
  8008e3:	c3                   	ret    

008008e4 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  8008e4:	55                   	push   %ebp
  8008e5:	89 e5                	mov    %esp,%ebp
  8008e7:	56                   	push   %esi
  8008e8:	53                   	push   %ebx
  8008e9:	8b 75 08             	mov    0x8(%ebp),%esi
  8008ec:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8008ef:	89 f3                	mov    %esi,%ebx
  8008f1:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8008f4:	89 f2                	mov    %esi,%edx
  8008f6:	eb 0f                	jmp    800907 <strncpy+0x23>
		*dst++ = *src;
  8008f8:	83 c2 01             	add    $0x1,%edx
  8008fb:	0f b6 01             	movzbl (%ecx),%eax
  8008fe:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  800901:	80 39 01             	cmpb   $0x1,(%ecx)
  800904:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800907:	39 da                	cmp    %ebx,%edx
  800909:	75 ed                	jne    8008f8 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  80090b:	89 f0                	mov    %esi,%eax
  80090d:	5b                   	pop    %ebx
  80090e:	5e                   	pop    %esi
  80090f:	5d                   	pop    %ebp
  800910:	c3                   	ret    

00800911 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  800911:	55                   	push   %ebp
  800912:	89 e5                	mov    %esp,%ebp
  800914:	56                   	push   %esi
  800915:	53                   	push   %ebx
  800916:	8b 75 08             	mov    0x8(%ebp),%esi
  800919:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80091c:	8b 55 10             	mov    0x10(%ebp),%edx
  80091f:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  800921:	85 d2                	test   %edx,%edx
  800923:	74 21                	je     800946 <strlcpy+0x35>
  800925:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
  800929:	89 f2                	mov    %esi,%edx
  80092b:	eb 09                	jmp    800936 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  80092d:	83 c2 01             	add    $0x1,%edx
  800930:	83 c1 01             	add    $0x1,%ecx
  800933:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  800936:	39 c2                	cmp    %eax,%edx
  800938:	74 09                	je     800943 <strlcpy+0x32>
  80093a:	0f b6 19             	movzbl (%ecx),%ebx
  80093d:	84 db                	test   %bl,%bl
  80093f:	75 ec                	jne    80092d <strlcpy+0x1c>
  800941:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
  800943:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  800946:	29 f0                	sub    %esi,%eax
}
  800948:	5b                   	pop    %ebx
  800949:	5e                   	pop    %esi
  80094a:	5d                   	pop    %ebp
  80094b:	c3                   	ret    

0080094c <strcmp>:

int
strcmp(const char *p, const char *q)
{
  80094c:	55                   	push   %ebp
  80094d:	89 e5                	mov    %esp,%ebp
  80094f:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800952:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  800955:	eb 06                	jmp    80095d <strcmp+0x11>
		p++, q++;
  800957:	83 c1 01             	add    $0x1,%ecx
  80095a:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  80095d:	0f b6 01             	movzbl (%ecx),%eax
  800960:	84 c0                	test   %al,%al
  800962:	74 04                	je     800968 <strcmp+0x1c>
  800964:	3a 02                	cmp    (%edx),%al
  800966:	74 ef                	je     800957 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800968:	0f b6 c0             	movzbl %al,%eax
  80096b:	0f b6 12             	movzbl (%edx),%edx
  80096e:	29 d0                	sub    %edx,%eax
}
  800970:	5d                   	pop    %ebp
  800971:	c3                   	ret    

00800972 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  800972:	55                   	push   %ebp
  800973:	89 e5                	mov    %esp,%ebp
  800975:	53                   	push   %ebx
  800976:	8b 45 08             	mov    0x8(%ebp),%eax
  800979:	8b 55 0c             	mov    0xc(%ebp),%edx
  80097c:	89 c3                	mov    %eax,%ebx
  80097e:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  800981:	eb 06                	jmp    800989 <strncmp+0x17>
		n--, p++, q++;
  800983:	83 c0 01             	add    $0x1,%eax
  800986:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  800989:	39 d8                	cmp    %ebx,%eax
  80098b:	74 15                	je     8009a2 <strncmp+0x30>
  80098d:	0f b6 08             	movzbl (%eax),%ecx
  800990:	84 c9                	test   %cl,%cl
  800992:	74 04                	je     800998 <strncmp+0x26>
  800994:	3a 0a                	cmp    (%edx),%cl
  800996:	74 eb                	je     800983 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  800998:	0f b6 00             	movzbl (%eax),%eax
  80099b:	0f b6 12             	movzbl (%edx),%edx
  80099e:	29 d0                	sub    %edx,%eax
  8009a0:	eb 05                	jmp    8009a7 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  8009a2:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  8009a7:	5b                   	pop    %ebx
  8009a8:	5d                   	pop    %ebp
  8009a9:	c3                   	ret    

008009aa <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  8009aa:	55                   	push   %ebp
  8009ab:	89 e5                	mov    %esp,%ebp
  8009ad:	8b 45 08             	mov    0x8(%ebp),%eax
  8009b0:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8009b4:	eb 07                	jmp    8009bd <strchr+0x13>
		if (*s == c)
  8009b6:	38 ca                	cmp    %cl,%dl
  8009b8:	74 0f                	je     8009c9 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  8009ba:	83 c0 01             	add    $0x1,%eax
  8009bd:	0f b6 10             	movzbl (%eax),%edx
  8009c0:	84 d2                	test   %dl,%dl
  8009c2:	75 f2                	jne    8009b6 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  8009c4:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8009c9:	5d                   	pop    %ebp
  8009ca:	c3                   	ret    

008009cb <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  8009cb:	55                   	push   %ebp
  8009cc:	89 e5                	mov    %esp,%ebp
  8009ce:	8b 45 08             	mov    0x8(%ebp),%eax
  8009d1:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8009d5:	eb 03                	jmp    8009da <strfind+0xf>
  8009d7:	83 c0 01             	add    $0x1,%eax
  8009da:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  8009dd:	38 ca                	cmp    %cl,%dl
  8009df:	74 04                	je     8009e5 <strfind+0x1a>
  8009e1:	84 d2                	test   %dl,%dl
  8009e3:	75 f2                	jne    8009d7 <strfind+0xc>
			break;
	return (char *) s;
}
  8009e5:	5d                   	pop    %ebp
  8009e6:	c3                   	ret    

008009e7 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  8009e7:	55                   	push   %ebp
  8009e8:	89 e5                	mov    %esp,%ebp
  8009ea:	57                   	push   %edi
  8009eb:	56                   	push   %esi
  8009ec:	53                   	push   %ebx
  8009ed:	8b 7d 08             	mov    0x8(%ebp),%edi
  8009f0:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  8009f3:	85 c9                	test   %ecx,%ecx
  8009f5:	74 36                	je     800a2d <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  8009f7:	f7 c7 03 00 00 00    	test   $0x3,%edi
  8009fd:	75 28                	jne    800a27 <memset+0x40>
  8009ff:	f6 c1 03             	test   $0x3,%cl
  800a02:	75 23                	jne    800a27 <memset+0x40>
		c &= 0xFF;
  800a04:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  800a08:	89 d3                	mov    %edx,%ebx
  800a0a:	c1 e3 08             	shl    $0x8,%ebx
  800a0d:	89 d6                	mov    %edx,%esi
  800a0f:	c1 e6 18             	shl    $0x18,%esi
  800a12:	89 d0                	mov    %edx,%eax
  800a14:	c1 e0 10             	shl    $0x10,%eax
  800a17:	09 f0                	or     %esi,%eax
  800a19:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
  800a1b:	89 d8                	mov    %ebx,%eax
  800a1d:	09 d0                	or     %edx,%eax
  800a1f:	c1 e9 02             	shr    $0x2,%ecx
  800a22:	fc                   	cld    
  800a23:	f3 ab                	rep stos %eax,%es:(%edi)
  800a25:	eb 06                	jmp    800a2d <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800a27:	8b 45 0c             	mov    0xc(%ebp),%eax
  800a2a:	fc                   	cld    
  800a2b:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  800a2d:	89 f8                	mov    %edi,%eax
  800a2f:	5b                   	pop    %ebx
  800a30:	5e                   	pop    %esi
  800a31:	5f                   	pop    %edi
  800a32:	5d                   	pop    %ebp
  800a33:	c3                   	ret    

00800a34 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800a34:	55                   	push   %ebp
  800a35:	89 e5                	mov    %esp,%ebp
  800a37:	57                   	push   %edi
  800a38:	56                   	push   %esi
  800a39:	8b 45 08             	mov    0x8(%ebp),%eax
  800a3c:	8b 75 0c             	mov    0xc(%ebp),%esi
  800a3f:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800a42:	39 c6                	cmp    %eax,%esi
  800a44:	73 35                	jae    800a7b <memmove+0x47>
  800a46:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800a49:	39 d0                	cmp    %edx,%eax
  800a4b:	73 2e                	jae    800a7b <memmove+0x47>
		s += n;
		d += n;
  800a4d:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800a50:	89 d6                	mov    %edx,%esi
  800a52:	09 fe                	or     %edi,%esi
  800a54:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800a5a:	75 13                	jne    800a6f <memmove+0x3b>
  800a5c:	f6 c1 03             	test   $0x3,%cl
  800a5f:	75 0e                	jne    800a6f <memmove+0x3b>
			asm volatile("std; rep movsl\n"
  800a61:	83 ef 04             	sub    $0x4,%edi
  800a64:	8d 72 fc             	lea    -0x4(%edx),%esi
  800a67:	c1 e9 02             	shr    $0x2,%ecx
  800a6a:	fd                   	std    
  800a6b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800a6d:	eb 09                	jmp    800a78 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800a6f:	83 ef 01             	sub    $0x1,%edi
  800a72:	8d 72 ff             	lea    -0x1(%edx),%esi
  800a75:	fd                   	std    
  800a76:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800a78:	fc                   	cld    
  800a79:	eb 1d                	jmp    800a98 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800a7b:	89 f2                	mov    %esi,%edx
  800a7d:	09 c2                	or     %eax,%edx
  800a7f:	f6 c2 03             	test   $0x3,%dl
  800a82:	75 0f                	jne    800a93 <memmove+0x5f>
  800a84:	f6 c1 03             	test   $0x3,%cl
  800a87:	75 0a                	jne    800a93 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
  800a89:	c1 e9 02             	shr    $0x2,%ecx
  800a8c:	89 c7                	mov    %eax,%edi
  800a8e:	fc                   	cld    
  800a8f:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800a91:	eb 05                	jmp    800a98 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800a93:	89 c7                	mov    %eax,%edi
  800a95:	fc                   	cld    
  800a96:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800a98:	5e                   	pop    %esi
  800a99:	5f                   	pop    %edi
  800a9a:	5d                   	pop    %ebp
  800a9b:	c3                   	ret    

00800a9c <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  800a9c:	55                   	push   %ebp
  800a9d:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  800a9f:	ff 75 10             	pushl  0x10(%ebp)
  800aa2:	ff 75 0c             	pushl  0xc(%ebp)
  800aa5:	ff 75 08             	pushl  0x8(%ebp)
  800aa8:	e8 87 ff ff ff       	call   800a34 <memmove>
}
  800aad:	c9                   	leave  
  800aae:	c3                   	ret    

00800aaf <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800aaf:	55                   	push   %ebp
  800ab0:	89 e5                	mov    %esp,%ebp
  800ab2:	56                   	push   %esi
  800ab3:	53                   	push   %ebx
  800ab4:	8b 45 08             	mov    0x8(%ebp),%eax
  800ab7:	8b 55 0c             	mov    0xc(%ebp),%edx
  800aba:	89 c6                	mov    %eax,%esi
  800abc:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800abf:	eb 1a                	jmp    800adb <memcmp+0x2c>
		if (*s1 != *s2)
  800ac1:	0f b6 08             	movzbl (%eax),%ecx
  800ac4:	0f b6 1a             	movzbl (%edx),%ebx
  800ac7:	38 d9                	cmp    %bl,%cl
  800ac9:	74 0a                	je     800ad5 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  800acb:	0f b6 c1             	movzbl %cl,%eax
  800ace:	0f b6 db             	movzbl %bl,%ebx
  800ad1:	29 d8                	sub    %ebx,%eax
  800ad3:	eb 0f                	jmp    800ae4 <memcmp+0x35>
		s1++, s2++;
  800ad5:	83 c0 01             	add    $0x1,%eax
  800ad8:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800adb:	39 f0                	cmp    %esi,%eax
  800add:	75 e2                	jne    800ac1 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  800adf:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800ae4:	5b                   	pop    %ebx
  800ae5:	5e                   	pop    %esi
  800ae6:	5d                   	pop    %ebp
  800ae7:	c3                   	ret    

00800ae8 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800ae8:	55                   	push   %ebp
  800ae9:	89 e5                	mov    %esp,%ebp
  800aeb:	53                   	push   %ebx
  800aec:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
  800aef:	89 c1                	mov    %eax,%ecx
  800af1:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
  800af4:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800af8:	eb 0a                	jmp    800b04 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
  800afa:	0f b6 10             	movzbl (%eax),%edx
  800afd:	39 da                	cmp    %ebx,%edx
  800aff:	74 07                	je     800b08 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800b01:	83 c0 01             	add    $0x1,%eax
  800b04:	39 c8                	cmp    %ecx,%eax
  800b06:	72 f2                	jb     800afa <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800b08:	5b                   	pop    %ebx
  800b09:	5d                   	pop    %ebp
  800b0a:	c3                   	ret    

00800b0b <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800b0b:	55                   	push   %ebp
  800b0c:	89 e5                	mov    %esp,%ebp
  800b0e:	57                   	push   %edi
  800b0f:	56                   	push   %esi
  800b10:	53                   	push   %ebx
  800b11:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800b14:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800b17:	eb 03                	jmp    800b1c <strtol+0x11>
		s++;
  800b19:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800b1c:	0f b6 01             	movzbl (%ecx),%eax
  800b1f:	3c 20                	cmp    $0x20,%al
  800b21:	74 f6                	je     800b19 <strtol+0xe>
  800b23:	3c 09                	cmp    $0x9,%al
  800b25:	74 f2                	je     800b19 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800b27:	3c 2b                	cmp    $0x2b,%al
  800b29:	75 0a                	jne    800b35 <strtol+0x2a>
		s++;
  800b2b:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800b2e:	bf 00 00 00 00       	mov    $0x0,%edi
  800b33:	eb 11                	jmp    800b46 <strtol+0x3b>
  800b35:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800b3a:	3c 2d                	cmp    $0x2d,%al
  800b3c:	75 08                	jne    800b46 <strtol+0x3b>
		s++, neg = 1;
  800b3e:	83 c1 01             	add    $0x1,%ecx
  800b41:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800b46:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800b4c:	75 15                	jne    800b63 <strtol+0x58>
  800b4e:	80 39 30             	cmpb   $0x30,(%ecx)
  800b51:	75 10                	jne    800b63 <strtol+0x58>
  800b53:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  800b57:	75 7c                	jne    800bd5 <strtol+0xca>
		s += 2, base = 16;
  800b59:	83 c1 02             	add    $0x2,%ecx
  800b5c:	bb 10 00 00 00       	mov    $0x10,%ebx
  800b61:	eb 16                	jmp    800b79 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  800b63:	85 db                	test   %ebx,%ebx
  800b65:	75 12                	jne    800b79 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800b67:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800b6c:	80 39 30             	cmpb   $0x30,(%ecx)
  800b6f:	75 08                	jne    800b79 <strtol+0x6e>
		s++, base = 8;
  800b71:	83 c1 01             	add    $0x1,%ecx
  800b74:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
  800b79:	b8 00 00 00 00       	mov    $0x0,%eax
  800b7e:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800b81:	0f b6 11             	movzbl (%ecx),%edx
  800b84:	8d 72 d0             	lea    -0x30(%edx),%esi
  800b87:	89 f3                	mov    %esi,%ebx
  800b89:	80 fb 09             	cmp    $0x9,%bl
  800b8c:	77 08                	ja     800b96 <strtol+0x8b>
			dig = *s - '0';
  800b8e:	0f be d2             	movsbl %dl,%edx
  800b91:	83 ea 30             	sub    $0x30,%edx
  800b94:	eb 22                	jmp    800bb8 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
  800b96:	8d 72 9f             	lea    -0x61(%edx),%esi
  800b99:	89 f3                	mov    %esi,%ebx
  800b9b:	80 fb 19             	cmp    $0x19,%bl
  800b9e:	77 08                	ja     800ba8 <strtol+0x9d>
			dig = *s - 'a' + 10;
  800ba0:	0f be d2             	movsbl %dl,%edx
  800ba3:	83 ea 57             	sub    $0x57,%edx
  800ba6:	eb 10                	jmp    800bb8 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
  800ba8:	8d 72 bf             	lea    -0x41(%edx),%esi
  800bab:	89 f3                	mov    %esi,%ebx
  800bad:	80 fb 19             	cmp    $0x19,%bl
  800bb0:	77 16                	ja     800bc8 <strtol+0xbd>
			dig = *s - 'A' + 10;
  800bb2:	0f be d2             	movsbl %dl,%edx
  800bb5:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
  800bb8:	3b 55 10             	cmp    0x10(%ebp),%edx
  800bbb:	7d 0b                	jge    800bc8 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  800bbd:	83 c1 01             	add    $0x1,%ecx
  800bc0:	0f af 45 10          	imul   0x10(%ebp),%eax
  800bc4:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
  800bc6:	eb b9                	jmp    800b81 <strtol+0x76>

	if (endptr)
  800bc8:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800bcc:	74 0d                	je     800bdb <strtol+0xd0>
		*endptr = (char *) s;
  800bce:	8b 75 0c             	mov    0xc(%ebp),%esi
  800bd1:	89 0e                	mov    %ecx,(%esi)
  800bd3:	eb 06                	jmp    800bdb <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800bd5:	85 db                	test   %ebx,%ebx
  800bd7:	74 98                	je     800b71 <strtol+0x66>
  800bd9:	eb 9e                	jmp    800b79 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
  800bdb:	89 c2                	mov    %eax,%edx
  800bdd:	f7 da                	neg    %edx
  800bdf:	85 ff                	test   %edi,%edi
  800be1:	0f 45 c2             	cmovne %edx,%eax
}
  800be4:	5b                   	pop    %ebx
  800be5:	5e                   	pop    %esi
  800be6:	5f                   	pop    %edi
  800be7:	5d                   	pop    %ebp
  800be8:	c3                   	ret    

00800be9 <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  800be9:	55                   	push   %ebp
  800bea:	89 e5                	mov    %esp,%ebp
  800bec:	57                   	push   %edi
  800bed:	56                   	push   %esi
  800bee:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800bef:	b8 00 00 00 00       	mov    $0x0,%eax
  800bf4:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800bf7:	8b 55 08             	mov    0x8(%ebp),%edx
  800bfa:	89 c3                	mov    %eax,%ebx
  800bfc:	89 c7                	mov    %eax,%edi
  800bfe:	89 c6                	mov    %eax,%esi
  800c00:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  800c02:	5b                   	pop    %ebx
  800c03:	5e                   	pop    %esi
  800c04:	5f                   	pop    %edi
  800c05:	5d                   	pop    %ebp
  800c06:	c3                   	ret    

00800c07 <sys_cgetc>:

int
sys_cgetc(void)
{
  800c07:	55                   	push   %ebp
  800c08:	89 e5                	mov    %esp,%ebp
  800c0a:	57                   	push   %edi
  800c0b:	56                   	push   %esi
  800c0c:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800c0d:	ba 00 00 00 00       	mov    $0x0,%edx
  800c12:	b8 01 00 00 00       	mov    $0x1,%eax
  800c17:	89 d1                	mov    %edx,%ecx
  800c19:	89 d3                	mov    %edx,%ebx
  800c1b:	89 d7                	mov    %edx,%edi
  800c1d:	89 d6                	mov    %edx,%esi
  800c1f:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  800c21:	5b                   	pop    %ebx
  800c22:	5e                   	pop    %esi
  800c23:	5f                   	pop    %edi
  800c24:	5d                   	pop    %ebp
  800c25:	c3                   	ret    

00800c26 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800c26:	55                   	push   %ebp
  800c27:	89 e5                	mov    %esp,%ebp
  800c29:	57                   	push   %edi
  800c2a:	56                   	push   %esi
  800c2b:	53                   	push   %ebx
  800c2c:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800c2f:	b9 00 00 00 00       	mov    $0x0,%ecx
  800c34:	b8 03 00 00 00       	mov    $0x3,%eax
  800c39:	8b 55 08             	mov    0x8(%ebp),%edx
  800c3c:	89 cb                	mov    %ecx,%ebx
  800c3e:	89 cf                	mov    %ecx,%edi
  800c40:	89 ce                	mov    %ecx,%esi
  800c42:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800c44:	85 c0                	test   %eax,%eax
  800c46:	7e 17                	jle    800c5f <sys_env_destroy+0x39>
		panic("syscall %d returned %d (> 0)", num, ret);
  800c48:	83 ec 0c             	sub    $0xc,%esp
  800c4b:	50                   	push   %eax
  800c4c:	6a 03                	push   $0x3
  800c4e:	68 28 19 80 00       	push   $0x801928
  800c53:	6a 23                	push   $0x23
  800c55:	68 45 19 80 00       	push   $0x801945
  800c5a:	e8 25 06 00 00       	call   801284 <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800c5f:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800c62:	5b                   	pop    %ebx
  800c63:	5e                   	pop    %esi
  800c64:	5f                   	pop    %edi
  800c65:	5d                   	pop    %ebp
  800c66:	c3                   	ret    

00800c67 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800c67:	55                   	push   %ebp
  800c68:	89 e5                	mov    %esp,%ebp
  800c6a:	57                   	push   %edi
  800c6b:	56                   	push   %esi
  800c6c:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800c6d:	ba 00 00 00 00       	mov    $0x0,%edx
  800c72:	b8 02 00 00 00       	mov    $0x2,%eax
  800c77:	89 d1                	mov    %edx,%ecx
  800c79:	89 d3                	mov    %edx,%ebx
  800c7b:	89 d7                	mov    %edx,%edi
  800c7d:	89 d6                	mov    %edx,%esi
  800c7f:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800c81:	5b                   	pop    %ebx
  800c82:	5e                   	pop    %esi
  800c83:	5f                   	pop    %edi
  800c84:	5d                   	pop    %ebp
  800c85:	c3                   	ret    

00800c86 <sys_yield>:

void
sys_yield(void)
{
  800c86:	55                   	push   %ebp
  800c87:	89 e5                	mov    %esp,%ebp
  800c89:	57                   	push   %edi
  800c8a:	56                   	push   %esi
  800c8b:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800c8c:	ba 00 00 00 00       	mov    $0x0,%edx
  800c91:	b8 0a 00 00 00       	mov    $0xa,%eax
  800c96:	89 d1                	mov    %edx,%ecx
  800c98:	89 d3                	mov    %edx,%ebx
  800c9a:	89 d7                	mov    %edx,%edi
  800c9c:	89 d6                	mov    %edx,%esi
  800c9e:	cd 30                	int    $0x30

void
sys_yield(void)
{
	syscall(SYS_yield, 0, 0, 0, 0, 0, 0);
}
  800ca0:	5b                   	pop    %ebx
  800ca1:	5e                   	pop    %esi
  800ca2:	5f                   	pop    %edi
  800ca3:	5d                   	pop    %ebp
  800ca4:	c3                   	ret    

00800ca5 <sys_page_alloc>:

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
  800ca5:	55                   	push   %ebp
  800ca6:	89 e5                	mov    %esp,%ebp
  800ca8:	57                   	push   %edi
  800ca9:	56                   	push   %esi
  800caa:	53                   	push   %ebx
  800cab:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800cae:	be 00 00 00 00       	mov    $0x0,%esi
  800cb3:	b8 04 00 00 00       	mov    $0x4,%eax
  800cb8:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800cbb:	8b 55 08             	mov    0x8(%ebp),%edx
  800cbe:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800cc1:	89 f7                	mov    %esi,%edi
  800cc3:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800cc5:	85 c0                	test   %eax,%eax
  800cc7:	7e 17                	jle    800ce0 <sys_page_alloc+0x3b>
		panic("syscall %d returned %d (> 0)", num, ret);
  800cc9:	83 ec 0c             	sub    $0xc,%esp
  800ccc:	50                   	push   %eax
  800ccd:	6a 04                	push   $0x4
  800ccf:	68 28 19 80 00       	push   $0x801928
  800cd4:	6a 23                	push   $0x23
  800cd6:	68 45 19 80 00       	push   $0x801945
  800cdb:	e8 a4 05 00 00       	call   801284 <_panic>

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
	return syscall(SYS_page_alloc, 1, envid, (uint32_t) va, perm, 0, 0);
}
  800ce0:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800ce3:	5b                   	pop    %ebx
  800ce4:	5e                   	pop    %esi
  800ce5:	5f                   	pop    %edi
  800ce6:	5d                   	pop    %ebp
  800ce7:	c3                   	ret    

00800ce8 <sys_page_map>:

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
  800ce8:	55                   	push   %ebp
  800ce9:	89 e5                	mov    %esp,%ebp
  800ceb:	57                   	push   %edi
  800cec:	56                   	push   %esi
  800ced:	53                   	push   %ebx
  800cee:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800cf1:	b8 05 00 00 00       	mov    $0x5,%eax
  800cf6:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800cf9:	8b 55 08             	mov    0x8(%ebp),%edx
  800cfc:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800cff:	8b 7d 14             	mov    0x14(%ebp),%edi
  800d02:	8b 75 18             	mov    0x18(%ebp),%esi
  800d05:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800d07:	85 c0                	test   %eax,%eax
  800d09:	7e 17                	jle    800d22 <sys_page_map+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800d0b:	83 ec 0c             	sub    $0xc,%esp
  800d0e:	50                   	push   %eax
  800d0f:	6a 05                	push   $0x5
  800d11:	68 28 19 80 00       	push   $0x801928
  800d16:	6a 23                	push   $0x23
  800d18:	68 45 19 80 00       	push   $0x801945
  800d1d:	e8 62 05 00 00       	call   801284 <_panic>

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
	return syscall(SYS_page_map, 1, srcenv, (uint32_t) srcva, dstenv, (uint32_t) dstva, perm);
}
  800d22:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800d25:	5b                   	pop    %ebx
  800d26:	5e                   	pop    %esi
  800d27:	5f                   	pop    %edi
  800d28:	5d                   	pop    %ebp
  800d29:	c3                   	ret    

00800d2a <sys_page_unmap>:

int
sys_page_unmap(envid_t envid, void *va)
{
  800d2a:	55                   	push   %ebp
  800d2b:	89 e5                	mov    %esp,%ebp
  800d2d:	57                   	push   %edi
  800d2e:	56                   	push   %esi
  800d2f:	53                   	push   %ebx
  800d30:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800d33:	bb 00 00 00 00       	mov    $0x0,%ebx
  800d38:	b8 06 00 00 00       	mov    $0x6,%eax
  800d3d:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800d40:	8b 55 08             	mov    0x8(%ebp),%edx
  800d43:	89 df                	mov    %ebx,%edi
  800d45:	89 de                	mov    %ebx,%esi
  800d47:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800d49:	85 c0                	test   %eax,%eax
  800d4b:	7e 17                	jle    800d64 <sys_page_unmap+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800d4d:	83 ec 0c             	sub    $0xc,%esp
  800d50:	50                   	push   %eax
  800d51:	6a 06                	push   $0x6
  800d53:	68 28 19 80 00       	push   $0x801928
  800d58:	6a 23                	push   $0x23
  800d5a:	68 45 19 80 00       	push   $0x801945
  800d5f:	e8 20 05 00 00       	call   801284 <_panic>

int
sys_page_unmap(envid_t envid, void *va)
{
	return syscall(SYS_page_unmap, 1, envid, (uint32_t) va, 0, 0, 0);
}
  800d64:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800d67:	5b                   	pop    %ebx
  800d68:	5e                   	pop    %esi
  800d69:	5f                   	pop    %edi
  800d6a:	5d                   	pop    %ebp
  800d6b:	c3                   	ret    

00800d6c <sys_env_set_status>:

// sys_exofork is inlined in lib.h

int
sys_env_set_status(envid_t envid, int status)
{
  800d6c:	55                   	push   %ebp
  800d6d:	89 e5                	mov    %esp,%ebp
  800d6f:	57                   	push   %edi
  800d70:	56                   	push   %esi
  800d71:	53                   	push   %ebx
  800d72:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800d75:	bb 00 00 00 00       	mov    $0x0,%ebx
  800d7a:	b8 08 00 00 00       	mov    $0x8,%eax
  800d7f:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800d82:	8b 55 08             	mov    0x8(%ebp),%edx
  800d85:	89 df                	mov    %ebx,%edi
  800d87:	89 de                	mov    %ebx,%esi
  800d89:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800d8b:	85 c0                	test   %eax,%eax
  800d8d:	7e 17                	jle    800da6 <sys_env_set_status+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800d8f:	83 ec 0c             	sub    $0xc,%esp
  800d92:	50                   	push   %eax
  800d93:	6a 08                	push   $0x8
  800d95:	68 28 19 80 00       	push   $0x801928
  800d9a:	6a 23                	push   $0x23
  800d9c:	68 45 19 80 00       	push   $0x801945
  800da1:	e8 de 04 00 00       	call   801284 <_panic>

int
sys_env_set_status(envid_t envid, int status)
{
	return syscall(SYS_env_set_status, 1, envid, status, 0, 0, 0);
}
  800da6:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800da9:	5b                   	pop    %ebx
  800daa:	5e                   	pop    %esi
  800dab:	5f                   	pop    %edi
  800dac:	5d                   	pop    %ebp
  800dad:	c3                   	ret    

00800dae <sys_env_set_pgfault_upcall>:

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
  800dae:	55                   	push   %ebp
  800daf:	89 e5                	mov    %esp,%ebp
  800db1:	57                   	push   %edi
  800db2:	56                   	push   %esi
  800db3:	53                   	push   %ebx
  800db4:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800db7:	bb 00 00 00 00       	mov    $0x0,%ebx
  800dbc:	b8 09 00 00 00       	mov    $0x9,%eax
  800dc1:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800dc4:	8b 55 08             	mov    0x8(%ebp),%edx
  800dc7:	89 df                	mov    %ebx,%edi
  800dc9:	89 de                	mov    %ebx,%esi
  800dcb:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800dcd:	85 c0                	test   %eax,%eax
  800dcf:	7e 17                	jle    800de8 <sys_env_set_pgfault_upcall+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800dd1:	83 ec 0c             	sub    $0xc,%esp
  800dd4:	50                   	push   %eax
  800dd5:	6a 09                	push   $0x9
  800dd7:	68 28 19 80 00       	push   $0x801928
  800ddc:	6a 23                	push   $0x23
  800dde:	68 45 19 80 00       	push   $0x801945
  800de3:	e8 9c 04 00 00       	call   801284 <_panic>

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
	return syscall(SYS_env_set_pgfault_upcall, 1, envid, (uint32_t) upcall, 0, 0, 0);
}
  800de8:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800deb:	5b                   	pop    %ebx
  800dec:	5e                   	pop    %esi
  800ded:	5f                   	pop    %edi
  800dee:	5d                   	pop    %ebp
  800def:	c3                   	ret    

00800df0 <sys_ipc_try_send>:

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
  800df0:	55                   	push   %ebp
  800df1:	89 e5                	mov    %esp,%ebp
  800df3:	57                   	push   %edi
  800df4:	56                   	push   %esi
  800df5:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800df6:	be 00 00 00 00       	mov    $0x0,%esi
  800dfb:	b8 0b 00 00 00       	mov    $0xb,%eax
  800e00:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800e03:	8b 55 08             	mov    0x8(%ebp),%edx
  800e06:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800e09:	8b 7d 14             	mov    0x14(%ebp),%edi
  800e0c:	cd 30                	int    $0x30

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
	return syscall(SYS_ipc_try_send, 0, envid, value, (uint32_t) srcva, perm, 0);
}
  800e0e:	5b                   	pop    %ebx
  800e0f:	5e                   	pop    %esi
  800e10:	5f                   	pop    %edi
  800e11:	5d                   	pop    %ebp
  800e12:	c3                   	ret    

00800e13 <sys_ipc_recv>:

int
sys_ipc_recv(void *dstva)
{
  800e13:	55                   	push   %ebp
  800e14:	89 e5                	mov    %esp,%ebp
  800e16:	57                   	push   %edi
  800e17:	56                   	push   %esi
  800e18:	53                   	push   %ebx
  800e19:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800e1c:	b9 00 00 00 00       	mov    $0x0,%ecx
  800e21:	b8 0c 00 00 00       	mov    $0xc,%eax
  800e26:	8b 55 08             	mov    0x8(%ebp),%edx
  800e29:	89 cb                	mov    %ecx,%ebx
  800e2b:	89 cf                	mov    %ecx,%edi
  800e2d:	89 ce                	mov    %ecx,%esi
  800e2f:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800e31:	85 c0                	test   %eax,%eax
  800e33:	7e 17                	jle    800e4c <sys_ipc_recv+0x39>
		panic("syscall %d returned %d (> 0)", num, ret);
  800e35:	83 ec 0c             	sub    $0xc,%esp
  800e38:	50                   	push   %eax
  800e39:	6a 0c                	push   $0xc
  800e3b:	68 28 19 80 00       	push   $0x801928
  800e40:	6a 23                	push   $0x23
  800e42:	68 45 19 80 00       	push   $0x801945
  800e47:	e8 38 04 00 00       	call   801284 <_panic>

int
sys_ipc_recv(void *dstva)
{
	return syscall(SYS_ipc_recv, 1, (uint32_t)dstva, 0, 0, 0, 0);
}
  800e4c:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800e4f:	5b                   	pop    %ebx
  800e50:	5e                   	pop    %esi
  800e51:	5f                   	pop    %edi
  800e52:	5d                   	pop    %ebp
  800e53:	c3                   	ret    

00800e54 <pgfault>:
// Custom page fault handler - if faulting page is copy-on-write,
// map in our own private writable copy.
//
static void
pgfault(struct UTrapframe *utf)
{
  800e54:	55                   	push   %ebp
  800e55:	89 e5                	mov    %esp,%ebp
  800e57:	56                   	push   %esi
  800e58:	53                   	push   %ebx
  800e59:	8b 75 08             	mov    0x8(%ebp),%esi


	void *addr = (void *) utf->utf_fault_va;
  800e5c:	8b 1e                	mov    (%esi),%ebx
	// Hint:
	//   Use the read-only page table mappings at uvpt
	//   (see <inc/memlayout.h>).

	// LAB 4: Your code here.
	if( (err & FEC_WR) == 0){
  800e5e:	f6 46 04 02          	testb  $0x2,0x4(%esi)
  800e62:	75 32                	jne    800e96 <pgfault+0x42>
		//cprintf(	" The eid = %x\n", sys_getenvid());
		//cprintf("The err is %d\n", err);
		cprintf("The va is 0x%x\n", (int)addr );
  800e64:	83 ec 08             	sub    $0x8,%esp
  800e67:	53                   	push   %ebx
  800e68:	68 53 19 80 00       	push   $0x801953
  800e6d:	e8 2c f4 ff ff       	call   80029e <cprintf>
		cprintf("The Eip is 0x%x\n", utf->utf_eip);
  800e72:	83 c4 08             	add    $0x8,%esp
  800e75:	ff 76 28             	pushl  0x28(%esi)
  800e78:	68 63 19 80 00       	push   $0x801963
  800e7d:	e8 1c f4 ff ff       	call   80029e <cprintf>

		 panic("The err is not right of the pgfault\n ");
  800e82:	83 c4 0c             	add    $0xc,%esp
  800e85:	68 a8 19 80 00       	push   $0x8019a8
  800e8a:	6a 24                	push   $0x24
  800e8c:	68 74 19 80 00       	push   $0x801974
  800e91:	e8 ee 03 00 00       	call   801284 <_panic>
	}

	pte_t PTE =uvpt[PGNUM(addr)];
  800e96:	89 d8                	mov    %ebx,%eax
  800e98:	c1 e8 0c             	shr    $0xc,%eax
  800e9b:	8b 04 85 00 00 40 ef 	mov    -0x10c00000(,%eax,4),%eax

	if( (PTE & PTE_COW) == 0)
  800ea2:	f6 c4 08             	test   $0x8,%ah
  800ea5:	75 14                	jne    800ebb <pgfault+0x67>
		panic("The pgfault perm is not right\n");
  800ea7:	83 ec 04             	sub    $0x4,%esp
  800eaa:	68 d0 19 80 00       	push   $0x8019d0
  800eaf:	6a 2a                	push   $0x2a
  800eb1:	68 74 19 80 00       	push   $0x801974
  800eb6:	e8 c9 03 00 00       	call   801284 <_panic>
	// page to the old page's address.
	// Hint:
	//   You should make three system calls.

	// LAB 4: Your code here.
	if(sys_page_alloc(sys_getenvid(), (void*)PFTEMP, PTE_U|PTE_W|PTE_P) <0 )
  800ebb:	e8 a7 fd ff ff       	call   800c67 <sys_getenvid>
  800ec0:	83 ec 04             	sub    $0x4,%esp
  800ec3:	6a 07                	push   $0x7
  800ec5:	68 00 f0 7f 00       	push   $0x7ff000
  800eca:	50                   	push   %eax
  800ecb:	e8 d5 fd ff ff       	call   800ca5 <sys_page_alloc>
  800ed0:	83 c4 10             	add    $0x10,%esp
  800ed3:	85 c0                	test   %eax,%eax
  800ed5:	79 14                	jns    800eeb <pgfault+0x97>
		panic("pgfault sys_page_alloc is not right\n");
  800ed7:	83 ec 04             	sub    $0x4,%esp
  800eda:	68 f0 19 80 00       	push   $0x8019f0
  800edf:	6a 34                	push   $0x34
  800ee1:	68 74 19 80 00       	push   $0x801974
  800ee6:	e8 99 03 00 00       	call   801284 <_panic>
	addr = ROUNDDOWN(addr, PGSIZE);
  800eeb:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	memcpy((void*)PFTEMP, addr, PGSIZE);
  800ef1:	83 ec 04             	sub    $0x4,%esp
  800ef4:	68 00 10 00 00       	push   $0x1000
  800ef9:	53                   	push   %ebx
  800efa:	68 00 f0 7f 00       	push   $0x7ff000
  800eff:	e8 98 fb ff ff       	call   800a9c <memcpy>

	if((r = sys_page_map(sys_getenvid(), (void*)PFTEMP, sys_getenvid(), addr, PTE_U|PTE_W|PTE_P)) < 0)
  800f04:	e8 5e fd ff ff       	call   800c67 <sys_getenvid>
  800f09:	89 c6                	mov    %eax,%esi
  800f0b:	e8 57 fd ff ff       	call   800c67 <sys_getenvid>
  800f10:	c7 04 24 07 00 00 00 	movl   $0x7,(%esp)
  800f17:	53                   	push   %ebx
  800f18:	56                   	push   %esi
  800f19:	68 00 f0 7f 00       	push   $0x7ff000
  800f1e:	50                   	push   %eax
  800f1f:	e8 c4 fd ff ff       	call   800ce8 <sys_page_map>
  800f24:	83 c4 20             	add    $0x20,%esp
  800f27:	85 c0                	test   %eax,%eax
  800f29:	79 12                	jns    800f3d <pgfault+0xe9>
		panic("The sys_page_map is not right, the errno is %d\n", r);
  800f2b:	50                   	push   %eax
  800f2c:	68 18 1a 80 00       	push   $0x801a18
  800f31:	6a 39                	push   $0x39
  800f33:	68 74 19 80 00       	push   $0x801974
  800f38:	e8 47 03 00 00       	call   801284 <_panic>
	if( (r = sys_page_unmap(sys_getenvid(), (void*)PFTEMP)) <0 )
  800f3d:	e8 25 fd ff ff       	call   800c67 <sys_getenvid>
  800f42:	83 ec 08             	sub    $0x8,%esp
  800f45:	68 00 f0 7f 00       	push   $0x7ff000
  800f4a:	50                   	push   %eax
  800f4b:	e8 da fd ff ff       	call   800d2a <sys_page_unmap>
  800f50:	83 c4 10             	add    $0x10,%esp
  800f53:	85 c0                	test   %eax,%eax
  800f55:	79 12                	jns    800f69 <pgfault+0x115>
		panic("The sys_page_unmap is not right, the errno is %d\n",r);
  800f57:	50                   	push   %eax
  800f58:	68 48 1a 80 00       	push   $0x801a48
  800f5d:	6a 3b                	push   $0x3b
  800f5f:	68 74 19 80 00       	push   $0x801974
  800f64:	e8 1b 03 00 00       	call   801284 <_panic>
	return;

	

	//panic("pgfault not implemented");
}
  800f69:	8d 65 f8             	lea    -0x8(%ebp),%esp
  800f6c:	5b                   	pop    %ebx
  800f6d:	5e                   	pop    %esi
  800f6e:	5d                   	pop    %ebp
  800f6f:	c3                   	ret    

00800f70 <fork>:
//   Neither user exception stack should ever be marked copy-on-write,
//   so you must allocate a new page for the child's user exception stack.
//
envid_t
fork(void)
{
  800f70:	55                   	push   %ebp
  800f71:	89 e5                	mov    %esp,%ebp
  800f73:	57                   	push   %edi
  800f74:	56                   	push   %esi
  800f75:	53                   	push   %ebx
  800f76:	83 ec 28             	sub    $0x28,%esp
	// LAB 4: Your code here.
	
	extern void*  _pgfault_upcall();
	//build the experition stack for the parent env
	set_pgfault_handler(pgfault);
  800f79:	68 54 0e 80 00       	push   $0x800e54
  800f7e:	e8 47 03 00 00       	call   8012ca <set_pgfault_handler>
// This must be inlined.  Exercise for reader: why?
static __inline envid_t __attribute__((always_inline))
sys_exofork(void)
{
	envid_t ret;
	__asm __volatile("int %2"
  800f83:	b8 07 00 00 00       	mov    $0x7,%eax
  800f88:	cd 30                	int    $0x30
  800f8a:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800f8d:	89 45 e4             	mov    %eax,-0x1c(%ebp)

	int childEid = sys_exofork();
	if(childEid < 0)
  800f90:	83 c4 10             	add    $0x10,%esp
  800f93:	85 c0                	test   %eax,%eax
  800f95:	79 15                	jns    800fac <fork+0x3c>
		panic("sys_exofork() is not right, and the errno is  %d\n",childEid);
  800f97:	50                   	push   %eax
  800f98:	68 7c 1a 80 00       	push   $0x801a7c
  800f9d:	68 82 00 00 00       	push   $0x82
  800fa2:	68 74 19 80 00       	push   $0x801974
  800fa7:	e8 d8 02 00 00       	call   801284 <_panic>
	if(childEid == 0){
  800fac:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800fb0:	75 1c                	jne    800fce <fork+0x5e>
		thisenv = &envs[ENVX(sys_getenvid())];
  800fb2:	e8 b0 fc ff ff       	call   800c67 <sys_getenvid>
  800fb7:	25 ff 03 00 00       	and    $0x3ff,%eax
  800fbc:	6b c0 7c             	imul   $0x7c,%eax,%eax
  800fbf:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  800fc4:	a3 0c 20 80 00       	mov    %eax,0x80200c
		return childEid;
  800fc9:	e9 41 01 00 00       	jmp    80110f <fork+0x19f>
	}

	int r = sys_env_set_pgfault_upcall(childEid,  _pgfault_upcall);
  800fce:	83 ec 08             	sub    $0x8,%esp
  800fd1:	68 40 13 80 00       	push   $0x801340
  800fd6:	ff 75 e0             	pushl  -0x20(%ebp)
  800fd9:	e8 d0 fd ff ff       	call   800dae <sys_env_set_pgfault_upcall>
  800fde:	89 c7                	mov    %eax,%edi
	if(r < 0)
  800fe0:	83 c4 10             	add    $0x10,%esp
  800fe3:	85 c0                	test   %eax,%eax
  800fe5:	79 15                	jns    800ffc <fork+0x8c>
		panic("sys_env_set_pgfault_upcall is not right ,and the errno is %d\n", r);
  800fe7:	50                   	push   %eax
  800fe8:	68 b0 1a 80 00       	push   $0x801ab0
  800fed:	68 8a 00 00 00       	push   $0x8a
  800ff2:	68 74 19 80 00       	push   $0x801974
  800ff7:	e8 88 02 00 00       	call   801284 <_panic>
  800ffc:	bb 00 00 00 00       	mov    $0x0,%ebx
	

	int pn =0;
	for(pn=0; pn*PGSIZE < UTOP ; pn++){
		if ( ( 	(uvpd[PDX(pn*PGSIZE)] & PTE_P) != 0) &&
  801001:	89 d8                	mov    %ebx,%eax
  801003:	c1 e8 16             	shr    $0x16,%eax
  801006:	8b 04 85 00 d0 7b ef 	mov    -0x10843000(,%eax,4),%eax
  80100d:	a8 01                	test   $0x1,%al
  80100f:	0f 84 bd 00 00 00    	je     8010d2 <fork+0x162>
				( (uvpt[PGNUM(pn*PGSIZE)] & PTE_U) != 0) &&
  801015:	89 d8                	mov    %ebx,%eax
  801017:	c1 e8 0c             	shr    $0xc,%eax
  80101a:	8b 14 85 00 00 40 ef 	mov    -0x10c00000(,%eax,4),%edx
		panic("sys_env_set_pgfault_upcall is not right ,and the errno is %d\n", r);
	

	int pn =0;
	for(pn=0; pn*PGSIZE < UTOP ; pn++){
		if ( ( 	(uvpd[PDX(pn*PGSIZE)] & PTE_P) != 0) &&
  801021:	f6 c2 04             	test   $0x4,%dl
  801024:	0f 84 a8 00 00 00    	je     8010d2 <fork+0x162>
				( (uvpt[PGNUM(pn*PGSIZE)] & PTE_U) != 0) &&
				( (uvpt[PGNUM(pn*PGSIZE)] & PTE_P) != 0))
  80102a:	8b 14 85 00 00 40 ef 	mov    -0x10c00000(,%eax,4),%edx
	

	int pn =0;
	for(pn=0; pn*PGSIZE < UTOP ; pn++){
		if ( ( 	(uvpd[PDX(pn*PGSIZE)] & PTE_P) != 0) &&
				( (uvpt[PGNUM(pn*PGSIZE)] & PTE_U) != 0) &&
  801031:	f6 c2 01             	test   $0x1,%dl
  801034:	0f 84 98 00 00 00    	je     8010d2 <fork+0x162>
				( (uvpt[PGNUM(pn*PGSIZE)] & PTE_P) != 0))
		{
		//build experition stack for the child env
			if(pn*PGSIZE == UXSTACKTOP -PGSIZE)
  80103a:	81 fb 00 f0 bf ee    	cmp    $0xeebff000,%ebx
  801040:	75 17                	jne    801059 <fork+0xe9>
				sys_page_alloc(childEid, (void*) (pn*PGSIZE), PTE_U| PTE_W | PTE_P);
  801042:	83 ec 04             	sub    $0x4,%esp
  801045:	6a 07                	push   $0x7
  801047:	68 00 f0 bf ee       	push   $0xeebff000
  80104c:	ff 75 e4             	pushl  -0x1c(%ebp)
  80104f:	e8 51 fc ff ff       	call   800ca5 <sys_page_alloc>
  801054:	83 c4 10             	add    $0x10,%esp
  801057:	eb 60                	jmp    8010b9 <fork+0x149>
duppage(envid_t envid, unsigned pn)
{
	int r;
	

	pte_t  PTE= uvpt[PGNUM(pn*PGSIZE)];
  801059:	8b 04 85 00 00 40 ef 	mov    -0x10c00000(,%eax,4),%eax
	int perm = PTE_U|PTE_P;
	if((PTE & PTE_W) || (PTE & PTE_COW))
  801060:	25 02 08 00 00       	and    $0x802,%eax
		perm |= PTE_COW;
  801065:	83 f8 01             	cmp    $0x1,%eax
  801068:	19 f6                	sbb    %esi,%esi
  80106a:	81 e6 00 f8 ff ff    	and    $0xfffff800,%esi
  801070:	81 c6 05 08 00 00    	add    $0x805,%esi
	
	if( (	r =sys_page_map(sys_getenvid(), (void*)(pn*PGSIZE), envid, (void*)(pn*PGSIZE), perm)) 
  801076:	e8 ec fb ff ff       	call   800c67 <sys_getenvid>
  80107b:	83 ec 0c             	sub    $0xc,%esp
  80107e:	56                   	push   %esi
  80107f:	53                   	push   %ebx
  801080:	ff 75 e4             	pushl  -0x1c(%ebp)
  801083:	53                   	push   %ebx
  801084:	50                   	push   %eax
  801085:	e8 5e fc ff ff       	call   800ce8 <sys_page_map>
  80108a:	89 c7                	mov    %eax,%edi
  80108c:	83 c4 20             	add    $0x20,%esp
  80108f:	85 c0                	test   %eax,%eax
  801091:	78 2a                	js     8010bd <fork+0x14d>
						<0)  
		return r;

	if( (	r =sys_page_map(sys_getenvid(), (void*)(pn*PGSIZE), sys_getenvid(), (void*)(pn*PGSIZE), perm)) 
  801093:	e8 cf fb ff ff       	call   800c67 <sys_getenvid>
  801098:	89 c7                	mov    %eax,%edi
  80109a:	e8 c8 fb ff ff       	call   800c67 <sys_getenvid>
  80109f:	83 ec 0c             	sub    $0xc,%esp
  8010a2:	56                   	push   %esi
  8010a3:	53                   	push   %ebx
  8010a4:	57                   	push   %edi
  8010a5:	53                   	push   %ebx
  8010a6:	50                   	push   %eax
  8010a7:	e8 3c fc ff ff       	call   800ce8 <sys_page_map>
  8010ac:	83 c4 20             	add    $0x20,%esp
  8010af:	85 c0                	test   %eax,%eax
  8010b1:	bf 00 00 00 00       	mov    $0x0,%edi
  8010b6:	0f 4e f8             	cmovle %eax,%edi
		//build experition stack for the child env
			if(pn*PGSIZE == UXSTACKTOP -PGSIZE)
				sys_page_alloc(childEid, (void*) (pn*PGSIZE), PTE_U| PTE_W | PTE_P);
			else
				r = duppage(childEid, pn);
			if(r <0)
  8010b9:	85 ff                	test   %edi,%edi
  8010bb:	79 15                	jns    8010d2 <fork+0x162>
				panic("fork() is wrong, and the errno is %d\n", r) ;
  8010bd:	57                   	push   %edi
  8010be:	68 f0 1a 80 00       	push   $0x801af0
  8010c3:	68 99 00 00 00       	push   $0x99
  8010c8:	68 74 19 80 00       	push   $0x801974
  8010cd:	e8 b2 01 00 00       	call   801284 <_panic>
  8010d2:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	if(r < 0)
		panic("sys_env_set_pgfault_upcall is not right ,and the errno is %d\n", r);
	

	int pn =0;
	for(pn=0; pn*PGSIZE < UTOP ; pn++){
  8010d8:	81 fb 00 00 c0 ee    	cmp    $0xeec00000,%ebx
  8010de:	0f 85 1d ff ff ff    	jne    801001 <fork+0x91>
				r = duppage(childEid, pn);
			if(r <0)
				panic("fork() is wrong, and the errno is %d\n", r) ;
		}
	}
	if (sys_env_set_status(childEid, ENV_RUNNABLE) < 0)
  8010e4:	83 ec 08             	sub    $0x8,%esp
  8010e7:	6a 02                	push   $0x2
  8010e9:	ff 75 e0             	pushl  -0x20(%ebp)
  8010ec:	e8 7b fc ff ff       	call   800d6c <sys_env_set_status>
  8010f1:	83 c4 10             	add    $0x10,%esp
  8010f4:	85 c0                	test   %eax,%eax
  8010f6:	79 17                	jns    80110f <fork+0x19f>
		panic("sys_env_set_status");
  8010f8:	83 ec 04             	sub    $0x4,%esp
  8010fb:	68 7f 19 80 00       	push   $0x80197f
  801100:	68 9d 00 00 00       	push   $0x9d
  801105:	68 74 19 80 00       	push   $0x801974
  80110a:	e8 75 01 00 00       	call   801284 <_panic>
	return childEid;
}
  80110f:	8b 45 e0             	mov    -0x20(%ebp),%eax
  801112:	8d 65 f4             	lea    -0xc(%ebp),%esp
  801115:	5b                   	pop    %ebx
  801116:	5e                   	pop    %esi
  801117:	5f                   	pop    %edi
  801118:	5d                   	pop    %ebp
  801119:	c3                   	ret    

0080111a <sfork>:

// Challenge!
int
sfork(void)
{
  80111a:	55                   	push   %ebp
  80111b:	89 e5                	mov    %esp,%ebp
  80111d:	83 ec 0c             	sub    $0xc,%esp
	panic("sfork not implemented");
  801120:	68 92 19 80 00       	push   $0x801992
  801125:	68 a5 00 00 00       	push   $0xa5
  80112a:	68 74 19 80 00       	push   $0x801974
  80112f:	e8 50 01 00 00       	call   801284 <_panic>

00801134 <ipc_recv>:
//   If 'pg' is null, pass sys_ipc_recv a value that it will understand
//   as meaning "no page".  (Zero is not the right value, since that's
//   a perfectly valid place to map a page.)
int32_t
ipc_recv(envid_t *from_env_store, void *pg, int *perm_store)
{
  801134:	55                   	push   %ebp
  801135:	89 e5                	mov    %esp,%ebp
  801137:	56                   	push   %esi
  801138:	53                   	push   %ebx
  801139:	8b 75 08             	mov    0x8(%ebp),%esi
  80113c:	8b 45 0c             	mov    0xc(%ebp),%eax
  80113f:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// LAB 4: Your code here.
	int r =0;
	int a;
	if(pg == 0)
  801142:	85 c0                	test   %eax,%eax
  801144:	75 12                	jne    801158 <ipc_recv+0x24>
		r= sys_ipc_recv( (void *)UTOP);
  801146:	83 ec 0c             	sub    $0xc,%esp
  801149:	68 00 00 c0 ee       	push   $0xeec00000
  80114e:	e8 c0 fc ff ff       	call   800e13 <sys_ipc_recv>
  801153:	83 c4 10             	add    $0x10,%esp
  801156:	eb 0c                	jmp    801164 <ipc_recv+0x30>
	else
		r = sys_ipc_recv(pg);
  801158:	83 ec 0c             	sub    $0xc,%esp
  80115b:	50                   	push   %eax
  80115c:	e8 b2 fc ff ff       	call   800e13 <sys_ipc_recv>
  801161:	83 c4 10             	add    $0x10,%esp
	if(r == 0){
  801164:	85 c0                	test   %eax,%eax
  801166:	75 1e                	jne    801186 <ipc_recv+0x52>
		if( from_env_store != 0 )
  801168:	85 f6                	test   %esi,%esi
  80116a:	74 0a                	je     801176 <ipc_recv+0x42>
			*from_env_store = thisenv->env_ipc_from;
  80116c:	a1 0c 20 80 00       	mov    0x80200c,%eax
  801171:	8b 40 74             	mov    0x74(%eax),%eax
  801174:	89 06                	mov    %eax,(%esi)

		if(perm_store != 0 )
  801176:	85 db                	test   %ebx,%ebx
  801178:	74 1e                	je     801198 <ipc_recv+0x64>
			*perm_store = thisenv->env_ipc_perm;
  80117a:	a1 0c 20 80 00       	mov    0x80200c,%eax
  80117f:	8b 40 78             	mov    0x78(%eax),%eax
  801182:	89 03                	mov    %eax,(%ebx)
  801184:	eb 12                	jmp    801198 <ipc_recv+0x64>
	}
	else{
		panic("The ipc_recv is not right, and the errno is %d\n",r);
  801186:	50                   	push   %eax
  801187:	68 18 1b 80 00       	push   $0x801b18
  80118c:	6a 28                	push   $0x28
  80118e:	68 94 1b 80 00       	push   $0x801b94
  801193:	e8 ec 00 00 00       	call   801284 <_panic>

		if(perm_store != 0 )
			*perm_store = 0;
		return r;
	}
	if(thisenv->env_ipc_value == 0)
  801198:	a1 0c 20 80 00       	mov    0x80200c,%eax
  80119d:	8b 50 70             	mov    0x70(%eax),%edx
  8011a0:	85 d2                	test   %edx,%edx
  8011a2:	75 14                	jne    8011b8 <ipc_recv+0x84>
		cprintf("the value is 0, the envid is %x\n", thisenv->env_id);
  8011a4:	8b 40 48             	mov    0x48(%eax),%eax
  8011a7:	83 ec 08             	sub    $0x8,%esp
  8011aa:	50                   	push   %eax
  8011ab:	68 48 1b 80 00       	push   $0x801b48
  8011b0:	e8 e9 f0 ff ff       	call   80029e <cprintf>
  8011b5:	83 c4 10             	add    $0x10,%esp
	return thisenv->env_ipc_value;
  8011b8:	a1 0c 20 80 00       	mov    0x80200c,%eax
  8011bd:	8b 40 70             	mov    0x70(%eax),%eax
	

	


}
  8011c0:	8d 65 f8             	lea    -0x8(%ebp),%esp
  8011c3:	5b                   	pop    %ebx
  8011c4:	5e                   	pop    %esi
  8011c5:	5d                   	pop    %ebp
  8011c6:	c3                   	ret    

008011c7 <ipc_send>:
//   Use sys_yield() to be CPU-friendly.
//   If 'pg' is null, pass sys_ipc_try_send a value that it will understand
//   as meaning "no page".  (Zero is not the right value.)
void
ipc_send(envid_t to_env, uint32_t val, void *pg, int perm)
{
  8011c7:	55                   	push   %ebp
  8011c8:	89 e5                	mov    %esp,%ebp
  8011ca:	57                   	push   %edi
  8011cb:	56                   	push   %esi
  8011cc:	53                   	push   %ebx
  8011cd:	83 ec 0c             	sub    $0xc,%esp
  8011d0:	8b 7d 08             	mov    0x8(%ebp),%edi
  8011d3:	8b 75 10             	mov    0x10(%ebp),%esi
	// LAB 4: Your code here.
	//panic("ipc_send not implemented");
	
	int r =0;
	while(1){
		if(pg == 0)
  8011d6:	85 f6                	test   %esi,%esi
  8011d8:	75 18                	jne    8011f2 <ipc_send+0x2b>
			r=sys_ipc_try_send(to_env,  val, (void*) UTOP,  perm);
  8011da:	ff 75 14             	pushl  0x14(%ebp)
  8011dd:	68 00 00 c0 ee       	push   $0xeec00000
  8011e2:	ff 75 0c             	pushl  0xc(%ebp)
  8011e5:	57                   	push   %edi
  8011e6:	e8 05 fc ff ff       	call   800df0 <sys_ipc_try_send>
  8011eb:	89 c3                	mov    %eax,%ebx
  8011ed:	83 c4 10             	add    $0x10,%esp
  8011f0:	eb 12                	jmp    801204 <ipc_send+0x3d>
		else
			r = sys_ipc_try_send(to_env,  val, pg,  perm);
  8011f2:	ff 75 14             	pushl  0x14(%ebp)
  8011f5:	56                   	push   %esi
  8011f6:	ff 75 0c             	pushl  0xc(%ebp)
  8011f9:	57                   	push   %edi
  8011fa:	e8 f1 fb ff ff       	call   800df0 <sys_ipc_try_send>
  8011ff:	89 c3                	mov    %eax,%ebx
  801201:	83 c4 10             	add    $0x10,%esp

		if(r <0 && r != -E_IPC_NOT_RECV){
  801204:	89 d8                	mov    %ebx,%eax
  801206:	c1 e8 1f             	shr    $0x1f,%eax
  801209:	84 c0                	test   %al,%al
  80120b:	74 2a                	je     801237 <ipc_send+0x70>
  80120d:	83 fb f8             	cmp    $0xfffffff8,%ebx
  801210:	74 25                	je     801237 <ipc_send+0x70>
			cprintf("the envid is %x\n", sys_getenvid());
  801212:	e8 50 fa ff ff       	call   800c67 <sys_getenvid>
  801217:	83 ec 08             	sub    $0x8,%esp
  80121a:	50                   	push   %eax
  80121b:	68 9e 1b 80 00       	push   $0x801b9e
  801220:	e8 79 f0 ff ff       	call   80029e <cprintf>
			panic("ipc_send is error, and the errno is %d\n", r);
  801225:	53                   	push   %ebx
  801226:	68 6c 1b 80 00       	push   $0x801b6c
  80122b:	6a 53                	push   $0x53
  80122d:	68 94 1b 80 00       	push   $0x801b94
  801232:	e8 4d 00 00 00       	call   801284 <_panic>
		}
		else if(r == -E_IPC_NOT_RECV)
  801237:	83 fb f8             	cmp    $0xfffffff8,%ebx
  80123a:	75 07                	jne    801243 <ipc_send+0x7c>
			sys_yield();
  80123c:	e8 45 fa ff ff       	call   800c86 <sys_yield>
		else break;
	}
  801241:	eb 93                	jmp    8011d6 <ipc_send+0xf>
	



}
  801243:	8d 65 f4             	lea    -0xc(%ebp),%esp
  801246:	5b                   	pop    %ebx
  801247:	5e                   	pop    %esi
  801248:	5f                   	pop    %edi
  801249:	5d                   	pop    %ebp
  80124a:	c3                   	ret    

0080124b <ipc_find_env>:
// Find the first environment of the given type.  We'll use this to
// find special environments.
// Returns 0 if no such environment exists.
envid_t
ipc_find_env(enum EnvType type)
{
  80124b:	55                   	push   %ebp
  80124c:	89 e5                	mov    %esp,%ebp
  80124e:	8b 4d 08             	mov    0x8(%ebp),%ecx
	int i;
	for (i = 0; i < NENV; i++)
  801251:	b8 00 00 00 00       	mov    $0x0,%eax
		if (envs[i].env_type == type)
  801256:	6b d0 7c             	imul   $0x7c,%eax,%edx
  801259:	81 c2 00 00 c0 ee    	add    $0xeec00000,%edx
  80125f:	8b 52 50             	mov    0x50(%edx),%edx
  801262:	39 ca                	cmp    %ecx,%edx
  801264:	75 0d                	jne    801273 <ipc_find_env+0x28>
			return envs[i].env_id;
  801266:	6b c0 7c             	imul   $0x7c,%eax,%eax
  801269:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  80126e:	8b 40 48             	mov    0x48(%eax),%eax
  801271:	eb 0f                	jmp    801282 <ipc_find_env+0x37>
// Returns 0 if no such environment exists.
envid_t
ipc_find_env(enum EnvType type)
{
	int i;
	for (i = 0; i < NENV; i++)
  801273:	83 c0 01             	add    $0x1,%eax
  801276:	3d 00 04 00 00       	cmp    $0x400,%eax
  80127b:	75 d9                	jne    801256 <ipc_find_env+0xb>
		if (envs[i].env_type == type)
			return envs[i].env_id;
	return 0;
  80127d:	b8 00 00 00 00       	mov    $0x0,%eax
}
  801282:	5d                   	pop    %ebp
  801283:	c3                   	ret    

00801284 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  801284:	55                   	push   %ebp
  801285:	89 e5                	mov    %esp,%ebp
  801287:	56                   	push   %esi
  801288:	53                   	push   %ebx
	va_list ap;

	va_start(ap, fmt);
  801289:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  80128c:	8b 35 08 20 80 00    	mov    0x802008,%esi
  801292:	e8 d0 f9 ff ff       	call   800c67 <sys_getenvid>
  801297:	83 ec 0c             	sub    $0xc,%esp
  80129a:	ff 75 0c             	pushl  0xc(%ebp)
  80129d:	ff 75 08             	pushl  0x8(%ebp)
  8012a0:	56                   	push   %esi
  8012a1:	50                   	push   %eax
  8012a2:	68 b0 1b 80 00       	push   $0x801bb0
  8012a7:	e8 f2 ef ff ff       	call   80029e <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  8012ac:	83 c4 18             	add    $0x18,%esp
  8012af:	53                   	push   %ebx
  8012b0:	ff 75 10             	pushl  0x10(%ebp)
  8012b3:	e8 95 ef ff ff       	call   80024d <vcprintf>
	cprintf("\n");
  8012b8:	c7 04 24 25 16 80 00 	movl   $0x801625,(%esp)
  8012bf:	e8 da ef ff ff       	call   80029e <cprintf>
  8012c4:	83 c4 10             	add    $0x10,%esp

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  8012c7:	cc                   	int3   
  8012c8:	eb fd                	jmp    8012c7 <_panic+0x43>

008012ca <set_pgfault_handler>:
// at UXSTACKTOP), and tell the kernel to call the assembly-language
// _pgfault_upcall routine when a page fault occurs.
//
void
set_pgfault_handler(void (*handler)(struct UTrapframe *utf))
{
  8012ca:	55                   	push   %ebp
  8012cb:	89 e5                	mov    %esp,%ebp
  8012cd:	83 ec 08             	sub    $0x8,%esp
	int r;

	if (_pgfault_handler == 0) {
  8012d0:	83 3d 10 20 80 00 00 	cmpl   $0x0,0x802010
  8012d7:	75 31                	jne    80130a <set_pgfault_handler+0x40>
		// First time through!
		// LAB 4: Your code here.
		void* addr = (void*) (UXSTACKTOP-PGSIZE);
		r=sys_page_alloc(thisenv->env_id, addr, PTE_W|PTE_U|PTE_P);
  8012d9:	a1 0c 20 80 00       	mov    0x80200c,%eax
  8012de:	8b 40 48             	mov    0x48(%eax),%eax
  8012e1:	83 ec 04             	sub    $0x4,%esp
  8012e4:	6a 07                	push   $0x7
  8012e6:	68 00 f0 bf ee       	push   $0xeebff000
  8012eb:	50                   	push   %eax
  8012ec:	e8 b4 f9 ff ff       	call   800ca5 <sys_page_alloc>
		if( r < 0)
  8012f1:	83 c4 10             	add    $0x10,%esp
  8012f4:	85 c0                	test   %eax,%eax
  8012f6:	79 12                	jns    80130a <set_pgfault_handler+0x40>
			panic("No memory for the UxStack, the mistake is %d\n",r);
  8012f8:	50                   	push   %eax
  8012f9:	68 d4 1b 80 00       	push   $0x801bd4
  8012fe:	6a 23                	push   $0x23
  801300:	68 30 1c 80 00       	push   $0x801c30
  801305:	e8 7a ff ff ff       	call   801284 <_panic>
		//panic("set_pgfault_handler not implemented");
	}

	// Save handler pointer for assembly to call.
	_pgfault_handler = handler;
  80130a:	8b 45 08             	mov    0x8(%ebp),%eax
  80130d:	a3 10 20 80 00       	mov    %eax,0x802010
	if(( r= sys_env_set_pgfault_upcall(sys_getenvid(), _pgfault_upcall))<0)
  801312:	e8 50 f9 ff ff       	call   800c67 <sys_getenvid>
  801317:	83 ec 08             	sub    $0x8,%esp
  80131a:	68 40 13 80 00       	push   $0x801340
  80131f:	50                   	push   %eax
  801320:	e8 89 fa ff ff       	call   800dae <sys_env_set_pgfault_upcall>
  801325:	83 c4 10             	add    $0x10,%esp
  801328:	85 c0                	test   %eax,%eax
  80132a:	79 12                	jns    80133e <set_pgfault_handler+0x74>
		panic("sys_env_set_pgfault_upcall is not right %d\n", r);
  80132c:	50                   	push   %eax
  80132d:	68 04 1c 80 00       	push   $0x801c04
  801332:	6a 2a                	push   $0x2a
  801334:	68 30 1c 80 00       	push   $0x801c30
  801339:	e8 46 ff ff ff       	call   801284 <_panic>


}
  80133e:	c9                   	leave  
  80133f:	c3                   	ret    

00801340 <_pgfault_upcall>:

.text
.globl _pgfault_upcall
_pgfault_upcall:
	// Call the C page fault handler.
	pushl %esp			// function argument: pointer to UTF
  801340:	54                   	push   %esp
	movl _pgfault_handler, %eax
  801341:	a1 10 20 80 00       	mov    0x802010,%eax
	call *%eax
  801346:	ff d0                	call   *%eax
	addl $4, %esp			// pop function argument
  801348:	83 c4 04             	add    $0x4,%esp

	// Restore the trap-time registers.  After you do this, you
	// can no longer modify any general-purpose registers.
	// LAB 4: Your code here.
	//	trap-eip -> eax
		movl 0x28(%esp), %eax
  80134b:	8b 44 24 28          	mov    0x28(%esp),%eax
	//	trap-ebp-> ebx		
		movl 0x10(%esp), %ebx
  80134f:	8b 5c 24 10          	mov    0x10(%esp),%ebx
	//  trap->esp -> ecx 
		movl 0x30(%esp), %ecx
  801353:	8b 4c 24 30          	mov    0x30(%esp),%ecx

		movl %eax, -0x4(%ecx)
  801357:	89 41 fc             	mov    %eax,-0x4(%ecx)
		movl %ebx, -0x8(%ecx)
  80135a:	89 59 f8             	mov    %ebx,-0x8(%ecx)

		leal -0x8(%ecx), %ebp
  80135d:	8d 69 f8             	lea    -0x8(%ecx),%ebp

		movl 0x8(%esp), %edi
  801360:	8b 7c 24 08          	mov    0x8(%esp),%edi
		movl 0xc(%esp),	%esi
  801364:	8b 74 24 0c          	mov    0xc(%esp),%esi
		movl 0x18(%esp),%ebx
  801368:	8b 5c 24 18          	mov    0x18(%esp),%ebx
		movl 0x1c(%esp),%edx
  80136c:	8b 54 24 1c          	mov    0x1c(%esp),%edx
		movl 0x20(%esp),%ecx
  801370:	8b 4c 24 20          	mov    0x20(%esp),%ecx
		movl 0x24(%esp),%eax
  801374:	8b 44 24 24          	mov    0x24(%esp),%eax

	// Restore eflags from the stack.  After you do this, you can
	// no longer use arithmetic operations or anything else that
	// modifies eflags.
	// LAB 4: Your code here.
		leal 0x2c(%esp), %esp
  801378:	8d 64 24 2c          	lea    0x2c(%esp),%esp
		popf
  80137c:	9d                   	popf   
	// Switch back to the adjusted trap-time stack.
	// LAB 4: Your code here.
		leave
  80137d:	c9                   	leave  
	// Return to re-execute the instruction that faulted.
	// LAB 4: Your code here.
  80137e:	c3                   	ret    
  80137f:	90                   	nop

00801380 <__udivdi3>:
  801380:	55                   	push   %ebp
  801381:	57                   	push   %edi
  801382:	56                   	push   %esi
  801383:	53                   	push   %ebx
  801384:	83 ec 1c             	sub    $0x1c,%esp
  801387:	8b 74 24 3c          	mov    0x3c(%esp),%esi
  80138b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
  80138f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
  801393:	8b 7c 24 38          	mov    0x38(%esp),%edi
  801397:	85 f6                	test   %esi,%esi
  801399:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  80139d:	89 ca                	mov    %ecx,%edx
  80139f:	89 f8                	mov    %edi,%eax
  8013a1:	75 3d                	jne    8013e0 <__udivdi3+0x60>
  8013a3:	39 cf                	cmp    %ecx,%edi
  8013a5:	0f 87 c5 00 00 00    	ja     801470 <__udivdi3+0xf0>
  8013ab:	85 ff                	test   %edi,%edi
  8013ad:	89 fd                	mov    %edi,%ebp
  8013af:	75 0b                	jne    8013bc <__udivdi3+0x3c>
  8013b1:	b8 01 00 00 00       	mov    $0x1,%eax
  8013b6:	31 d2                	xor    %edx,%edx
  8013b8:	f7 f7                	div    %edi
  8013ba:	89 c5                	mov    %eax,%ebp
  8013bc:	89 c8                	mov    %ecx,%eax
  8013be:	31 d2                	xor    %edx,%edx
  8013c0:	f7 f5                	div    %ebp
  8013c2:	89 c1                	mov    %eax,%ecx
  8013c4:	89 d8                	mov    %ebx,%eax
  8013c6:	89 cf                	mov    %ecx,%edi
  8013c8:	f7 f5                	div    %ebp
  8013ca:	89 c3                	mov    %eax,%ebx
  8013cc:	89 d8                	mov    %ebx,%eax
  8013ce:	89 fa                	mov    %edi,%edx
  8013d0:	83 c4 1c             	add    $0x1c,%esp
  8013d3:	5b                   	pop    %ebx
  8013d4:	5e                   	pop    %esi
  8013d5:	5f                   	pop    %edi
  8013d6:	5d                   	pop    %ebp
  8013d7:	c3                   	ret    
  8013d8:	90                   	nop
  8013d9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  8013e0:	39 ce                	cmp    %ecx,%esi
  8013e2:	77 74                	ja     801458 <__udivdi3+0xd8>
  8013e4:	0f bd fe             	bsr    %esi,%edi
  8013e7:	83 f7 1f             	xor    $0x1f,%edi
  8013ea:	0f 84 98 00 00 00    	je     801488 <__udivdi3+0x108>
  8013f0:	bb 20 00 00 00       	mov    $0x20,%ebx
  8013f5:	89 f9                	mov    %edi,%ecx
  8013f7:	89 c5                	mov    %eax,%ebp
  8013f9:	29 fb                	sub    %edi,%ebx
  8013fb:	d3 e6                	shl    %cl,%esi
  8013fd:	89 d9                	mov    %ebx,%ecx
  8013ff:	d3 ed                	shr    %cl,%ebp
  801401:	89 f9                	mov    %edi,%ecx
  801403:	d3 e0                	shl    %cl,%eax
  801405:	09 ee                	or     %ebp,%esi
  801407:	89 d9                	mov    %ebx,%ecx
  801409:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80140d:	89 d5                	mov    %edx,%ebp
  80140f:	8b 44 24 08          	mov    0x8(%esp),%eax
  801413:	d3 ed                	shr    %cl,%ebp
  801415:	89 f9                	mov    %edi,%ecx
  801417:	d3 e2                	shl    %cl,%edx
  801419:	89 d9                	mov    %ebx,%ecx
  80141b:	d3 e8                	shr    %cl,%eax
  80141d:	09 c2                	or     %eax,%edx
  80141f:	89 d0                	mov    %edx,%eax
  801421:	89 ea                	mov    %ebp,%edx
  801423:	f7 f6                	div    %esi
  801425:	89 d5                	mov    %edx,%ebp
  801427:	89 c3                	mov    %eax,%ebx
  801429:	f7 64 24 0c          	mull   0xc(%esp)
  80142d:	39 d5                	cmp    %edx,%ebp
  80142f:	72 10                	jb     801441 <__udivdi3+0xc1>
  801431:	8b 74 24 08          	mov    0x8(%esp),%esi
  801435:	89 f9                	mov    %edi,%ecx
  801437:	d3 e6                	shl    %cl,%esi
  801439:	39 c6                	cmp    %eax,%esi
  80143b:	73 07                	jae    801444 <__udivdi3+0xc4>
  80143d:	39 d5                	cmp    %edx,%ebp
  80143f:	75 03                	jne    801444 <__udivdi3+0xc4>
  801441:	83 eb 01             	sub    $0x1,%ebx
  801444:	31 ff                	xor    %edi,%edi
  801446:	89 d8                	mov    %ebx,%eax
  801448:	89 fa                	mov    %edi,%edx
  80144a:	83 c4 1c             	add    $0x1c,%esp
  80144d:	5b                   	pop    %ebx
  80144e:	5e                   	pop    %esi
  80144f:	5f                   	pop    %edi
  801450:	5d                   	pop    %ebp
  801451:	c3                   	ret    
  801452:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  801458:	31 ff                	xor    %edi,%edi
  80145a:	31 db                	xor    %ebx,%ebx
  80145c:	89 d8                	mov    %ebx,%eax
  80145e:	89 fa                	mov    %edi,%edx
  801460:	83 c4 1c             	add    $0x1c,%esp
  801463:	5b                   	pop    %ebx
  801464:	5e                   	pop    %esi
  801465:	5f                   	pop    %edi
  801466:	5d                   	pop    %ebp
  801467:	c3                   	ret    
  801468:	90                   	nop
  801469:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  801470:	89 d8                	mov    %ebx,%eax
  801472:	f7 f7                	div    %edi
  801474:	31 ff                	xor    %edi,%edi
  801476:	89 c3                	mov    %eax,%ebx
  801478:	89 d8                	mov    %ebx,%eax
  80147a:	89 fa                	mov    %edi,%edx
  80147c:	83 c4 1c             	add    $0x1c,%esp
  80147f:	5b                   	pop    %ebx
  801480:	5e                   	pop    %esi
  801481:	5f                   	pop    %edi
  801482:	5d                   	pop    %ebp
  801483:	c3                   	ret    
  801484:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801488:	39 ce                	cmp    %ecx,%esi
  80148a:	72 0c                	jb     801498 <__udivdi3+0x118>
  80148c:	31 db                	xor    %ebx,%ebx
  80148e:	3b 44 24 08          	cmp    0x8(%esp),%eax
  801492:	0f 87 34 ff ff ff    	ja     8013cc <__udivdi3+0x4c>
  801498:	bb 01 00 00 00       	mov    $0x1,%ebx
  80149d:	e9 2a ff ff ff       	jmp    8013cc <__udivdi3+0x4c>
  8014a2:	66 90                	xchg   %ax,%ax
  8014a4:	66 90                	xchg   %ax,%ax
  8014a6:	66 90                	xchg   %ax,%ax
  8014a8:	66 90                	xchg   %ax,%ax
  8014aa:	66 90                	xchg   %ax,%ax
  8014ac:	66 90                	xchg   %ax,%ax
  8014ae:	66 90                	xchg   %ax,%ax

008014b0 <__umoddi3>:
  8014b0:	55                   	push   %ebp
  8014b1:	57                   	push   %edi
  8014b2:	56                   	push   %esi
  8014b3:	53                   	push   %ebx
  8014b4:	83 ec 1c             	sub    $0x1c,%esp
  8014b7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
  8014bb:	8b 4c 24 30          	mov    0x30(%esp),%ecx
  8014bf:	8b 74 24 34          	mov    0x34(%esp),%esi
  8014c3:	8b 7c 24 38          	mov    0x38(%esp),%edi
  8014c7:	85 d2                	test   %edx,%edx
  8014c9:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  8014cd:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  8014d1:	89 f3                	mov    %esi,%ebx
  8014d3:	89 3c 24             	mov    %edi,(%esp)
  8014d6:	89 74 24 04          	mov    %esi,0x4(%esp)
  8014da:	75 1c                	jne    8014f8 <__umoddi3+0x48>
  8014dc:	39 f7                	cmp    %esi,%edi
  8014de:	76 50                	jbe    801530 <__umoddi3+0x80>
  8014e0:	89 c8                	mov    %ecx,%eax
  8014e2:	89 f2                	mov    %esi,%edx
  8014e4:	f7 f7                	div    %edi
  8014e6:	89 d0                	mov    %edx,%eax
  8014e8:	31 d2                	xor    %edx,%edx
  8014ea:	83 c4 1c             	add    $0x1c,%esp
  8014ed:	5b                   	pop    %ebx
  8014ee:	5e                   	pop    %esi
  8014ef:	5f                   	pop    %edi
  8014f0:	5d                   	pop    %ebp
  8014f1:	c3                   	ret    
  8014f2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  8014f8:	39 f2                	cmp    %esi,%edx
  8014fa:	89 d0                	mov    %edx,%eax
  8014fc:	77 52                	ja     801550 <__umoddi3+0xa0>
  8014fe:	0f bd ea             	bsr    %edx,%ebp
  801501:	83 f5 1f             	xor    $0x1f,%ebp
  801504:	75 5a                	jne    801560 <__umoddi3+0xb0>
  801506:	3b 54 24 04          	cmp    0x4(%esp),%edx
  80150a:	0f 82 e0 00 00 00    	jb     8015f0 <__umoddi3+0x140>
  801510:	39 0c 24             	cmp    %ecx,(%esp)
  801513:	0f 86 d7 00 00 00    	jbe    8015f0 <__umoddi3+0x140>
  801519:	8b 44 24 08          	mov    0x8(%esp),%eax
  80151d:	8b 54 24 04          	mov    0x4(%esp),%edx
  801521:	83 c4 1c             	add    $0x1c,%esp
  801524:	5b                   	pop    %ebx
  801525:	5e                   	pop    %esi
  801526:	5f                   	pop    %edi
  801527:	5d                   	pop    %ebp
  801528:	c3                   	ret    
  801529:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  801530:	85 ff                	test   %edi,%edi
  801532:	89 fd                	mov    %edi,%ebp
  801534:	75 0b                	jne    801541 <__umoddi3+0x91>
  801536:	b8 01 00 00 00       	mov    $0x1,%eax
  80153b:	31 d2                	xor    %edx,%edx
  80153d:	f7 f7                	div    %edi
  80153f:	89 c5                	mov    %eax,%ebp
  801541:	89 f0                	mov    %esi,%eax
  801543:	31 d2                	xor    %edx,%edx
  801545:	f7 f5                	div    %ebp
  801547:	89 c8                	mov    %ecx,%eax
  801549:	f7 f5                	div    %ebp
  80154b:	89 d0                	mov    %edx,%eax
  80154d:	eb 99                	jmp    8014e8 <__umoddi3+0x38>
  80154f:	90                   	nop
  801550:	89 c8                	mov    %ecx,%eax
  801552:	89 f2                	mov    %esi,%edx
  801554:	83 c4 1c             	add    $0x1c,%esp
  801557:	5b                   	pop    %ebx
  801558:	5e                   	pop    %esi
  801559:	5f                   	pop    %edi
  80155a:	5d                   	pop    %ebp
  80155b:	c3                   	ret    
  80155c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801560:	8b 34 24             	mov    (%esp),%esi
  801563:	bf 20 00 00 00       	mov    $0x20,%edi
  801568:	89 e9                	mov    %ebp,%ecx
  80156a:	29 ef                	sub    %ebp,%edi
  80156c:	d3 e0                	shl    %cl,%eax
  80156e:	89 f9                	mov    %edi,%ecx
  801570:	89 f2                	mov    %esi,%edx
  801572:	d3 ea                	shr    %cl,%edx
  801574:	89 e9                	mov    %ebp,%ecx
  801576:	09 c2                	or     %eax,%edx
  801578:	89 d8                	mov    %ebx,%eax
  80157a:	89 14 24             	mov    %edx,(%esp)
  80157d:	89 f2                	mov    %esi,%edx
  80157f:	d3 e2                	shl    %cl,%edx
  801581:	89 f9                	mov    %edi,%ecx
  801583:	89 54 24 04          	mov    %edx,0x4(%esp)
  801587:	8b 54 24 0c          	mov    0xc(%esp),%edx
  80158b:	d3 e8                	shr    %cl,%eax
  80158d:	89 e9                	mov    %ebp,%ecx
  80158f:	89 c6                	mov    %eax,%esi
  801591:	d3 e3                	shl    %cl,%ebx
  801593:	89 f9                	mov    %edi,%ecx
  801595:	89 d0                	mov    %edx,%eax
  801597:	d3 e8                	shr    %cl,%eax
  801599:	89 e9                	mov    %ebp,%ecx
  80159b:	09 d8                	or     %ebx,%eax
  80159d:	89 d3                	mov    %edx,%ebx
  80159f:	89 f2                	mov    %esi,%edx
  8015a1:	f7 34 24             	divl   (%esp)
  8015a4:	89 d6                	mov    %edx,%esi
  8015a6:	d3 e3                	shl    %cl,%ebx
  8015a8:	f7 64 24 04          	mull   0x4(%esp)
  8015ac:	39 d6                	cmp    %edx,%esi
  8015ae:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  8015b2:	89 d1                	mov    %edx,%ecx
  8015b4:	89 c3                	mov    %eax,%ebx
  8015b6:	72 08                	jb     8015c0 <__umoddi3+0x110>
  8015b8:	75 11                	jne    8015cb <__umoddi3+0x11b>
  8015ba:	39 44 24 08          	cmp    %eax,0x8(%esp)
  8015be:	73 0b                	jae    8015cb <__umoddi3+0x11b>
  8015c0:	2b 44 24 04          	sub    0x4(%esp),%eax
  8015c4:	1b 14 24             	sbb    (%esp),%edx
  8015c7:	89 d1                	mov    %edx,%ecx
  8015c9:	89 c3                	mov    %eax,%ebx
  8015cb:	8b 54 24 08          	mov    0x8(%esp),%edx
  8015cf:	29 da                	sub    %ebx,%edx
  8015d1:	19 ce                	sbb    %ecx,%esi
  8015d3:	89 f9                	mov    %edi,%ecx
  8015d5:	89 f0                	mov    %esi,%eax
  8015d7:	d3 e0                	shl    %cl,%eax
  8015d9:	89 e9                	mov    %ebp,%ecx
  8015db:	d3 ea                	shr    %cl,%edx
  8015dd:	89 e9                	mov    %ebp,%ecx
  8015df:	d3 ee                	shr    %cl,%esi
  8015e1:	09 d0                	or     %edx,%eax
  8015e3:	89 f2                	mov    %esi,%edx
  8015e5:	83 c4 1c             	add    $0x1c,%esp
  8015e8:	5b                   	pop    %ebx
  8015e9:	5e                   	pop    %esi
  8015ea:	5f                   	pop    %edi
  8015eb:	5d                   	pop    %ebp
  8015ec:	c3                   	ret    
  8015ed:	8d 76 00             	lea    0x0(%esi),%esi
  8015f0:	29 f9                	sub    %edi,%ecx
  8015f2:	19 d6                	sbb    %edx,%esi
  8015f4:	89 74 24 04          	mov    %esi,0x4(%esp)
  8015f8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  8015fc:	e9 18 ff ff ff       	jmp    801519 <__umoddi3+0x69>
