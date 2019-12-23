
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4                   	.byte 0xe4

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 e0 11 00       	mov    $0x11e000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 e0 11 f0       	mov    $0xf011e000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 5c 00 00 00       	call   f010009a <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	56                   	push   %esi
f0100044:	53                   	push   %ebx
f0100045:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100048:	83 3d 80 fe 22 f0 00 	cmpl   $0x0,0xf022fe80
f010004f:	75 3a                	jne    f010008b <_panic+0x4b>
		goto dead;
	panicstr = fmt;
f0100051:	89 35 80 fe 22 f0    	mov    %esi,0xf022fe80

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f0100057:	fa                   	cli    
f0100058:	fc                   	cld    

	va_start(ap, fmt);
f0100059:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic on CPU %d at %s:%d: ", cpunum(), file, line);
f010005c:	e8 f9 5b 00 00       	call   f0105c5a <cpunum>
f0100061:	ff 75 0c             	pushl  0xc(%ebp)
f0100064:	ff 75 08             	pushl  0x8(%ebp)
f0100067:	50                   	push   %eax
f0100068:	68 00 63 10 f0       	push   $0xf0106300
f010006d:	e8 ea 36 00 00       	call   f010375c <cprintf>
	vcprintf(fmt, ap);
f0100072:	83 c4 08             	add    $0x8,%esp
f0100075:	53                   	push   %ebx
f0100076:	56                   	push   %esi
f0100077:	e8 ba 36 00 00       	call   f0103736 <vcprintf>
	cprintf("\n");
f010007c:	c7 04 24 30 74 10 f0 	movl   $0xf0107430,(%esp)
f0100083:	e8 d4 36 00 00       	call   f010375c <cprintf>
	va_end(ap);
f0100088:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010008b:	83 ec 0c             	sub    $0xc,%esp
f010008e:	6a 00                	push   $0x0
f0100090:	e8 fc 07 00 00       	call   f0100891 <monitor>
f0100095:	83 c4 10             	add    $0x10,%esp
f0100098:	eb f1                	jmp    f010008b <_panic+0x4b>

f010009a <i386_init>:
static void boot_aps(void);


void
i386_init(void)
{
f010009a:	55                   	push   %ebp
f010009b:	89 e5                	mov    %esp,%ebp
f010009d:	53                   	push   %ebx
f010009e:	83 ec 08             	sub    $0x8,%esp
	extern char edata[], end[];
	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f01000a1:	b8 08 10 27 f0       	mov    $0xf0271008,%eax
f01000a6:	2d 28 e6 22 f0       	sub    $0xf022e628,%eax
f01000ab:	50                   	push   %eax
f01000ac:	6a 00                	push   $0x0
f01000ae:	68 28 e6 22 f0       	push   $0xf022e628
f01000b3:	e8 81 55 00 00       	call   f0105639 <memset>
	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000b8:	e8 92 05 00 00       	call   f010064f <cons_init>
	cprintf("6828 decimal is %o octal!\n", 6828);
f01000bd:	83 c4 08             	add    $0x8,%esp
f01000c0:	68 ac 1a 00 00       	push   $0x1aac
f01000c5:	68 6c 63 10 f0       	push   $0xf010636c
f01000ca:	e8 8d 36 00 00       	call   f010375c <cprintf>
	// Lab 2 memory management initialization functions
	mem_init();
f01000cf:	e8 5c 11 00 00       	call   f0101230 <mem_init>
	// Lab 3 user environment initialization functions
	env_init();
f01000d4:	e8 69 2e 00 00       	call   f0102f42 <env_init>
	trap_init();
f01000d9:	e8 62 37 00 00       	call   f0103840 <trap_init>
	// Lab 4 multiprocessor initialization functions
	mp_init();
f01000de:	e8 6d 58 00 00       	call   f0105950 <mp_init>
	lapic_init();
f01000e3:	e8 8d 5b 00 00       	call   f0105c75 <lapic_init>
	// Lab 4 multitasking initialization functions
	pic_init();
f01000e8:	e8 96 35 00 00       	call   f0103683 <pic_init>
extern struct spinlock kernel_lock;

static inline void
lock_kernel(void)
{
	spin_lock(&kernel_lock);
f01000ed:	c7 04 24 c0 03 12 f0 	movl   $0xf01203c0,(%esp)
f01000f4:	e8 cf 5d 00 00       	call   f0105ec8 <spin_lock>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01000f9:	83 c4 10             	add    $0x10,%esp
f01000fc:	83 3d 88 fe 22 f0 07 	cmpl   $0x7,0xf022fe88
f0100103:	77 16                	ja     f010011b <i386_init+0x81>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100105:	68 00 70 00 00       	push   $0x7000
f010010a:	68 24 63 10 f0       	push   $0xf0106324
f010010f:	6a 57                	push   $0x57
f0100111:	68 87 63 10 f0       	push   $0xf0106387
f0100116:	e8 25 ff ff ff       	call   f0100040 <_panic>
	void *code;
	struct CpuInfo *c;

	// Write entry code to unused memory at MPENTRY_PADDR
	code = KADDR(MPENTRY_PADDR);
	memmove(code, mpentry_start, mpentry_end - mpentry_start);
f010011b:	83 ec 04             	sub    $0x4,%esp
f010011e:	b8 b6 58 10 f0       	mov    $0xf01058b6,%eax
f0100123:	2d 3c 58 10 f0       	sub    $0xf010583c,%eax
f0100128:	50                   	push   %eax
f0100129:	68 3c 58 10 f0       	push   $0xf010583c
f010012e:	68 00 70 00 f0       	push   $0xf0007000
f0100133:	e8 4e 55 00 00       	call   f0105686 <memmove>
f0100138:	83 c4 10             	add    $0x10,%esp

	// Boot each AP one at a time
	for (c = cpus; c < cpus + ncpu; c++) {
f010013b:	bb 20 00 23 f0       	mov    $0xf0230020,%ebx
f0100140:	eb 4d                	jmp    f010018f <i386_init+0xf5>
		if (c == cpus + cpunum())  // We've started already.
f0100142:	e8 13 5b 00 00       	call   f0105c5a <cpunum>
f0100147:	6b c0 74             	imul   $0x74,%eax,%eax
f010014a:	05 20 00 23 f0       	add    $0xf0230020,%eax
f010014f:	39 c3                	cmp    %eax,%ebx
f0100151:	74 39                	je     f010018c <i386_init+0xf2>
			continue;

		// Tell mpentry.S what stack to use 
		mpentry_kstack = percpu_kstacks[c - cpus] + KSTKSIZE;
f0100153:	89 d8                	mov    %ebx,%eax
f0100155:	2d 20 00 23 f0       	sub    $0xf0230020,%eax
f010015a:	c1 f8 02             	sar    $0x2,%eax
f010015d:	69 c0 35 c2 72 4f    	imul   $0x4f72c235,%eax,%eax
f0100163:	c1 e0 0f             	shl    $0xf,%eax
f0100166:	05 00 90 23 f0       	add    $0xf0239000,%eax
f010016b:	a3 84 fe 22 f0       	mov    %eax,0xf022fe84
		// Start the CPU at mpentry_start
		lapic_startap(c->cpu_id, PADDR(code));
f0100170:	83 ec 08             	sub    $0x8,%esp
f0100173:	68 00 70 00 00       	push   $0x7000
f0100178:	0f b6 03             	movzbl (%ebx),%eax
f010017b:	50                   	push   %eax
f010017c:	e8 42 5c 00 00       	call   f0105dc3 <lapic_startap>
f0100181:	83 c4 10             	add    $0x10,%esp
		// Wait for the CPU to finish some basic setup in mp_main()
		while(c->cpu_status != CPU_STARTED)
f0100184:	8b 43 04             	mov    0x4(%ebx),%eax
f0100187:	83 f8 01             	cmp    $0x1,%eax
f010018a:	75 f8                	jne    f0100184 <i386_init+0xea>
	// Write entry code to unused memory at MPENTRY_PADDR
	code = KADDR(MPENTRY_PADDR);
	memmove(code, mpentry_start, mpentry_end - mpentry_start);

	// Boot each AP one at a time
	for (c = cpus; c < cpus + ncpu; c++) {
f010018c:	83 c3 74             	add    $0x74,%ebx
f010018f:	6b 05 c4 03 23 f0 74 	imul   $0x74,0xf02303c4,%eax
f0100196:	05 20 00 23 f0       	add    $0xf0230020,%eax
f010019b:	39 c3                	cmp    %eax,%ebx
f010019d:	72 a3                	jb     f0100142 <i386_init+0xa8>
#else
	// Touch all you want.
	//ENV_CREATE(user_primes, ENV_TYPE_USER);
	//ENV_CREATE(user_idle, ENV_TYPE_USER);
	//ENV_CREATE(user_yield, ENV_TYPE_USER);
	ENV_CREATE(user_yield, ENV_TYPE_USER);
f010019f:	83 ec 08             	sub    $0x8,%esp
f01001a2:	6a 00                	push   $0x0
f01001a4:	68 9c 82 19 f0       	push   $0xf019829c
f01001a9:	e8 73 2f 00 00       	call   f0103121 <env_create>
	ENV_CREATE(user_yield, ENV_TYPE_USER);
f01001ae:	83 c4 08             	add    $0x8,%esp
f01001b1:	6a 00                	push   $0x0
f01001b3:	68 9c 82 19 f0       	push   $0xf019829c
f01001b8:	e8 64 2f 00 00       	call   f0103121 <env_create>
	ENV_CREATE(user_yield, ENV_TYPE_USER);
f01001bd:	83 c4 08             	add    $0x8,%esp
f01001c0:	6a 00                	push   $0x0
f01001c2:	68 9c 82 19 f0       	push   $0xf019829c
f01001c7:	e8 55 2f 00 00       	call   f0103121 <env_create>
														envs[2].env_status
														);
*/

	// Schedule and run the first user environment!
	sched_yield();
f01001cc:	e8 07 42 00 00       	call   f01043d8 <sched_yield>

f01001d1 <mp_main>:
}

// Setup code for APs
void
mp_main(void)
{
f01001d1:	55                   	push   %ebp
f01001d2:	89 e5                	mov    %esp,%ebp
f01001d4:	83 ec 08             	sub    $0x8,%esp
	// We are in high EIP now, safe to switch to kern_pgdir 
	lcr3(PADDR(kern_pgdir));
f01001d7:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01001dc:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01001e1:	77 12                	ja     f01001f5 <mp_main+0x24>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01001e3:	50                   	push   %eax
f01001e4:	68 48 63 10 f0       	push   $0xf0106348
f01001e9:	6a 6e                	push   $0x6e
f01001eb:	68 87 63 10 f0       	push   $0xf0106387
f01001f0:	e8 4b fe ff ff       	call   f0100040 <_panic>
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f01001f5:	05 00 00 00 10       	add    $0x10000000,%eax
f01001fa:	0f 22 d8             	mov    %eax,%cr3
	cprintf("SMP: CPU %d starting\n", cpunum());
f01001fd:	e8 58 5a 00 00       	call   f0105c5a <cpunum>
f0100202:	83 ec 08             	sub    $0x8,%esp
f0100205:	50                   	push   %eax
f0100206:	68 93 63 10 f0       	push   $0xf0106393
f010020b:	e8 4c 35 00 00       	call   f010375c <cprintf>

	lapic_init();
f0100210:	e8 60 5a 00 00       	call   f0105c75 <lapic_init>
	env_init_percpu();
f0100215:	e8 f8 2c 00 00       	call   f0102f12 <env_init_percpu>
	trap_init_percpu();
f010021a:	e8 51 35 00 00       	call   f0103770 <trap_init_percpu>
	xchg(&thiscpu->cpu_status, CPU_STARTED); // tell boot_aps() we're up
f010021f:	e8 36 5a 00 00       	call   f0105c5a <cpunum>
f0100224:	6b d0 74             	imul   $0x74,%eax,%edx
f0100227:	81 c2 20 00 23 f0    	add    $0xf0230020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f010022d:	b8 01 00 00 00       	mov    $0x1,%eax
f0100232:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
f0100236:	c7 04 24 c0 03 12 f0 	movl   $0xf01203c0,(%esp)
f010023d:	e8 86 5c 00 00       	call   f0105ec8 <spin_lock>
	// only one CPU can enter the scheduler at a time!
	//
	// Your code here:
	//在初始化完 AP 后获得内核锁，接着调用 sched_yield() 来开始在这个 AP 上运行进程。
	lock_kernel();
	sched_yield();
f0100242:	e8 91 41 00 00       	call   f01043d8 <sched_yield>

f0100247 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100247:	55                   	push   %ebp
f0100248:	89 e5                	mov    %esp,%ebp
f010024a:	53                   	push   %ebx
f010024b:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f010024e:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100251:	ff 75 0c             	pushl  0xc(%ebp)
f0100254:	ff 75 08             	pushl  0x8(%ebp)
f0100257:	68 a9 63 10 f0       	push   $0xf01063a9
f010025c:	e8 fb 34 00 00       	call   f010375c <cprintf>
	vcprintf(fmt, ap);
f0100261:	83 c4 08             	add    $0x8,%esp
f0100264:	53                   	push   %ebx
f0100265:	ff 75 10             	pushl  0x10(%ebp)
f0100268:	e8 c9 34 00 00       	call   f0103736 <vcprintf>
	cprintf("\n");
f010026d:	c7 04 24 30 74 10 f0 	movl   $0xf0107430,(%esp)
f0100274:	e8 e3 34 00 00       	call   f010375c <cprintf>
	va_end(ap);
}
f0100279:	83 c4 10             	add    $0x10,%esp
f010027c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010027f:	c9                   	leave  
f0100280:	c3                   	ret    

f0100281 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100281:	55                   	push   %ebp
f0100282:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100284:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100289:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f010028a:	a8 01                	test   $0x1,%al
f010028c:	74 0b                	je     f0100299 <serial_proc_data+0x18>
f010028e:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100293:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100294:	0f b6 c0             	movzbl %al,%eax
f0100297:	eb 05                	jmp    f010029e <serial_proc_data+0x1d>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100299:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f010029e:	5d                   	pop    %ebp
f010029f:	c3                   	ret    

f01002a0 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f01002a0:	55                   	push   %ebp
f01002a1:	89 e5                	mov    %esp,%ebp
f01002a3:	53                   	push   %ebx
f01002a4:	83 ec 04             	sub    $0x4,%esp
f01002a7:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f01002a9:	eb 2b                	jmp    f01002d6 <cons_intr+0x36>
		if (c == 0)
f01002ab:	85 c0                	test   %eax,%eax
f01002ad:	74 27                	je     f01002d6 <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f01002af:	8b 0d 24 f2 22 f0    	mov    0xf022f224,%ecx
f01002b5:	8d 51 01             	lea    0x1(%ecx),%edx
f01002b8:	89 15 24 f2 22 f0    	mov    %edx,0xf022f224
f01002be:	88 81 20 f0 22 f0    	mov    %al,-0xfdd0fe0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f01002c4:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01002ca:	75 0a                	jne    f01002d6 <cons_intr+0x36>
			cons.wpos = 0;
f01002cc:	c7 05 24 f2 22 f0 00 	movl   $0x0,0xf022f224
f01002d3:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01002d6:	ff d3                	call   *%ebx
f01002d8:	83 f8 ff             	cmp    $0xffffffff,%eax
f01002db:	75 ce                	jne    f01002ab <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01002dd:	83 c4 04             	add    $0x4,%esp
f01002e0:	5b                   	pop    %ebx
f01002e1:	5d                   	pop    %ebp
f01002e2:	c3                   	ret    

f01002e3 <kbd_proc_data>:
f01002e3:	ba 64 00 00 00       	mov    $0x64,%edx
f01002e8:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f01002e9:	a8 01                	test   $0x1,%al
f01002eb:	0f 84 f0 00 00 00    	je     f01003e1 <kbd_proc_data+0xfe>
f01002f1:	ba 60 00 00 00       	mov    $0x60,%edx
f01002f6:	ec                   	in     (%dx),%al
f01002f7:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01002f9:	3c e0                	cmp    $0xe0,%al
f01002fb:	75 0d                	jne    f010030a <kbd_proc_data+0x27>
		// E0 escape character
		shift |= E0ESC;
f01002fd:	83 0d 00 f0 22 f0 40 	orl    $0x40,0xf022f000
		return 0;
f0100304:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100309:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f010030a:	55                   	push   %ebp
f010030b:	89 e5                	mov    %esp,%ebp
f010030d:	53                   	push   %ebx
f010030e:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f0100311:	84 c0                	test   %al,%al
f0100313:	79 36                	jns    f010034b <kbd_proc_data+0x68>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f0100315:	8b 0d 00 f0 22 f0    	mov    0xf022f000,%ecx
f010031b:	89 cb                	mov    %ecx,%ebx
f010031d:	83 e3 40             	and    $0x40,%ebx
f0100320:	83 e0 7f             	and    $0x7f,%eax
f0100323:	85 db                	test   %ebx,%ebx
f0100325:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100328:	0f b6 d2             	movzbl %dl,%edx
f010032b:	0f b6 82 20 65 10 f0 	movzbl -0xfef9ae0(%edx),%eax
f0100332:	83 c8 40             	or     $0x40,%eax
f0100335:	0f b6 c0             	movzbl %al,%eax
f0100338:	f7 d0                	not    %eax
f010033a:	21 c8                	and    %ecx,%eax
f010033c:	a3 00 f0 22 f0       	mov    %eax,0xf022f000
		return 0;
f0100341:	b8 00 00 00 00       	mov    $0x0,%eax
f0100346:	e9 9e 00 00 00       	jmp    f01003e9 <kbd_proc_data+0x106>
	} else if (shift & E0ESC) {
f010034b:	8b 0d 00 f0 22 f0    	mov    0xf022f000,%ecx
f0100351:	f6 c1 40             	test   $0x40,%cl
f0100354:	74 0e                	je     f0100364 <kbd_proc_data+0x81>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100356:	83 c8 80             	or     $0xffffff80,%eax
f0100359:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f010035b:	83 e1 bf             	and    $0xffffffbf,%ecx
f010035e:	89 0d 00 f0 22 f0    	mov    %ecx,0xf022f000
	}

	shift |= shiftcode[data];
f0100364:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f0100367:	0f b6 82 20 65 10 f0 	movzbl -0xfef9ae0(%edx),%eax
f010036e:	0b 05 00 f0 22 f0    	or     0xf022f000,%eax
f0100374:	0f b6 8a 20 64 10 f0 	movzbl -0xfef9be0(%edx),%ecx
f010037b:	31 c8                	xor    %ecx,%eax
f010037d:	a3 00 f0 22 f0       	mov    %eax,0xf022f000

	c = charcode[shift & (CTL | SHIFT)][data];
f0100382:	89 c1                	mov    %eax,%ecx
f0100384:	83 e1 03             	and    $0x3,%ecx
f0100387:	8b 0c 8d 00 64 10 f0 	mov    -0xfef9c00(,%ecx,4),%ecx
f010038e:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100392:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100395:	a8 08                	test   $0x8,%al
f0100397:	74 1b                	je     f01003b4 <kbd_proc_data+0xd1>
		if ('a' <= c && c <= 'z')
f0100399:	89 da                	mov    %ebx,%edx
f010039b:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f010039e:	83 f9 19             	cmp    $0x19,%ecx
f01003a1:	77 05                	ja     f01003a8 <kbd_proc_data+0xc5>
			c += 'A' - 'a';
f01003a3:	83 eb 20             	sub    $0x20,%ebx
f01003a6:	eb 0c                	jmp    f01003b4 <kbd_proc_data+0xd1>
		else if ('A' <= c && c <= 'Z')
f01003a8:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01003ab:	8d 4b 20             	lea    0x20(%ebx),%ecx
f01003ae:	83 fa 19             	cmp    $0x19,%edx
f01003b1:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01003b4:	f7 d0                	not    %eax
f01003b6:	a8 06                	test   $0x6,%al
f01003b8:	75 2d                	jne    f01003e7 <kbd_proc_data+0x104>
f01003ba:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01003c0:	75 25                	jne    f01003e7 <kbd_proc_data+0x104>
		cprintf("Rebooting!\n");
f01003c2:	83 ec 0c             	sub    $0xc,%esp
f01003c5:	68 c3 63 10 f0       	push   $0xf01063c3
f01003ca:	e8 8d 33 00 00       	call   f010375c <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01003cf:	ba 92 00 00 00       	mov    $0x92,%edx
f01003d4:	b8 03 00 00 00       	mov    $0x3,%eax
f01003d9:	ee                   	out    %al,(%dx)
f01003da:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01003dd:	89 d8                	mov    %ebx,%eax
f01003df:	eb 08                	jmp    f01003e9 <kbd_proc_data+0x106>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f01003e1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01003e6:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01003e7:	89 d8                	mov    %ebx,%eax
}
f01003e9:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01003ec:	c9                   	leave  
f01003ed:	c3                   	ret    

f01003ee <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01003ee:	55                   	push   %ebp
f01003ef:	89 e5                	mov    %esp,%ebp
f01003f1:	57                   	push   %edi
f01003f2:	56                   	push   %esi
f01003f3:	53                   	push   %ebx
f01003f4:	83 ec 1c             	sub    $0x1c,%esp
f01003f7:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01003f9:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01003fe:	be fd 03 00 00       	mov    $0x3fd,%esi
f0100403:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100408:	eb 09                	jmp    f0100413 <cons_putc+0x25>
f010040a:	89 ca                	mov    %ecx,%edx
f010040c:	ec                   	in     (%dx),%al
f010040d:	ec                   	in     (%dx),%al
f010040e:	ec                   	in     (%dx),%al
f010040f:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f0100410:	83 c3 01             	add    $0x1,%ebx
f0100413:	89 f2                	mov    %esi,%edx
f0100415:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100416:	a8 20                	test   $0x20,%al
f0100418:	75 08                	jne    f0100422 <cons_putc+0x34>
f010041a:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100420:	7e e8                	jle    f010040a <cons_putc+0x1c>
f0100422:	89 f8                	mov    %edi,%eax
f0100424:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100427:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010042c:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010042d:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100432:	be 79 03 00 00       	mov    $0x379,%esi
f0100437:	b9 84 00 00 00       	mov    $0x84,%ecx
f010043c:	eb 09                	jmp    f0100447 <cons_putc+0x59>
f010043e:	89 ca                	mov    %ecx,%edx
f0100440:	ec                   	in     (%dx),%al
f0100441:	ec                   	in     (%dx),%al
f0100442:	ec                   	in     (%dx),%al
f0100443:	ec                   	in     (%dx),%al
f0100444:	83 c3 01             	add    $0x1,%ebx
f0100447:	89 f2                	mov    %esi,%edx
f0100449:	ec                   	in     (%dx),%al
f010044a:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100450:	7f 04                	jg     f0100456 <cons_putc+0x68>
f0100452:	84 c0                	test   %al,%al
f0100454:	79 e8                	jns    f010043e <cons_putc+0x50>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100456:	ba 78 03 00 00       	mov    $0x378,%edx
f010045b:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f010045f:	ee                   	out    %al,(%dx)
f0100460:	ba 7a 03 00 00       	mov    $0x37a,%edx
f0100465:	b8 0d 00 00 00       	mov    $0xd,%eax
f010046a:	ee                   	out    %al,(%dx)
f010046b:	b8 08 00 00 00       	mov    $0x8,%eax
f0100470:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100471:	89 fa                	mov    %edi,%edx
f0100473:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100479:	89 f8                	mov    %edi,%eax
f010047b:	80 cc 07             	or     $0x7,%ah
f010047e:	85 d2                	test   %edx,%edx
f0100480:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100483:	89 f8                	mov    %edi,%eax
f0100485:	0f b6 c0             	movzbl %al,%eax
f0100488:	83 f8 09             	cmp    $0x9,%eax
f010048b:	74 74                	je     f0100501 <cons_putc+0x113>
f010048d:	83 f8 09             	cmp    $0x9,%eax
f0100490:	7f 0a                	jg     f010049c <cons_putc+0xae>
f0100492:	83 f8 08             	cmp    $0x8,%eax
f0100495:	74 14                	je     f01004ab <cons_putc+0xbd>
f0100497:	e9 99 00 00 00       	jmp    f0100535 <cons_putc+0x147>
f010049c:	83 f8 0a             	cmp    $0xa,%eax
f010049f:	74 3a                	je     f01004db <cons_putc+0xed>
f01004a1:	83 f8 0d             	cmp    $0xd,%eax
f01004a4:	74 3d                	je     f01004e3 <cons_putc+0xf5>
f01004a6:	e9 8a 00 00 00       	jmp    f0100535 <cons_putc+0x147>
	case '\b':
		if (crt_pos > 0) {
f01004ab:	0f b7 05 28 f2 22 f0 	movzwl 0xf022f228,%eax
f01004b2:	66 85 c0             	test   %ax,%ax
f01004b5:	0f 84 e6 00 00 00    	je     f01005a1 <cons_putc+0x1b3>
			crt_pos--;
f01004bb:	83 e8 01             	sub    $0x1,%eax
f01004be:	66 a3 28 f2 22 f0    	mov    %ax,0xf022f228
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01004c4:	0f b7 c0             	movzwl %ax,%eax
f01004c7:	66 81 e7 00 ff       	and    $0xff00,%di
f01004cc:	83 cf 20             	or     $0x20,%edi
f01004cf:	8b 15 2c f2 22 f0    	mov    0xf022f22c,%edx
f01004d5:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01004d9:	eb 78                	jmp    f0100553 <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01004db:	66 83 05 28 f2 22 f0 	addw   $0x50,0xf022f228
f01004e2:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01004e3:	0f b7 05 28 f2 22 f0 	movzwl 0xf022f228,%eax
f01004ea:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01004f0:	c1 e8 16             	shr    $0x16,%eax
f01004f3:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01004f6:	c1 e0 04             	shl    $0x4,%eax
f01004f9:	66 a3 28 f2 22 f0    	mov    %ax,0xf022f228
f01004ff:	eb 52                	jmp    f0100553 <cons_putc+0x165>
		break;
	case '\t':
		cons_putc(' ');
f0100501:	b8 20 00 00 00       	mov    $0x20,%eax
f0100506:	e8 e3 fe ff ff       	call   f01003ee <cons_putc>
		cons_putc(' ');
f010050b:	b8 20 00 00 00       	mov    $0x20,%eax
f0100510:	e8 d9 fe ff ff       	call   f01003ee <cons_putc>
		cons_putc(' ');
f0100515:	b8 20 00 00 00       	mov    $0x20,%eax
f010051a:	e8 cf fe ff ff       	call   f01003ee <cons_putc>
		cons_putc(' ');
f010051f:	b8 20 00 00 00       	mov    $0x20,%eax
f0100524:	e8 c5 fe ff ff       	call   f01003ee <cons_putc>
		cons_putc(' ');
f0100529:	b8 20 00 00 00       	mov    $0x20,%eax
f010052e:	e8 bb fe ff ff       	call   f01003ee <cons_putc>
f0100533:	eb 1e                	jmp    f0100553 <cons_putc+0x165>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100535:	0f b7 05 28 f2 22 f0 	movzwl 0xf022f228,%eax
f010053c:	8d 50 01             	lea    0x1(%eax),%edx
f010053f:	66 89 15 28 f2 22 f0 	mov    %dx,0xf022f228
f0100546:	0f b7 c0             	movzwl %ax,%eax
f0100549:	8b 15 2c f2 22 f0    	mov    0xf022f22c,%edx
f010054f:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100553:	66 81 3d 28 f2 22 f0 	cmpw   $0x7cf,0xf022f228
f010055a:	cf 07 
f010055c:	76 43                	jbe    f01005a1 <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010055e:	a1 2c f2 22 f0       	mov    0xf022f22c,%eax
f0100563:	83 ec 04             	sub    $0x4,%esp
f0100566:	68 00 0f 00 00       	push   $0xf00
f010056b:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100571:	52                   	push   %edx
f0100572:	50                   	push   %eax
f0100573:	e8 0e 51 00 00       	call   f0105686 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100578:	8b 15 2c f2 22 f0    	mov    0xf022f22c,%edx
f010057e:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f0100584:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f010058a:	83 c4 10             	add    $0x10,%esp
f010058d:	66 c7 00 20 07       	movw   $0x720,(%eax)
f0100592:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100595:	39 d0                	cmp    %edx,%eax
f0100597:	75 f4                	jne    f010058d <cons_putc+0x19f>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100599:	66 83 2d 28 f2 22 f0 	subw   $0x50,0xf022f228
f01005a0:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f01005a1:	8b 0d 30 f2 22 f0    	mov    0xf022f230,%ecx
f01005a7:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005ac:	89 ca                	mov    %ecx,%edx
f01005ae:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01005af:	0f b7 1d 28 f2 22 f0 	movzwl 0xf022f228,%ebx
f01005b6:	8d 71 01             	lea    0x1(%ecx),%esi
f01005b9:	89 d8                	mov    %ebx,%eax
f01005bb:	66 c1 e8 08          	shr    $0x8,%ax
f01005bf:	89 f2                	mov    %esi,%edx
f01005c1:	ee                   	out    %al,(%dx)
f01005c2:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005c7:	89 ca                	mov    %ecx,%edx
f01005c9:	ee                   	out    %al,(%dx)
f01005ca:	89 d8                	mov    %ebx,%eax
f01005cc:	89 f2                	mov    %esi,%edx
f01005ce:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01005cf:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01005d2:	5b                   	pop    %ebx
f01005d3:	5e                   	pop    %esi
f01005d4:	5f                   	pop    %edi
f01005d5:	5d                   	pop    %ebp
f01005d6:	c3                   	ret    

f01005d7 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01005d7:	80 3d 34 f2 22 f0 00 	cmpb   $0x0,0xf022f234
f01005de:	74 11                	je     f01005f1 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01005e0:	55                   	push   %ebp
f01005e1:	89 e5                	mov    %esp,%ebp
f01005e3:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01005e6:	b8 81 02 10 f0       	mov    $0xf0100281,%eax
f01005eb:	e8 b0 fc ff ff       	call   f01002a0 <cons_intr>
}
f01005f0:	c9                   	leave  
f01005f1:	f3 c3                	repz ret 

f01005f3 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01005f3:	55                   	push   %ebp
f01005f4:	89 e5                	mov    %esp,%ebp
f01005f6:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01005f9:	b8 e3 02 10 f0       	mov    $0xf01002e3,%eax
f01005fe:	e8 9d fc ff ff       	call   f01002a0 <cons_intr>
}
f0100603:	c9                   	leave  
f0100604:	c3                   	ret    

f0100605 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f0100605:	55                   	push   %ebp
f0100606:	89 e5                	mov    %esp,%ebp
f0100608:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f010060b:	e8 c7 ff ff ff       	call   f01005d7 <serial_intr>
	kbd_intr();
f0100610:	e8 de ff ff ff       	call   f01005f3 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100615:	a1 20 f2 22 f0       	mov    0xf022f220,%eax
f010061a:	3b 05 24 f2 22 f0    	cmp    0xf022f224,%eax
f0100620:	74 26                	je     f0100648 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100622:	8d 50 01             	lea    0x1(%eax),%edx
f0100625:	89 15 20 f2 22 f0    	mov    %edx,0xf022f220
f010062b:	0f b6 88 20 f0 22 f0 	movzbl -0xfdd0fe0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f0100632:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f0100634:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010063a:	75 11                	jne    f010064d <cons_getc+0x48>
			cons.rpos = 0;
f010063c:	c7 05 20 f2 22 f0 00 	movl   $0x0,0xf022f220
f0100643:	00 00 00 
f0100646:	eb 05                	jmp    f010064d <cons_getc+0x48>
		return c;
	}
	return 0;
f0100648:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010064d:	c9                   	leave  
f010064e:	c3                   	ret    

f010064f <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f010064f:	55                   	push   %ebp
f0100650:	89 e5                	mov    %esp,%ebp
f0100652:	57                   	push   %edi
f0100653:	56                   	push   %esi
f0100654:	53                   	push   %ebx
f0100655:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100658:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010065f:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100666:	5a a5 
	if (*cp != 0xA55A) {
f0100668:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010066f:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100673:	74 11                	je     f0100686 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100675:	c7 05 30 f2 22 f0 b4 	movl   $0x3b4,0xf022f230
f010067c:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010067f:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f0100684:	eb 16                	jmp    f010069c <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100686:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010068d:	c7 05 30 f2 22 f0 d4 	movl   $0x3d4,0xf022f230
f0100694:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100697:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f010069c:	8b 3d 30 f2 22 f0    	mov    0xf022f230,%edi
f01006a2:	b8 0e 00 00 00       	mov    $0xe,%eax
f01006a7:	89 fa                	mov    %edi,%edx
f01006a9:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01006aa:	8d 5f 01             	lea    0x1(%edi),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01006ad:	89 da                	mov    %ebx,%edx
f01006af:	ec                   	in     (%dx),%al
f01006b0:	0f b6 c8             	movzbl %al,%ecx
f01006b3:	c1 e1 08             	shl    $0x8,%ecx
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01006b6:	b8 0f 00 00 00       	mov    $0xf,%eax
f01006bb:	89 fa                	mov    %edi,%edx
f01006bd:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01006be:	89 da                	mov    %ebx,%edx
f01006c0:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01006c1:	89 35 2c f2 22 f0    	mov    %esi,0xf022f22c
	crt_pos = pos;
f01006c7:	0f b6 c0             	movzbl %al,%eax
f01006ca:	09 c8                	or     %ecx,%eax
f01006cc:	66 a3 28 f2 22 f0    	mov    %ax,0xf022f228

static void
kbd_init(void)
{
	// Drain the kbd buffer so that QEMU generates interrupts.
	kbd_intr();
f01006d2:	e8 1c ff ff ff       	call   f01005f3 <kbd_intr>
	irq_setmask_8259A(irq_mask_8259A & ~(1<<1));
f01006d7:	83 ec 0c             	sub    $0xc,%esp
f01006da:	0f b7 05 a8 03 12 f0 	movzwl 0xf01203a8,%eax
f01006e1:	25 fd ff 00 00       	and    $0xfffd,%eax
f01006e6:	50                   	push   %eax
f01006e7:	e8 1f 2f 00 00       	call   f010360b <irq_setmask_8259A>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01006ec:	be fa 03 00 00       	mov    $0x3fa,%esi
f01006f1:	b8 00 00 00 00       	mov    $0x0,%eax
f01006f6:	89 f2                	mov    %esi,%edx
f01006f8:	ee                   	out    %al,(%dx)
f01006f9:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01006fe:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100703:	ee                   	out    %al,(%dx)
f0100704:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f0100709:	b8 0c 00 00 00       	mov    $0xc,%eax
f010070e:	89 da                	mov    %ebx,%edx
f0100710:	ee                   	out    %al,(%dx)
f0100711:	ba f9 03 00 00       	mov    $0x3f9,%edx
f0100716:	b8 00 00 00 00       	mov    $0x0,%eax
f010071b:	ee                   	out    %al,(%dx)
f010071c:	ba fb 03 00 00       	mov    $0x3fb,%edx
f0100721:	b8 03 00 00 00       	mov    $0x3,%eax
f0100726:	ee                   	out    %al,(%dx)
f0100727:	ba fc 03 00 00       	mov    $0x3fc,%edx
f010072c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100731:	ee                   	out    %al,(%dx)
f0100732:	ba f9 03 00 00       	mov    $0x3f9,%edx
f0100737:	b8 01 00 00 00       	mov    $0x1,%eax
f010073c:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010073d:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100742:	ec                   	in     (%dx),%al
f0100743:	89 c1                	mov    %eax,%ecx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100745:	83 c4 10             	add    $0x10,%esp
f0100748:	3c ff                	cmp    $0xff,%al
f010074a:	0f 95 05 34 f2 22 f0 	setne  0xf022f234
f0100751:	89 f2                	mov    %esi,%edx
f0100753:	ec                   	in     (%dx),%al
f0100754:	89 da                	mov    %ebx,%edx
f0100756:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100757:	80 f9 ff             	cmp    $0xff,%cl
f010075a:	75 10                	jne    f010076c <cons_init+0x11d>
		cprintf("Serial port does not exist!\n");
f010075c:	83 ec 0c             	sub    $0xc,%esp
f010075f:	68 cf 63 10 f0       	push   $0xf01063cf
f0100764:	e8 f3 2f 00 00       	call   f010375c <cprintf>
f0100769:	83 c4 10             	add    $0x10,%esp
}
f010076c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010076f:	5b                   	pop    %ebx
f0100770:	5e                   	pop    %esi
f0100771:	5f                   	pop    %edi
f0100772:	5d                   	pop    %ebp
f0100773:	c3                   	ret    

f0100774 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100774:	55                   	push   %ebp
f0100775:	89 e5                	mov    %esp,%ebp
f0100777:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f010077a:	8b 45 08             	mov    0x8(%ebp),%eax
f010077d:	e8 6c fc ff ff       	call   f01003ee <cons_putc>
}
f0100782:	c9                   	leave  
f0100783:	c3                   	ret    

f0100784 <getchar>:

int
getchar(void)
{
f0100784:	55                   	push   %ebp
f0100785:	89 e5                	mov    %esp,%ebp
f0100787:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f010078a:	e8 76 fe ff ff       	call   f0100605 <cons_getc>
f010078f:	85 c0                	test   %eax,%eax
f0100791:	74 f7                	je     f010078a <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100793:	c9                   	leave  
f0100794:	c3                   	ret    

f0100795 <iscons>:

int
iscons(int fdnum)
{
f0100795:	55                   	push   %ebp
f0100796:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100798:	b8 01 00 00 00       	mov    $0x1,%eax
f010079d:	5d                   	pop    %ebp
f010079e:	c3                   	ret    

f010079f <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f010079f:	55                   	push   %ebp
f01007a0:	89 e5                	mov    %esp,%ebp
f01007a2:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f01007a5:	68 20 66 10 f0       	push   $0xf0106620
f01007aa:	68 3e 66 10 f0       	push   $0xf010663e
f01007af:	68 43 66 10 f0       	push   $0xf0106643
f01007b4:	e8 a3 2f 00 00       	call   f010375c <cprintf>
f01007b9:	83 c4 0c             	add    $0xc,%esp
f01007bc:	68 ac 66 10 f0       	push   $0xf01066ac
f01007c1:	68 4c 66 10 f0       	push   $0xf010664c
f01007c6:	68 43 66 10 f0       	push   $0xf0106643
f01007cb:	e8 8c 2f 00 00       	call   f010375c <cprintf>
	return 0;
}
f01007d0:	b8 00 00 00 00       	mov    $0x0,%eax
f01007d5:	c9                   	leave  
f01007d6:	c3                   	ret    

f01007d7 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01007d7:	55                   	push   %ebp
f01007d8:	89 e5                	mov    %esp,%ebp
f01007da:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01007dd:	68 55 66 10 f0       	push   $0xf0106655
f01007e2:	e8 75 2f 00 00       	call   f010375c <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01007e7:	83 c4 08             	add    $0x8,%esp
f01007ea:	68 0c 00 10 00       	push   $0x10000c
f01007ef:	68 d4 66 10 f0       	push   $0xf01066d4
f01007f4:	e8 63 2f 00 00       	call   f010375c <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01007f9:	83 c4 0c             	add    $0xc,%esp
f01007fc:	68 0c 00 10 00       	push   $0x10000c
f0100801:	68 0c 00 10 f0       	push   $0xf010000c
f0100806:	68 fc 66 10 f0       	push   $0xf01066fc
f010080b:	e8 4c 2f 00 00       	call   f010375c <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100810:	83 c4 0c             	add    $0xc,%esp
f0100813:	68 e1 62 10 00       	push   $0x1062e1
f0100818:	68 e1 62 10 f0       	push   $0xf01062e1
f010081d:	68 20 67 10 f0       	push   $0xf0106720
f0100822:	e8 35 2f 00 00       	call   f010375c <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100827:	83 c4 0c             	add    $0xc,%esp
f010082a:	68 28 e6 22 00       	push   $0x22e628
f010082f:	68 28 e6 22 f0       	push   $0xf022e628
f0100834:	68 44 67 10 f0       	push   $0xf0106744
f0100839:	e8 1e 2f 00 00       	call   f010375c <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010083e:	83 c4 0c             	add    $0xc,%esp
f0100841:	68 08 10 27 00       	push   $0x271008
f0100846:	68 08 10 27 f0       	push   $0xf0271008
f010084b:	68 68 67 10 f0       	push   $0xf0106768
f0100850:	e8 07 2f 00 00       	call   f010375c <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100855:	b8 07 14 27 f0       	mov    $0xf0271407,%eax
f010085a:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f010085f:	83 c4 08             	add    $0x8,%esp
f0100862:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f0100867:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f010086d:	85 c0                	test   %eax,%eax
f010086f:	0f 48 c2             	cmovs  %edx,%eax
f0100872:	c1 f8 0a             	sar    $0xa,%eax
f0100875:	50                   	push   %eax
f0100876:	68 8c 67 10 f0       	push   $0xf010678c
f010087b:	e8 dc 2e 00 00       	call   f010375c <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100880:	b8 00 00 00 00       	mov    $0x0,%eax
f0100885:	c9                   	leave  
f0100886:	c3                   	ret    

f0100887 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100887:	55                   	push   %ebp
f0100888:	89 e5                	mov    %esp,%ebp
	// Your code here.
	return 0;
}
f010088a:	b8 00 00 00 00       	mov    $0x0,%eax
f010088f:	5d                   	pop    %ebp
f0100890:	c3                   	ret    

f0100891 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100891:	55                   	push   %ebp
f0100892:	89 e5                	mov    %esp,%ebp
f0100894:	57                   	push   %edi
f0100895:	56                   	push   %esi
f0100896:	53                   	push   %ebx
f0100897:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f010089a:	68 b8 67 10 f0       	push   $0xf01067b8
f010089f:	e8 b8 2e 00 00       	call   f010375c <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01008a4:	c7 04 24 dc 67 10 f0 	movl   $0xf01067dc,(%esp)
f01008ab:	e8 ac 2e 00 00       	call   f010375c <cprintf>

	if (tf != NULL)
f01008b0:	83 c4 10             	add    $0x10,%esp
f01008b3:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f01008b7:	74 0e                	je     f01008c7 <monitor+0x36>
		print_trapframe(tf);
f01008b9:	83 ec 0c             	sub    $0xc,%esp
f01008bc:	ff 75 08             	pushl  0x8(%ebp)
f01008bf:	e8 a0 34 00 00       	call   f0103d64 <print_trapframe>
f01008c4:	83 c4 10             	add    $0x10,%esp

	while (1) {
		buf = readline("K> ");
f01008c7:	83 ec 0c             	sub    $0xc,%esp
f01008ca:	68 6e 66 10 f0       	push   $0xf010666e
f01008cf:	e8 0e 4b 00 00       	call   f01053e2 <readline>
f01008d4:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f01008d6:	83 c4 10             	add    $0x10,%esp
f01008d9:	85 c0                	test   %eax,%eax
f01008db:	74 ea                	je     f01008c7 <monitor+0x36>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f01008dd:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f01008e4:	be 00 00 00 00       	mov    $0x0,%esi
f01008e9:	eb 0a                	jmp    f01008f5 <monitor+0x64>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f01008eb:	c6 03 00             	movb   $0x0,(%ebx)
f01008ee:	89 f7                	mov    %esi,%edi
f01008f0:	8d 5b 01             	lea    0x1(%ebx),%ebx
f01008f3:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f01008f5:	0f b6 03             	movzbl (%ebx),%eax
f01008f8:	84 c0                	test   %al,%al
f01008fa:	74 63                	je     f010095f <monitor+0xce>
f01008fc:	83 ec 08             	sub    $0x8,%esp
f01008ff:	0f be c0             	movsbl %al,%eax
f0100902:	50                   	push   %eax
f0100903:	68 72 66 10 f0       	push   $0xf0106672
f0100908:	e8 ef 4c 00 00       	call   f01055fc <strchr>
f010090d:	83 c4 10             	add    $0x10,%esp
f0100910:	85 c0                	test   %eax,%eax
f0100912:	75 d7                	jne    f01008eb <monitor+0x5a>
			*buf++ = 0;
		if (*buf == 0)
f0100914:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100917:	74 46                	je     f010095f <monitor+0xce>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100919:	83 fe 0f             	cmp    $0xf,%esi
f010091c:	75 14                	jne    f0100932 <monitor+0xa1>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f010091e:	83 ec 08             	sub    $0x8,%esp
f0100921:	6a 10                	push   $0x10
f0100923:	68 77 66 10 f0       	push   $0xf0106677
f0100928:	e8 2f 2e 00 00       	call   f010375c <cprintf>
f010092d:	83 c4 10             	add    $0x10,%esp
f0100930:	eb 95                	jmp    f01008c7 <monitor+0x36>
			return 0;
		}
		argv[argc++] = buf;
f0100932:	8d 7e 01             	lea    0x1(%esi),%edi
f0100935:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100939:	eb 03                	jmp    f010093e <monitor+0xad>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f010093b:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f010093e:	0f b6 03             	movzbl (%ebx),%eax
f0100941:	84 c0                	test   %al,%al
f0100943:	74 ae                	je     f01008f3 <monitor+0x62>
f0100945:	83 ec 08             	sub    $0x8,%esp
f0100948:	0f be c0             	movsbl %al,%eax
f010094b:	50                   	push   %eax
f010094c:	68 72 66 10 f0       	push   $0xf0106672
f0100951:	e8 a6 4c 00 00       	call   f01055fc <strchr>
f0100956:	83 c4 10             	add    $0x10,%esp
f0100959:	85 c0                	test   %eax,%eax
f010095b:	74 de                	je     f010093b <monitor+0xaa>
f010095d:	eb 94                	jmp    f01008f3 <monitor+0x62>
			buf++;
	}
	argv[argc] = 0;
f010095f:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100966:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100967:	85 f6                	test   %esi,%esi
f0100969:	0f 84 58 ff ff ff    	je     f01008c7 <monitor+0x36>
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f010096f:	83 ec 08             	sub    $0x8,%esp
f0100972:	68 3e 66 10 f0       	push   $0xf010663e
f0100977:	ff 75 a8             	pushl  -0x58(%ebp)
f010097a:	e8 1f 4c 00 00       	call   f010559e <strcmp>
f010097f:	83 c4 10             	add    $0x10,%esp
f0100982:	85 c0                	test   %eax,%eax
f0100984:	74 1e                	je     f01009a4 <monitor+0x113>
f0100986:	83 ec 08             	sub    $0x8,%esp
f0100989:	68 4c 66 10 f0       	push   $0xf010664c
f010098e:	ff 75 a8             	pushl  -0x58(%ebp)
f0100991:	e8 08 4c 00 00       	call   f010559e <strcmp>
f0100996:	83 c4 10             	add    $0x10,%esp
f0100999:	85 c0                	test   %eax,%eax
f010099b:	75 2f                	jne    f01009cc <monitor+0x13b>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f010099d:	b8 01 00 00 00       	mov    $0x1,%eax
f01009a2:	eb 05                	jmp    f01009a9 <monitor+0x118>
		if (strcmp(argv[0], commands[i].name) == 0)
f01009a4:	b8 00 00 00 00       	mov    $0x0,%eax
			return commands[i].func(argc, argv, tf);
f01009a9:	83 ec 04             	sub    $0x4,%esp
f01009ac:	8d 14 00             	lea    (%eax,%eax,1),%edx
f01009af:	01 d0                	add    %edx,%eax
f01009b1:	ff 75 08             	pushl  0x8(%ebp)
f01009b4:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f01009b7:	51                   	push   %ecx
f01009b8:	56                   	push   %esi
f01009b9:	ff 14 85 0c 68 10 f0 	call   *-0xfef97f4(,%eax,4)
		print_trapframe(tf);

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f01009c0:	83 c4 10             	add    $0x10,%esp
f01009c3:	85 c0                	test   %eax,%eax
f01009c5:	78 1d                	js     f01009e4 <monitor+0x153>
f01009c7:	e9 fb fe ff ff       	jmp    f01008c7 <monitor+0x36>
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f01009cc:	83 ec 08             	sub    $0x8,%esp
f01009cf:	ff 75 a8             	pushl  -0x58(%ebp)
f01009d2:	68 94 66 10 f0       	push   $0xf0106694
f01009d7:	e8 80 2d 00 00       	call   f010375c <cprintf>
f01009dc:	83 c4 10             	add    $0x10,%esp
f01009df:	e9 e3 fe ff ff       	jmp    f01008c7 <monitor+0x36>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f01009e4:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01009e7:	5b                   	pop    %ebx
f01009e8:	5e                   	pop    %esi
f01009e9:	5f                   	pop    %edi
f01009ea:	5d                   	pop    %ebp
f01009eb:	c3                   	ret    

f01009ec <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f01009ec:	55                   	push   %ebp
f01009ed:	89 e5                	mov    %esp,%ebp
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f01009ef:	83 3d 38 f2 22 f0 00 	cmpl   $0x0,0xf022f238
f01009f6:	75 11                	jne    f0100a09 <boot_alloc+0x1d>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f01009f8:	ba 07 20 27 f0       	mov    $0xf0272007,%edx
f01009fd:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100a03:	89 15 38 f2 22 f0    	mov    %edx,0xf022f238
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	if(n==0)
f0100a09:	85 c0                	test   %eax,%eax
f0100a0b:	75 07                	jne    f0100a14 <boot_alloc+0x28>
		return nextfree;
f0100a0d:	a1 38 f2 22 f0       	mov    0xf022f238,%eax
f0100a12:	eb 19                	jmp    f0100a2d <boot_alloc+0x41>
	result = nextfree;
f0100a14:	8b 15 38 f2 22 f0    	mov    0xf022f238,%edx
	nextfree += n;
	nextfree = ROUNDUP((char *) nextfree, PGSIZE);	
f0100a1a:	8d 84 02 ff 0f 00 00 	lea    0xfff(%edx,%eax,1),%eax
f0100a21:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100a26:	a3 38 f2 22 f0       	mov    %eax,0xf022f238
	
	// return the head address of the alloc pages;
	return result;
f0100a2b:	89 d0                	mov    %edx,%eax
}
f0100a2d:	5d                   	pop    %ebp
f0100a2e:	c3                   	ret    

f0100a2f <check_va2pa>:
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f0100a2f:	89 d1                	mov    %edx,%ecx
f0100a31:	c1 e9 16             	shr    $0x16,%ecx
f0100a34:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100a37:	a8 01                	test   $0x1,%al
f0100a39:	74 52                	je     f0100a8d <check_va2pa+0x5e>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100a3b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100a40:	89 c1                	mov    %eax,%ecx
f0100a42:	c1 e9 0c             	shr    $0xc,%ecx
f0100a45:	3b 0d 88 fe 22 f0    	cmp    0xf022fe88,%ecx
f0100a4b:	72 1b                	jb     f0100a68 <check_va2pa+0x39>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100a4d:	55                   	push   %ebp
f0100a4e:	89 e5                	mov    %esp,%ebp
f0100a50:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100a53:	50                   	push   %eax
f0100a54:	68 24 63 10 f0       	push   $0xf0106324
f0100a59:	68 b3 03 00 00       	push   $0x3b3
f0100a5e:	68 39 71 10 f0       	push   $0xf0107139
f0100a63:	e8 d8 f5 ff ff       	call   f0100040 <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f0100a68:	c1 ea 0c             	shr    $0xc,%edx
f0100a6b:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100a71:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100a78:	89 c2                	mov    %eax,%edx
f0100a7a:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100a7d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100a82:	85 d2                	test   %edx,%edx
f0100a84:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100a89:	0f 44 c2             	cmove  %edx,%eax
f0100a8c:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f0100a8d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f0100a92:	c3                   	ret    

f0100a93 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100a93:	55                   	push   %ebp
f0100a94:	89 e5                	mov    %esp,%ebp
f0100a96:	57                   	push   %edi
f0100a97:	56                   	push   %esi
f0100a98:	53                   	push   %ebx
f0100a99:	83 ec 2c             	sub    $0x2c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100a9c:	84 c0                	test   %al,%al
f0100a9e:	0f 85 91 02 00 00    	jne    f0100d35 <check_page_free_list+0x2a2>
f0100aa4:	e9 9e 02 00 00       	jmp    f0100d47 <check_page_free_list+0x2b4>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100aa9:	83 ec 04             	sub    $0x4,%esp
f0100aac:	68 1c 68 10 f0       	push   $0xf010681c
f0100ab1:	68 e8 02 00 00       	push   $0x2e8
f0100ab6:	68 39 71 10 f0       	push   $0xf0107139
f0100abb:	e8 80 f5 ff ff       	call   f0100040 <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100ac0:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100ac3:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100ac6:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100ac9:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100acc:	89 c2                	mov    %eax,%edx
f0100ace:	2b 15 90 fe 22 f0    	sub    0xf022fe90,%edx
f0100ad4:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100ada:	0f 95 c2             	setne  %dl
f0100add:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100ae0:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100ae4:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100ae6:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100aea:	8b 00                	mov    (%eax),%eax
f0100aec:	85 c0                	test   %eax,%eax
f0100aee:	75 dc                	jne    f0100acc <check_page_free_list+0x39>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100af0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100af3:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100af9:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100afc:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100aff:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100b01:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100b04:	a3 40 f2 22 f0       	mov    %eax,0xf022f240
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100b09:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100b0e:	8b 1d 40 f2 22 f0    	mov    0xf022f240,%ebx
f0100b14:	eb 53                	jmp    f0100b69 <check_page_free_list+0xd6>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100b16:	89 d8                	mov    %ebx,%eax
f0100b18:	2b 05 90 fe 22 f0    	sub    0xf022fe90,%eax
f0100b1e:	c1 f8 03             	sar    $0x3,%eax
f0100b21:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100b24:	89 c2                	mov    %eax,%edx
f0100b26:	c1 ea 16             	shr    $0x16,%edx
f0100b29:	39 f2                	cmp    %esi,%edx
f0100b2b:	73 3a                	jae    f0100b67 <check_page_free_list+0xd4>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100b2d:	89 c2                	mov    %eax,%edx
f0100b2f:	c1 ea 0c             	shr    $0xc,%edx
f0100b32:	3b 15 88 fe 22 f0    	cmp    0xf022fe88,%edx
f0100b38:	72 12                	jb     f0100b4c <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100b3a:	50                   	push   %eax
f0100b3b:	68 24 63 10 f0       	push   $0xf0106324
f0100b40:	6a 58                	push   $0x58
f0100b42:	68 45 71 10 f0       	push   $0xf0107145
f0100b47:	e8 f4 f4 ff ff       	call   f0100040 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100b4c:	83 ec 04             	sub    $0x4,%esp
f0100b4f:	68 80 00 00 00       	push   $0x80
f0100b54:	68 97 00 00 00       	push   $0x97
f0100b59:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100b5e:	50                   	push   %eax
f0100b5f:	e8 d5 4a 00 00       	call   f0105639 <memset>
f0100b64:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100b67:	8b 1b                	mov    (%ebx),%ebx
f0100b69:	85 db                	test   %ebx,%ebx
f0100b6b:	75 a9                	jne    f0100b16 <check_page_free_list+0x83>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100b6d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100b72:	e8 75 fe ff ff       	call   f01009ec <boot_alloc>
f0100b77:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b7a:	8b 15 40 f2 22 f0    	mov    0xf022f240,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100b80:	8b 0d 90 fe 22 f0    	mov    0xf022fe90,%ecx
		assert(pp < pages + npages);
f0100b86:	a1 88 fe 22 f0       	mov    0xf022fe88,%eax
f0100b8b:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100b8e:	8d 04 c1             	lea    (%ecx,%eax,8),%eax
f0100b91:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100b94:	89 4d d0             	mov    %ecx,-0x30(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100b97:	be 00 00 00 00       	mov    $0x0,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b9c:	e9 52 01 00 00       	jmp    f0100cf3 <check_page_free_list+0x260>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100ba1:	39 ca                	cmp    %ecx,%edx
f0100ba3:	73 19                	jae    f0100bbe <check_page_free_list+0x12b>
f0100ba5:	68 53 71 10 f0       	push   $0xf0107153
f0100baa:	68 5f 71 10 f0       	push   $0xf010715f
f0100baf:	68 02 03 00 00       	push   $0x302
f0100bb4:	68 39 71 10 f0       	push   $0xf0107139
f0100bb9:	e8 82 f4 ff ff       	call   f0100040 <_panic>
		assert(pp < pages + npages);
f0100bbe:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100bc1:	72 19                	jb     f0100bdc <check_page_free_list+0x149>
f0100bc3:	68 74 71 10 f0       	push   $0xf0107174
f0100bc8:	68 5f 71 10 f0       	push   $0xf010715f
f0100bcd:	68 03 03 00 00       	push   $0x303
f0100bd2:	68 39 71 10 f0       	push   $0xf0107139
f0100bd7:	e8 64 f4 ff ff       	call   f0100040 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100bdc:	89 d0                	mov    %edx,%eax
f0100bde:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0100be1:	a8 07                	test   $0x7,%al
f0100be3:	74 19                	je     f0100bfe <check_page_free_list+0x16b>
f0100be5:	68 40 68 10 f0       	push   $0xf0106840
f0100bea:	68 5f 71 10 f0       	push   $0xf010715f
f0100bef:	68 04 03 00 00       	push   $0x304
f0100bf4:	68 39 71 10 f0       	push   $0xf0107139
f0100bf9:	e8 42 f4 ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100bfe:	c1 f8 03             	sar    $0x3,%eax
f0100c01:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100c04:	85 c0                	test   %eax,%eax
f0100c06:	75 19                	jne    f0100c21 <check_page_free_list+0x18e>
f0100c08:	68 88 71 10 f0       	push   $0xf0107188
f0100c0d:	68 5f 71 10 f0       	push   $0xf010715f
f0100c12:	68 07 03 00 00       	push   $0x307
f0100c17:	68 39 71 10 f0       	push   $0xf0107139
f0100c1c:	e8 1f f4 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100c21:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100c26:	75 19                	jne    f0100c41 <check_page_free_list+0x1ae>
f0100c28:	68 99 71 10 f0       	push   $0xf0107199
f0100c2d:	68 5f 71 10 f0       	push   $0xf010715f
f0100c32:	68 08 03 00 00       	push   $0x308
f0100c37:	68 39 71 10 f0       	push   $0xf0107139
f0100c3c:	e8 ff f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100c41:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100c46:	75 19                	jne    f0100c61 <check_page_free_list+0x1ce>
f0100c48:	68 74 68 10 f0       	push   $0xf0106874
f0100c4d:	68 5f 71 10 f0       	push   $0xf010715f
f0100c52:	68 09 03 00 00       	push   $0x309
f0100c57:	68 39 71 10 f0       	push   $0xf0107139
f0100c5c:	e8 df f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100c61:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100c66:	75 19                	jne    f0100c81 <check_page_free_list+0x1ee>
f0100c68:	68 b2 71 10 f0       	push   $0xf01071b2
f0100c6d:	68 5f 71 10 f0       	push   $0xf010715f
f0100c72:	68 0a 03 00 00       	push   $0x30a
f0100c77:	68 39 71 10 f0       	push   $0xf0107139
f0100c7c:	e8 bf f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100c81:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100c86:	0f 86 de 00 00 00    	jbe    f0100d6a <check_page_free_list+0x2d7>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100c8c:	89 c7                	mov    %eax,%edi
f0100c8e:	c1 ef 0c             	shr    $0xc,%edi
f0100c91:	39 7d c8             	cmp    %edi,-0x38(%ebp)
f0100c94:	77 12                	ja     f0100ca8 <check_page_free_list+0x215>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100c96:	50                   	push   %eax
f0100c97:	68 24 63 10 f0       	push   $0xf0106324
f0100c9c:	6a 58                	push   $0x58
f0100c9e:	68 45 71 10 f0       	push   $0xf0107145
f0100ca3:	e8 98 f3 ff ff       	call   f0100040 <_panic>
f0100ca8:	8d b8 00 00 00 f0    	lea    -0x10000000(%eax),%edi
f0100cae:	39 7d cc             	cmp    %edi,-0x34(%ebp)
f0100cb1:	0f 86 a7 00 00 00    	jbe    f0100d5e <check_page_free_list+0x2cb>
f0100cb7:	68 98 68 10 f0       	push   $0xf0106898
f0100cbc:	68 5f 71 10 f0       	push   $0xf010715f
f0100cc1:	68 0b 03 00 00       	push   $0x30b
f0100cc6:	68 39 71 10 f0       	push   $0xf0107139
f0100ccb:	e8 70 f3 ff ff       	call   f0100040 <_panic>
		// (new test for lab 4)
		assert(page2pa(pp) != MPENTRY_PADDR);
f0100cd0:	68 cc 71 10 f0       	push   $0xf01071cc
f0100cd5:	68 5f 71 10 f0       	push   $0xf010715f
f0100cda:	68 0d 03 00 00       	push   $0x30d
f0100cdf:	68 39 71 10 f0       	push   $0xf0107139
f0100ce4:	e8 57 f3 ff ff       	call   f0100040 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100ce9:	83 c6 01             	add    $0x1,%esi
f0100cec:	eb 03                	jmp    f0100cf1 <check_page_free_list+0x25e>
		else
			++nfree_extmem;
f0100cee:	83 c3 01             	add    $0x1,%ebx
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100cf1:	8b 12                	mov    (%edx),%edx
f0100cf3:	85 d2                	test   %edx,%edx
f0100cf5:	0f 85 a6 fe ff ff    	jne    f0100ba1 <check_page_free_list+0x10e>
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100cfb:	85 f6                	test   %esi,%esi
f0100cfd:	7f 19                	jg     f0100d18 <check_page_free_list+0x285>
f0100cff:	68 e9 71 10 f0       	push   $0xf01071e9
f0100d04:	68 5f 71 10 f0       	push   $0xf010715f
f0100d09:	68 15 03 00 00       	push   $0x315
f0100d0e:	68 39 71 10 f0       	push   $0xf0107139
f0100d13:	e8 28 f3 ff ff       	call   f0100040 <_panic>
	assert(nfree_extmem > 0);
f0100d18:	85 db                	test   %ebx,%ebx
f0100d1a:	7f 5e                	jg     f0100d7a <check_page_free_list+0x2e7>
f0100d1c:	68 fb 71 10 f0       	push   $0xf01071fb
f0100d21:	68 5f 71 10 f0       	push   $0xf010715f
f0100d26:	68 16 03 00 00       	push   $0x316
f0100d2b:	68 39 71 10 f0       	push   $0xf0107139
f0100d30:	e8 0b f3 ff ff       	call   f0100040 <_panic>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100d35:	a1 40 f2 22 f0       	mov    0xf022f240,%eax
f0100d3a:	85 c0                	test   %eax,%eax
f0100d3c:	0f 85 7e fd ff ff    	jne    f0100ac0 <check_page_free_list+0x2d>
f0100d42:	e9 62 fd ff ff       	jmp    f0100aa9 <check_page_free_list+0x16>
f0100d47:	83 3d 40 f2 22 f0 00 	cmpl   $0x0,0xf022f240
f0100d4e:	0f 84 55 fd ff ff    	je     f0100aa9 <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100d54:	be 00 04 00 00       	mov    $0x400,%esi
f0100d59:	e9 b0 fd ff ff       	jmp    f0100b0e <check_page_free_list+0x7b>
		assert(page2pa(pp) != IOPHYSMEM);
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
		assert(page2pa(pp) != EXTPHYSMEM);
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
		// (new test for lab 4)
		assert(page2pa(pp) != MPENTRY_PADDR);
f0100d5e:	3d 00 70 00 00       	cmp    $0x7000,%eax
f0100d63:	75 89                	jne    f0100cee <check_page_free_list+0x25b>
f0100d65:	e9 66 ff ff ff       	jmp    f0100cd0 <check_page_free_list+0x23d>
f0100d6a:	3d 00 70 00 00       	cmp    $0x7000,%eax
f0100d6f:	0f 85 74 ff ff ff    	jne    f0100ce9 <check_page_free_list+0x256>
f0100d75:	e9 56 ff ff ff       	jmp    f0100cd0 <check_page_free_list+0x23d>
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
}
f0100d7a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100d7d:	5b                   	pop    %ebx
f0100d7e:	5e                   	pop    %esi
f0100d7f:	5f                   	pop    %edi
f0100d80:	5d                   	pop    %ebp
f0100d81:	c3                   	ret    

f0100d82 <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100d82:	55                   	push   %ebp
f0100d83:	89 e5                	mov    %esp,%ebp
f0100d85:	56                   	push   %esi
f0100d86:	53                   	push   %ebx
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = 0; i < npages; i++) {
f0100d87:	be 00 00 00 00       	mov    $0x0,%esi
f0100d8c:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100d91:	e9 e1 00 00 00       	jmp    f0100e77 <page_init+0xf5>
		if(i == 0)
f0100d96:	85 db                	test   %ebx,%ebx
f0100d98:	75 16                	jne    f0100db0 <page_init+0x2e>
			{	pages[i].pp_ref = 1;
f0100d9a:	a1 90 fe 22 f0       	mov    0xf022fe90,%eax
f0100d9f:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
				pages[i].pp_link = NULL;
f0100da5:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f0100dab:	e9 c1 00 00 00       	jmp    f0100e71 <page_init+0xef>
			}
		else if(i == MPENTRY_PADDR/PGSIZE){
f0100db0:	83 fb 07             	cmp    $0x7,%ebx
f0100db3:	75 17                	jne    f0100dcc <page_init+0x4a>
				pages[i].pp_ref = 1;
f0100db5:	a1 90 fe 22 f0       	mov    0xf022fe90,%eax
f0100dba:	66 c7 40 3c 01 00    	movw   $0x1,0x3c(%eax)
				pages[i].pp_link = NULL;
f0100dc0:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)
f0100dc7:	e9 a5 00 00 00       	jmp    f0100e71 <page_init+0xef>
		}
		else if(i>=1 && i<npages_basemem)
f0100dcc:	3b 1d 44 f2 22 f0    	cmp    0xf022f244,%ebx
f0100dd2:	73 25                	jae    f0100df9 <page_init+0x77>
		{
			pages[i].pp_ref = 0;
f0100dd4:	89 f0                	mov    %esi,%eax
f0100dd6:	03 05 90 fe 22 f0    	add    0xf022fe90,%eax
f0100ddc:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
			pages[i].pp_link = page_free_list; 
f0100de2:	8b 15 40 f2 22 f0    	mov    0xf022f240,%edx
f0100de8:	89 10                	mov    %edx,(%eax)
			page_free_list = &pages[i];
f0100dea:	89 f0                	mov    %esi,%eax
f0100dec:	03 05 90 fe 22 f0    	add    0xf022fe90,%eax
f0100df2:	a3 40 f2 22 f0       	mov    %eax,0xf022f240
f0100df7:	eb 78                	jmp    f0100e71 <page_init+0xef>
		}
		else if(i>=IOPHYSMEM/PGSIZE && i< EXTPHYSMEM/PGSIZE )
f0100df9:	8d 83 60 ff ff ff    	lea    -0xa0(%ebx),%eax
f0100dff:	83 f8 5f             	cmp    $0x5f,%eax
f0100e02:	77 16                	ja     f0100e1a <page_init+0x98>
		{
			pages[i].pp_ref = 1;
f0100e04:	89 f0                	mov    %esi,%eax
f0100e06:	03 05 90 fe 22 f0    	add    0xf022fe90,%eax
f0100e0c:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
			pages[i].pp_link = NULL;
f0100e12:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f0100e18:	eb 57                	jmp    f0100e71 <page_init+0xef>
		}
	
		else if( i >= EXTPHYSMEM / PGSIZE && 
f0100e1a:	81 fb ff 00 00 00    	cmp    $0xff,%ebx
f0100e20:	76 2c                	jbe    f0100e4e <page_init+0xcc>
				i < ( (int)(boot_alloc(0)) - KERNBASE)/PGSIZE)
f0100e22:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e27:	e8 c0 fb ff ff       	call   f01009ec <boot_alloc>
		{
			pages[i].pp_ref = 1;
			pages[i].pp_link = NULL;
		}
	
		else if( i >= EXTPHYSMEM / PGSIZE && 
f0100e2c:	05 00 00 00 10       	add    $0x10000000,%eax
f0100e31:	c1 e8 0c             	shr    $0xc,%eax
f0100e34:	39 c3                	cmp    %eax,%ebx
f0100e36:	73 16                	jae    f0100e4e <page_init+0xcc>
				i < ( (int)(boot_alloc(0)) - KERNBASE)/PGSIZE)
		{
			pages[i].pp_ref = 1;
f0100e38:	89 f0                	mov    %esi,%eax
f0100e3a:	03 05 90 fe 22 f0    	add    0xf022fe90,%eax
f0100e40:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
			pages[i].pp_link =NULL;
f0100e46:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f0100e4c:	eb 23                	jmp    f0100e71 <page_init+0xef>
		}
		else
		{
			pages[i].pp_ref = 0;
f0100e4e:	89 f0                	mov    %esi,%eax
f0100e50:	03 05 90 fe 22 f0    	add    0xf022fe90,%eax
f0100e56:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
			pages[i].pp_link = page_free_list;
f0100e5c:	8b 15 40 f2 22 f0    	mov    0xf022f240,%edx
f0100e62:	89 10                	mov    %edx,(%eax)
			page_free_list = &pages[i];
f0100e64:	89 f0                	mov    %esi,%eax
f0100e66:	03 05 90 fe 22 f0    	add    0xf022fe90,%eax
f0100e6c:	a3 40 f2 22 f0       	mov    %eax,0xf022f240
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = 0; i < npages; i++) {
f0100e71:	83 c3 01             	add    $0x1,%ebx
f0100e74:	83 c6 08             	add    $0x8,%esi
f0100e77:	3b 1d 88 fe 22 f0    	cmp    0xf022fe88,%ebx
f0100e7d:	0f 82 13 ff ff ff    	jb     f0100d96 <page_init+0x14>
			page_free_list = &pages[i];
		}

	}

}
f0100e83:	5b                   	pop    %ebx
f0100e84:	5e                   	pop    %esi
f0100e85:	5d                   	pop    %ebp
f0100e86:	c3                   	ret    

f0100e87 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100e87:	55                   	push   %ebp
f0100e88:	89 e5                	mov    %esp,%ebp
f0100e8a:	53                   	push   %ebx
f0100e8b:	83 ec 04             	sub    $0x4,%esp
	// Fill this function in
	if(page_free_list == NULL)
f0100e8e:	8b 1d 40 f2 22 f0    	mov    0xf022f240,%ebx
f0100e94:	85 db                	test   %ebx,%ebx
f0100e96:	74 58                	je     f0100ef0 <page_alloc+0x69>
		return NULL;

	struct PageInfo* page = page_free_list;
	page_free_list = page->pp_link;
f0100e98:	8b 03                	mov    (%ebx),%eax
f0100e9a:	a3 40 f2 22 f0       	mov    %eax,0xf022f240
	page->pp_link = 0;
f0100e9f:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	if(alloc_flags & ALLOC_ZERO)
f0100ea5:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100ea9:	74 45                	je     f0100ef0 <page_alloc+0x69>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100eab:	89 d8                	mov    %ebx,%eax
f0100ead:	2b 05 90 fe 22 f0    	sub    0xf022fe90,%eax
f0100eb3:	c1 f8 03             	sar    $0x3,%eax
f0100eb6:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100eb9:	89 c2                	mov    %eax,%edx
f0100ebb:	c1 ea 0c             	shr    $0xc,%edx
f0100ebe:	3b 15 88 fe 22 f0    	cmp    0xf022fe88,%edx
f0100ec4:	72 12                	jb     f0100ed8 <page_alloc+0x51>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ec6:	50                   	push   %eax
f0100ec7:	68 24 63 10 f0       	push   $0xf0106324
f0100ecc:	6a 58                	push   $0x58
f0100ece:	68 45 71 10 f0       	push   $0xf0107145
f0100ed3:	e8 68 f1 ff ff       	call   f0100040 <_panic>
		memset(page2kva(page), 0, PGSIZE);
f0100ed8:	83 ec 04             	sub    $0x4,%esp
f0100edb:	68 00 10 00 00       	push   $0x1000
f0100ee0:	6a 00                	push   $0x0
f0100ee2:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100ee7:	50                   	push   %eax
f0100ee8:	e8 4c 47 00 00       	call   f0105639 <memset>
f0100eed:	83 c4 10             	add    $0x10,%esp
	return page;
	return 0;
}
f0100ef0:	89 d8                	mov    %ebx,%eax
f0100ef2:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100ef5:	c9                   	leave  
f0100ef6:	c3                   	ret    

f0100ef7 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100ef7:	55                   	push   %ebp
f0100ef8:	89 e5                	mov    %esp,%ebp
f0100efa:	83 ec 08             	sub    $0x8,%esp
f0100efd:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
	if(pp->pp_link != 0  || pp->pp_ref != 0)
f0100f00:	83 38 00             	cmpl   $0x0,(%eax)
f0100f03:	75 07                	jne    f0100f0c <page_free+0x15>
f0100f05:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100f0a:	74 17                	je     f0100f23 <page_free+0x2c>
		panic("page_free is not right");
f0100f0c:	83 ec 04             	sub    $0x4,%esp
f0100f0f:	68 0c 72 10 f0       	push   $0xf010720c
f0100f14:	68 9b 01 00 00       	push   $0x19b
f0100f19:	68 39 71 10 f0       	push   $0xf0107139
f0100f1e:	e8 1d f1 ff ff       	call   f0100040 <_panic>
	pp->pp_link = page_free_list;
f0100f23:	8b 15 40 f2 22 f0    	mov    0xf022f240,%edx
f0100f29:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0100f2b:	a3 40 f2 22 f0       	mov    %eax,0xf022f240
	return; 
}
f0100f30:	c9                   	leave  
f0100f31:	c3                   	ret    

f0100f32 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100f32:	55                   	push   %ebp
f0100f33:	89 e5                	mov    %esp,%ebp
f0100f35:	83 ec 08             	sub    $0x8,%esp
f0100f38:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0100f3b:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0100f3f:	83 e8 01             	sub    $0x1,%eax
f0100f42:	66 89 42 04          	mov    %ax,0x4(%edx)
f0100f46:	66 85 c0             	test   %ax,%ax
f0100f49:	75 0c                	jne    f0100f57 <page_decref+0x25>
		page_free(pp);
f0100f4b:	83 ec 0c             	sub    $0xc,%esp
f0100f4e:	52                   	push   %edx
f0100f4f:	e8 a3 ff ff ff       	call   f0100ef7 <page_free>
f0100f54:	83 c4 10             	add    $0x10,%esp
}
f0100f57:	c9                   	leave  
f0100f58:	c3                   	ret    

f0100f59 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100f59:	55                   	push   %ebp
f0100f5a:	89 e5                	mov    %esp,%ebp
f0100f5c:	56                   	push   %esi
f0100f5d:	53                   	push   %ebx
f0100f5e:	8b 75 0c             	mov    0xc(%ebp),%esi
	// Fill this function in
	int pdeIndex = (unsigned int)va >>22;
	if(pgdir[pdeIndex] == 0 && create == 0)
f0100f61:	89 f3                	mov    %esi,%ebx
f0100f63:	c1 eb 16             	shr    $0x16,%ebx
f0100f66:	c1 e3 02             	shl    $0x2,%ebx
f0100f69:	03 5d 08             	add    0x8(%ebp),%ebx
f0100f6c:	8b 03                	mov    (%ebx),%eax
f0100f6e:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100f72:	75 04                	jne    f0100f78 <pgdir_walk+0x1f>
f0100f74:	85 c0                	test   %eax,%eax
f0100f76:	74 66                	je     f0100fde <pgdir_walk+0x85>
		return NULL;
	if(pgdir[pdeIndex] == 0){
f0100f78:	85 c0                	test   %eax,%eax
f0100f7a:	75 27                	jne    f0100fa3 <pgdir_walk+0x4a>
		struct PageInfo* page = page_alloc(1);
f0100f7c:	83 ec 0c             	sub    $0xc,%esp
f0100f7f:	6a 01                	push   $0x1
f0100f81:	e8 01 ff ff ff       	call   f0100e87 <page_alloc>
		if(page == NULL)
f0100f86:	83 c4 10             	add    $0x10,%esp
f0100f89:	85 c0                	test   %eax,%eax
f0100f8b:	74 58                	je     f0100fe5 <pgdir_walk+0x8c>
			return NULL;
		page->pp_ref++;
f0100f8d:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
		pte_t pgAddress = page2pa(page);
		pgAddress |= PTE_U;
		pgAddress |= PTE_P;
		pgAddress |= PTE_W;
		pgdir[pdeIndex] = pgAddress;
f0100f92:	2b 05 90 fe 22 f0    	sub    0xf022fe90,%eax
f0100f98:	c1 f8 03             	sar    $0x3,%eax
f0100f9b:	c1 e0 0c             	shl    $0xc,%eax
f0100f9e:	83 c8 07             	or     $0x7,%eax
f0100fa1:	89 03                	mov    %eax,(%ebx)
	}
	pte_t pgAdd = pgdir[pdeIndex];
f0100fa3:	8b 03                	mov    (%ebx),%eax
	pgAdd = pgAdd & (~0x3ff);
f0100fa5:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	int pteIndex =(pte_t)va >>12 & 0x3ff;
f0100faa:	c1 ee 0c             	shr    $0xc,%esi
f0100fad:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100fb3:	89 c2                	mov    %eax,%edx
f0100fb5:	c1 ea 0c             	shr    $0xc,%edx
f0100fb8:	3b 15 88 fe 22 f0    	cmp    0xf022fe88,%edx
f0100fbe:	72 15                	jb     f0100fd5 <pgdir_walk+0x7c>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100fc0:	50                   	push   %eax
f0100fc1:	68 24 63 10 f0       	push   $0xf0106324
f0100fc6:	68 d7 01 00 00       	push   $0x1d7
f0100fcb:	68 39 71 10 f0       	push   $0xf0107139
f0100fd0:	e8 6b f0 ff ff       	call   f0100040 <_panic>
	pte_t* pte = (pte_t *)KADDR(pgAdd) + pteIndex;
	return pte;
f0100fd5:	8d 84 b0 00 00 00 f0 	lea    -0x10000000(%eax,%esi,4),%eax
f0100fdc:	eb 0c                	jmp    f0100fea <pgdir_walk+0x91>
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
	// Fill this function in
	int pdeIndex = (unsigned int)va >>22;
	if(pgdir[pdeIndex] == 0 && create == 0)
		return NULL;
f0100fde:	b8 00 00 00 00       	mov    $0x0,%eax
f0100fe3:	eb 05                	jmp    f0100fea <pgdir_walk+0x91>
	if(pgdir[pdeIndex] == 0){
		struct PageInfo* page = page_alloc(1);
		if(page == NULL)
			return NULL;
f0100fe5:	b8 00 00 00 00       	mov    $0x0,%eax
	pte_t pgAdd = pgdir[pdeIndex];
	pgAdd = pgAdd & (~0x3ff);
	int pteIndex =(pte_t)va >>12 & 0x3ff;
	pte_t* pte = (pte_t *)KADDR(pgAdd) + pteIndex;
	return pte;
}
f0100fea:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100fed:	5b                   	pop    %ebx
f0100fee:	5e                   	pop    %esi
f0100fef:	5d                   	pop    %ebp
f0100ff0:	c3                   	ret    

f0100ff1 <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0100ff1:	55                   	push   %ebp
f0100ff2:	89 e5                	mov    %esp,%ebp
f0100ff4:	57                   	push   %edi
f0100ff5:	56                   	push   %esi
f0100ff6:	53                   	push   %ebx
f0100ff7:	83 ec 1c             	sub    $0x1c,%esp
f0100ffa:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100ffd:	89 cf                	mov    %ecx,%edi
	// Fill this function in
	while(size)
f0100fff:	89 d3                	mov    %edx,%ebx
f0101001:	8b 45 08             	mov    0x8(%ebp),%eax
f0101004:	29 d0                	sub    %edx,%eax
f0101006:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	{
		pte_t* pte = pgdir_walk(pgdir, (void* )va, 1);
		if(pte == NULL)
			return;
		*pte= pa |perm|PTE_P;
f0101009:	8b 45 0c             	mov    0xc(%ebp),%eax
f010100c:	83 c8 01             	or     $0x1,%eax
f010100f:	89 45 dc             	mov    %eax,-0x24(%ebp)
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	while(size)
f0101012:	eb 26                	jmp    f010103a <boot_map_region+0x49>
	{
		pte_t* pte = pgdir_walk(pgdir, (void* )va, 1);
f0101014:	83 ec 04             	sub    $0x4,%esp
f0101017:	6a 01                	push   $0x1
f0101019:	53                   	push   %ebx
f010101a:	ff 75 e0             	pushl  -0x20(%ebp)
f010101d:	e8 37 ff ff ff       	call   f0100f59 <pgdir_walk>
		if(pte == NULL)
f0101022:	83 c4 10             	add    $0x10,%esp
f0101025:	85 c0                	test   %eax,%eax
f0101027:	74 1b                	je     f0101044 <boot_map_region+0x53>
			return;
		*pte= pa |perm|PTE_P;
f0101029:	0b 75 dc             	or     -0x24(%ebp),%esi
f010102c:	89 30                	mov    %esi,(%eax)
		
		size -= PGSIZE;
f010102e:	81 ef 00 10 00 00    	sub    $0x1000,%edi
		pa  += PGSIZE;
		va  += PGSIZE;
f0101034:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f010103a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010103d:	8d 34 18             	lea    (%eax,%ebx,1),%esi
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	while(size)
f0101040:	85 ff                	test   %edi,%edi
f0101042:	75 d0                	jne    f0101014 <boot_map_region+0x23>
		
		size -= PGSIZE;
		pa  += PGSIZE;
		va  += PGSIZE;
	}
}
f0101044:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101047:	5b                   	pop    %ebx
f0101048:	5e                   	pop    %esi
f0101049:	5f                   	pop    %edi
f010104a:	5d                   	pop    %ebp
f010104b:	c3                   	ret    

f010104c <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f010104c:	55                   	push   %ebp
f010104d:	89 e5                	mov    %esp,%ebp
f010104f:	53                   	push   %ebx
f0101050:	83 ec 08             	sub    $0x8,%esp
f0101053:	8b 5d 10             	mov    0x10(%ebp),%ebx
	pte_t* pte = pgdir_walk(pgdir, va, 0);
f0101056:	6a 00                	push   $0x0
f0101058:	ff 75 0c             	pushl  0xc(%ebp)
f010105b:	ff 75 08             	pushl  0x8(%ebp)
f010105e:	e8 f6 fe ff ff       	call   f0100f59 <pgdir_walk>
	if(pte == NULL)
f0101063:	83 c4 10             	add    $0x10,%esp
f0101066:	85 c0                	test   %eax,%eax
f0101068:	74 3a                	je     f01010a4 <page_lookup+0x58>
		return NULL;
	pte_t pa =  *pte>>12<<12;
f010106a:	8b 10                	mov    (%eax),%edx
f010106c:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	if(pte_store != 0)
f0101072:	85 db                	test   %ebx,%ebx
f0101074:	74 02                	je     f0101078 <page_lookup+0x2c>
		*pte_store = pte ;
f0101076:	89 03                	mov    %eax,(%ebx)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101078:	89 d0                	mov    %edx,%eax
f010107a:	c1 e8 0c             	shr    $0xc,%eax
f010107d:	3b 05 88 fe 22 f0    	cmp    0xf022fe88,%eax
f0101083:	72 14                	jb     f0101099 <page_lookup+0x4d>
		panic("pa2page called with invalid pa");
f0101085:	83 ec 04             	sub    $0x4,%esp
f0101088:	68 e0 68 10 f0       	push   $0xf01068e0
f010108d:	6a 51                	push   $0x51
f010108f:	68 45 71 10 f0       	push   $0xf0107145
f0101094:	e8 a7 ef ff ff       	call   f0100040 <_panic>
	return &pages[PGNUM(pa)];
f0101099:	8b 15 90 fe 22 f0    	mov    0xf022fe90,%edx
f010109f:	8d 04 c2             	lea    (%edx,%eax,8),%eax
	return pa2page(pa);	
f01010a2:	eb 05                	jmp    f01010a9 <page_lookup+0x5d>
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	pte_t* pte = pgdir_walk(pgdir, va, 0);
	if(pte == NULL)
		return NULL;
f01010a4:	b8 00 00 00 00       	mov    $0x0,%eax
	pte_t pa =  *pte>>12<<12;
	if(pte_store != 0)
		*pte_store = pte ;
	return pa2page(pa);	
}
f01010a9:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01010ac:	c9                   	leave  
f01010ad:	c3                   	ret    

f01010ae <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f01010ae:	55                   	push   %ebp
f01010af:	89 e5                	mov    %esp,%ebp
f01010b1:	83 ec 08             	sub    $0x8,%esp
	// Flush the entry only if we're modifying the current address space.
	if (!curenv || curenv->env_pgdir == pgdir)
f01010b4:	e8 a1 4b 00 00       	call   f0105c5a <cpunum>
f01010b9:	6b c0 74             	imul   $0x74,%eax,%eax
f01010bc:	83 b8 28 00 23 f0 00 	cmpl   $0x0,-0xfdcffd8(%eax)
f01010c3:	74 16                	je     f01010db <tlb_invalidate+0x2d>
f01010c5:	e8 90 4b 00 00       	call   f0105c5a <cpunum>
f01010ca:	6b c0 74             	imul   $0x74,%eax,%eax
f01010cd:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f01010d3:	8b 55 08             	mov    0x8(%ebp),%edx
f01010d6:	39 50 60             	cmp    %edx,0x60(%eax)
f01010d9:	75 06                	jne    f01010e1 <tlb_invalidate+0x33>
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01010db:	8b 45 0c             	mov    0xc(%ebp),%eax
f01010de:	0f 01 38             	invlpg (%eax)
		invlpg(va);
}
f01010e1:	c9                   	leave  
f01010e2:	c3                   	ret    

f01010e3 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f01010e3:	55                   	push   %ebp
f01010e4:	89 e5                	mov    %esp,%ebp
f01010e6:	56                   	push   %esi
f01010e7:	53                   	push   %ebx
f01010e8:	83 ec 14             	sub    $0x14,%esp
f01010eb:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01010ee:	8b 75 0c             	mov    0xc(%ebp),%esi
	// Fill this function in
	pte_t* pte;
	struct PageInfo* page = page_lookup(pgdir, va, &pte);
f01010f1:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01010f4:	50                   	push   %eax
f01010f5:	56                   	push   %esi
f01010f6:	53                   	push   %ebx
f01010f7:	e8 50 ff ff ff       	call   f010104c <page_lookup>
	if(page == 0)
f01010fc:	83 c4 10             	add    $0x10,%esp
f01010ff:	85 c0                	test   %eax,%eax
f0101101:	74 32                	je     f0101135 <page_remove+0x52>
		return;
	*pte = 0;
f0101103:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0101106:	c7 02 00 00 00 00    	movl   $0x0,(%edx)
	page->pp_ref--;
f010110c:	0f b7 48 04          	movzwl 0x4(%eax),%ecx
f0101110:	8d 51 ff             	lea    -0x1(%ecx),%edx
f0101113:	66 89 50 04          	mov    %dx,0x4(%eax)
	if(page->pp_ref ==0)
f0101117:	66 85 d2             	test   %dx,%dx
f010111a:	75 0c                	jne    f0101128 <page_remove+0x45>
		page_free(page);
f010111c:	83 ec 0c             	sub    $0xc,%esp
f010111f:	50                   	push   %eax
f0101120:	e8 d2 fd ff ff       	call   f0100ef7 <page_free>
f0101125:	83 c4 10             	add    $0x10,%esp
	tlb_invalidate(pgdir, va);
f0101128:	83 ec 08             	sub    $0x8,%esp
f010112b:	56                   	push   %esi
f010112c:	53                   	push   %ebx
f010112d:	e8 7c ff ff ff       	call   f01010ae <tlb_invalidate>
f0101132:	83 c4 10             	add    $0x10,%esp
}
f0101135:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0101138:	5b                   	pop    %ebx
f0101139:	5e                   	pop    %esi
f010113a:	5d                   	pop    %ebp
f010113b:	c3                   	ret    

f010113c <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f010113c:	55                   	push   %ebp
f010113d:	89 e5                	mov    %esp,%ebp
f010113f:	57                   	push   %edi
f0101140:	56                   	push   %esi
f0101141:	53                   	push   %ebx
f0101142:	83 ec 10             	sub    $0x10,%esp
f0101145:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101148:	8b 7d 10             	mov    0x10(%ebp),%edi
	pte_t* pte = pgdir_walk(pgdir, va, 1);
f010114b:	6a 01                	push   $0x1
f010114d:	57                   	push   %edi
f010114e:	ff 75 08             	pushl  0x8(%ebp)
f0101151:	e8 03 fe ff ff       	call   f0100f59 <pgdir_walk>
	if(pte == NULL)
f0101156:	83 c4 10             	add    $0x10,%esp
f0101159:	85 c0                	test   %eax,%eax
f010115b:	74 5c                	je     f01011b9 <page_insert+0x7d>
f010115d:	89 c6                	mov    %eax,%esi
		return -E_NO_MEM;
	if( (pte[0] &  ~0xfff) == page2pa(pp))
f010115f:	8b 10                	mov    (%eax),%edx
f0101161:	89 d1                	mov    %edx,%ecx
f0101163:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0101169:	89 d8                	mov    %ebx,%eax
f010116b:	2b 05 90 fe 22 f0    	sub    0xf022fe90,%eax
f0101171:	c1 f8 03             	sar    $0x3,%eax
f0101174:	c1 e0 0c             	shl    $0xc,%eax
f0101177:	39 c1                	cmp    %eax,%ecx
f0101179:	75 07                	jne    f0101182 <page_insert+0x46>
		pp->pp_ref--;
f010117b:	66 83 6b 04 01       	subw   $0x1,0x4(%ebx)
f0101180:	eb 13                	jmp    f0101195 <page_insert+0x59>
	
	else if(*pte != 0)
f0101182:	85 d2                	test   %edx,%edx
f0101184:	74 0f                	je     f0101195 <page_insert+0x59>
		page_remove(pgdir, va);
f0101186:	83 ec 08             	sub    $0x8,%esp
f0101189:	57                   	push   %edi
f010118a:	ff 75 08             	pushl  0x8(%ebp)
f010118d:	e8 51 ff ff ff       	call   f01010e3 <page_remove>
f0101192:	83 c4 10             	add    $0x10,%esp

	*pte = (page2pa(pp) & ~0xfff) | perm | PTE_P;
f0101195:	89 d8                	mov    %ebx,%eax
f0101197:	2b 05 90 fe 22 f0    	sub    0xf022fe90,%eax
f010119d:	c1 f8 03             	sar    $0x3,%eax
f01011a0:	c1 e0 0c             	shl    $0xc,%eax
f01011a3:	8b 55 14             	mov    0x14(%ebp),%edx
f01011a6:	83 ca 01             	or     $0x1,%edx
f01011a9:	09 d0                	or     %edx,%eax
f01011ab:	89 06                	mov    %eax,(%esi)
	pp->pp_ref++;
f01011ad:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
	return 0;
f01011b2:	b8 00 00 00 00       	mov    $0x0,%eax
f01011b7:	eb 05                	jmp    f01011be <page_insert+0x82>
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
	pte_t* pte = pgdir_walk(pgdir, va, 1);
	if(pte == NULL)
		return -E_NO_MEM;
f01011b9:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
		page_remove(pgdir, va);

	*pte = (page2pa(pp) & ~0xfff) | perm | PTE_P;
	pp->pp_ref++;
	return 0;
}
f01011be:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01011c1:	5b                   	pop    %ebx
f01011c2:	5e                   	pop    %esi
f01011c3:	5f                   	pop    %edi
f01011c4:	5d                   	pop    %ebp
f01011c5:	c3                   	ret    

f01011c6 <mmio_map_region>:
// location.  Return the base of the reserved region.  size does *not*
// have to be multiple of PGSIZE.
//
void *
mmio_map_region(physaddr_t pa, size_t size)
{
f01011c6:	55                   	push   %ebp
f01011c7:	89 e5                	mov    %esp,%ebp
f01011c9:	53                   	push   %ebx
f01011ca:	83 ec 04             	sub    $0x4,%esp
	// okay to simply panic if this happens).
	//
	// Hint: The staff solution uses boot_map_region.
	//
	// Your code here:
	size = ROUNDUP(size, PGSIZE);
f01011cd:	8b 45 0c             	mov    0xc(%ebp),%eax
f01011d0:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
f01011d6:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	pa = ROUNDDOWN(pa, PGSIZE);
f01011dc:	8b 45 08             	mov    0x8(%ebp),%eax
f01011df:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	if(size + base >= MMIOLIM)
f01011e4:	8b 15 00 03 12 f0    	mov    0xf0120300,%edx
f01011ea:	8d 0c 13             	lea    (%ebx,%edx,1),%ecx
f01011ed:	81 f9 ff ff bf ef    	cmp    $0xefbfffff,%ecx
f01011f3:	76 17                	jbe    f010120c <mmio_map_region+0x46>
		panic("mmio_map_region not implemented");
f01011f5:	83 ec 04             	sub    $0x4,%esp
f01011f8:	68 00 69 10 f0       	push   $0xf0106900
f01011fd:	68 85 02 00 00       	push   $0x285
f0101202:	68 39 71 10 f0       	push   $0xf0107139
f0101207:	e8 34 ee ff ff       	call   f0100040 <_panic>
	boot_map_region(kern_pgdir, base, size, pa, PTE_PCD|PTE_PWT|PTE_W);
f010120c:	83 ec 08             	sub    $0x8,%esp
f010120f:	6a 1a                	push   $0x1a
f0101211:	50                   	push   %eax
f0101212:	89 d9                	mov    %ebx,%ecx
f0101214:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
f0101219:	e8 d3 fd ff ff       	call   f0100ff1 <boot_map_region>
	uintptr_t ret = base;
f010121e:	a1 00 03 12 f0       	mov    0xf0120300,%eax
	base = base +size;
f0101223:	01 c3                	add    %eax,%ebx
f0101225:	89 1d 00 03 12 f0    	mov    %ebx,0xf0120300
	return (void*) ret;

}
f010122b:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010122e:	c9                   	leave  
f010122f:	c3                   	ret    

f0101230 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0101230:	55                   	push   %ebp
f0101231:	89 e5                	mov    %esp,%ebp
f0101233:	57                   	push   %edi
f0101234:	56                   	push   %esi
f0101235:	53                   	push   %ebx
f0101236:	83 ec 48             	sub    $0x48,%esp
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0101239:	6a 15                	push   $0x15
f010123b:	e8 9d 23 00 00       	call   f01035dd <mc146818_read>
f0101240:	89 c3                	mov    %eax,%ebx
f0101242:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f0101249:	e8 8f 23 00 00       	call   f01035dd <mc146818_read>
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f010124e:	c1 e0 08             	shl    $0x8,%eax
f0101251:	09 d8                	or     %ebx,%eax
f0101253:	c1 e0 0a             	shl    $0xa,%eax
f0101256:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f010125c:	85 c0                	test   %eax,%eax
f010125e:	0f 48 c2             	cmovs  %edx,%eax
f0101261:	c1 f8 0c             	sar    $0xc,%eax
f0101264:	a3 44 f2 22 f0       	mov    %eax,0xf022f244
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0101269:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f0101270:	e8 68 23 00 00       	call   f01035dd <mc146818_read>
f0101275:	89 c3                	mov    %eax,%ebx
f0101277:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f010127e:	e8 5a 23 00 00       	call   f01035dd <mc146818_read>
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f0101283:	c1 e0 08             	shl    $0x8,%eax
f0101286:	09 d8                	or     %ebx,%eax
f0101288:	c1 e0 0a             	shl    $0xa,%eax
f010128b:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101291:	83 c4 10             	add    $0x10,%esp
f0101294:	85 c0                	test   %eax,%eax
f0101296:	0f 48 c2             	cmovs  %edx,%eax
f0101299:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f010129c:	85 c0                	test   %eax,%eax
f010129e:	74 0e                	je     f01012ae <mem_init+0x7e>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f01012a0:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f01012a6:	89 15 88 fe 22 f0    	mov    %edx,0xf022fe88
f01012ac:	eb 0c                	jmp    f01012ba <mem_init+0x8a>
	else
		npages = npages_basemem;
f01012ae:	8b 15 44 f2 22 f0    	mov    0xf022f244,%edx
f01012b4:	89 15 88 fe 22 f0    	mov    %edx,0xf022fe88

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01012ba:	c1 e0 0c             	shl    $0xc,%eax
f01012bd:	c1 e8 0a             	shr    $0xa,%eax
f01012c0:	50                   	push   %eax
f01012c1:	a1 44 f2 22 f0       	mov    0xf022f244,%eax
f01012c6:	c1 e0 0c             	shl    $0xc,%eax
f01012c9:	c1 e8 0a             	shr    $0xa,%eax
f01012cc:	50                   	push   %eax
f01012cd:	a1 88 fe 22 f0       	mov    0xf022fe88,%eax
f01012d2:	c1 e0 0c             	shl    $0xc,%eax
f01012d5:	c1 e8 0a             	shr    $0xa,%eax
f01012d8:	50                   	push   %eax
f01012d9:	68 20 69 10 f0       	push   $0xf0106920
f01012de:	e8 79 24 00 00       	call   f010375c <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f01012e3:	b8 00 10 00 00       	mov    $0x1000,%eax
f01012e8:	e8 ff f6 ff ff       	call   f01009ec <boot_alloc>
f01012ed:	a3 8c fe 22 f0       	mov    %eax,0xf022fe8c
	memset(kern_pgdir, 0, PGSIZE);
f01012f2:	83 c4 0c             	add    $0xc,%esp
f01012f5:	68 00 10 00 00       	push   $0x1000
f01012fa:	6a 00                	push   $0x0
f01012fc:	50                   	push   %eax
f01012fd:	e8 37 43 00 00       	call   f0105639 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0101302:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0101307:	83 c4 10             	add    $0x10,%esp
f010130a:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010130f:	77 15                	ja     f0101326 <mem_init+0xf6>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101311:	50                   	push   %eax
f0101312:	68 48 63 10 f0       	push   $0xf0106348
f0101317:	68 93 00 00 00       	push   $0x93
f010131c:	68 39 71 10 f0       	push   $0xf0107139
f0101321:	e8 1a ed ff ff       	call   f0100040 <_panic>
f0101326:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f010132c:	83 ca 05             	or     $0x5,%edx
f010132f:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages = (struct PageInfo* )boot_alloc(npages * sizeof (struct PageInfo));
f0101335:	a1 88 fe 22 f0       	mov    0xf022fe88,%eax
f010133a:	c1 e0 03             	shl    $0x3,%eax
f010133d:	e8 aa f6 ff ff       	call   f01009ec <boot_alloc>
f0101342:	a3 90 fe 22 f0       	mov    %eax,0xf022fe90
	memset(pages, 0, npages*sizeof(struct PageInfo));
f0101347:	83 ec 04             	sub    $0x4,%esp
f010134a:	8b 0d 88 fe 22 f0    	mov    0xf022fe88,%ecx
f0101350:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f0101357:	52                   	push   %edx
f0101358:	6a 00                	push   $0x0
f010135a:	50                   	push   %eax
f010135b:	e8 d9 42 00 00       	call   f0105639 <memset>

	//////////////////////////////////////////////////////////////////////
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.
	envs =(struct Env*) boot_alloc(NENV* sizeof(struct Env));
f0101360:	b8 00 f0 01 00       	mov    $0x1f000,%eax
f0101365:	e8 82 f6 ff ff       	call   f01009ec <boot_alloc>
f010136a:	a3 48 f2 22 f0       	mov    %eax,0xf022f248
	memset(envs, 0, NENV*sizeof(struct Env) );
f010136f:	83 c4 0c             	add    $0xc,%esp
f0101372:	68 00 f0 01 00       	push   $0x1f000
f0101377:	6a 00                	push   $0x0
f0101379:	50                   	push   %eax
f010137a:	e8 ba 42 00 00       	call   f0105639 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f010137f:	e8 fe f9 ff ff       	call   f0100d82 <page_init>

	check_page_free_list(1);
f0101384:	b8 01 00 00 00       	mov    $0x1,%eax
f0101389:	e8 05 f7 ff ff       	call   f0100a93 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f010138e:	83 c4 10             	add    $0x10,%esp
f0101391:	83 3d 90 fe 22 f0 00 	cmpl   $0x0,0xf022fe90
f0101398:	75 17                	jne    f01013b1 <mem_init+0x181>
		panic("'pages' is a null pointer!");
f010139a:	83 ec 04             	sub    $0x4,%esp
f010139d:	68 23 72 10 f0       	push   $0xf0107223
f01013a2:	68 27 03 00 00       	push   $0x327
f01013a7:	68 39 71 10 f0       	push   $0xf0107139
f01013ac:	e8 8f ec ff ff       	call   f0100040 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01013b1:	a1 40 f2 22 f0       	mov    0xf022f240,%eax
f01013b6:	bb 00 00 00 00       	mov    $0x0,%ebx
f01013bb:	eb 05                	jmp    f01013c2 <mem_init+0x192>
		++nfree;
f01013bd:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01013c0:	8b 00                	mov    (%eax),%eax
f01013c2:	85 c0                	test   %eax,%eax
f01013c4:	75 f7                	jne    f01013bd <mem_init+0x18d>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01013c6:	83 ec 0c             	sub    $0xc,%esp
f01013c9:	6a 00                	push   $0x0
f01013cb:	e8 b7 fa ff ff       	call   f0100e87 <page_alloc>
f01013d0:	89 c7                	mov    %eax,%edi
f01013d2:	83 c4 10             	add    $0x10,%esp
f01013d5:	85 c0                	test   %eax,%eax
f01013d7:	75 19                	jne    f01013f2 <mem_init+0x1c2>
f01013d9:	68 3e 72 10 f0       	push   $0xf010723e
f01013de:	68 5f 71 10 f0       	push   $0xf010715f
f01013e3:	68 2f 03 00 00       	push   $0x32f
f01013e8:	68 39 71 10 f0       	push   $0xf0107139
f01013ed:	e8 4e ec ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f01013f2:	83 ec 0c             	sub    $0xc,%esp
f01013f5:	6a 00                	push   $0x0
f01013f7:	e8 8b fa ff ff       	call   f0100e87 <page_alloc>
f01013fc:	89 c6                	mov    %eax,%esi
f01013fe:	83 c4 10             	add    $0x10,%esp
f0101401:	85 c0                	test   %eax,%eax
f0101403:	75 19                	jne    f010141e <mem_init+0x1ee>
f0101405:	68 54 72 10 f0       	push   $0xf0107254
f010140a:	68 5f 71 10 f0       	push   $0xf010715f
f010140f:	68 30 03 00 00       	push   $0x330
f0101414:	68 39 71 10 f0       	push   $0xf0107139
f0101419:	e8 22 ec ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f010141e:	83 ec 0c             	sub    $0xc,%esp
f0101421:	6a 00                	push   $0x0
f0101423:	e8 5f fa ff ff       	call   f0100e87 <page_alloc>
f0101428:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010142b:	83 c4 10             	add    $0x10,%esp
f010142e:	85 c0                	test   %eax,%eax
f0101430:	75 19                	jne    f010144b <mem_init+0x21b>
f0101432:	68 6a 72 10 f0       	push   $0xf010726a
f0101437:	68 5f 71 10 f0       	push   $0xf010715f
f010143c:	68 31 03 00 00       	push   $0x331
f0101441:	68 39 71 10 f0       	push   $0xf0107139
f0101446:	e8 f5 eb ff ff       	call   f0100040 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010144b:	39 f7                	cmp    %esi,%edi
f010144d:	75 19                	jne    f0101468 <mem_init+0x238>
f010144f:	68 80 72 10 f0       	push   $0xf0107280
f0101454:	68 5f 71 10 f0       	push   $0xf010715f
f0101459:	68 34 03 00 00       	push   $0x334
f010145e:	68 39 71 10 f0       	push   $0xf0107139
f0101463:	e8 d8 eb ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101468:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010146b:	39 c6                	cmp    %eax,%esi
f010146d:	74 04                	je     f0101473 <mem_init+0x243>
f010146f:	39 c7                	cmp    %eax,%edi
f0101471:	75 19                	jne    f010148c <mem_init+0x25c>
f0101473:	68 5c 69 10 f0       	push   $0xf010695c
f0101478:	68 5f 71 10 f0       	push   $0xf010715f
f010147d:	68 35 03 00 00       	push   $0x335
f0101482:	68 39 71 10 f0       	push   $0xf0107139
f0101487:	e8 b4 eb ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010148c:	8b 0d 90 fe 22 f0    	mov    0xf022fe90,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101492:	8b 15 88 fe 22 f0    	mov    0xf022fe88,%edx
f0101498:	c1 e2 0c             	shl    $0xc,%edx
f010149b:	89 f8                	mov    %edi,%eax
f010149d:	29 c8                	sub    %ecx,%eax
f010149f:	c1 f8 03             	sar    $0x3,%eax
f01014a2:	c1 e0 0c             	shl    $0xc,%eax
f01014a5:	39 d0                	cmp    %edx,%eax
f01014a7:	72 19                	jb     f01014c2 <mem_init+0x292>
f01014a9:	68 92 72 10 f0       	push   $0xf0107292
f01014ae:	68 5f 71 10 f0       	push   $0xf010715f
f01014b3:	68 36 03 00 00       	push   $0x336
f01014b8:	68 39 71 10 f0       	push   $0xf0107139
f01014bd:	e8 7e eb ff ff       	call   f0100040 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f01014c2:	89 f0                	mov    %esi,%eax
f01014c4:	29 c8                	sub    %ecx,%eax
f01014c6:	c1 f8 03             	sar    $0x3,%eax
f01014c9:	c1 e0 0c             	shl    $0xc,%eax
f01014cc:	39 c2                	cmp    %eax,%edx
f01014ce:	77 19                	ja     f01014e9 <mem_init+0x2b9>
f01014d0:	68 af 72 10 f0       	push   $0xf01072af
f01014d5:	68 5f 71 10 f0       	push   $0xf010715f
f01014da:	68 37 03 00 00       	push   $0x337
f01014df:	68 39 71 10 f0       	push   $0xf0107139
f01014e4:	e8 57 eb ff ff       	call   f0100040 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f01014e9:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01014ec:	29 c8                	sub    %ecx,%eax
f01014ee:	c1 f8 03             	sar    $0x3,%eax
f01014f1:	c1 e0 0c             	shl    $0xc,%eax
f01014f4:	39 c2                	cmp    %eax,%edx
f01014f6:	77 19                	ja     f0101511 <mem_init+0x2e1>
f01014f8:	68 cc 72 10 f0       	push   $0xf01072cc
f01014fd:	68 5f 71 10 f0       	push   $0xf010715f
f0101502:	68 38 03 00 00       	push   $0x338
f0101507:	68 39 71 10 f0       	push   $0xf0107139
f010150c:	e8 2f eb ff ff       	call   f0100040 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101511:	a1 40 f2 22 f0       	mov    0xf022f240,%eax
f0101516:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101519:	c7 05 40 f2 22 f0 00 	movl   $0x0,0xf022f240
f0101520:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101523:	83 ec 0c             	sub    $0xc,%esp
f0101526:	6a 00                	push   $0x0
f0101528:	e8 5a f9 ff ff       	call   f0100e87 <page_alloc>
f010152d:	83 c4 10             	add    $0x10,%esp
f0101530:	85 c0                	test   %eax,%eax
f0101532:	74 19                	je     f010154d <mem_init+0x31d>
f0101534:	68 e9 72 10 f0       	push   $0xf01072e9
f0101539:	68 5f 71 10 f0       	push   $0xf010715f
f010153e:	68 3f 03 00 00       	push   $0x33f
f0101543:	68 39 71 10 f0       	push   $0xf0107139
f0101548:	e8 f3 ea ff ff       	call   f0100040 <_panic>

	// free and re-allocate?
	page_free(pp0);
f010154d:	83 ec 0c             	sub    $0xc,%esp
f0101550:	57                   	push   %edi
f0101551:	e8 a1 f9 ff ff       	call   f0100ef7 <page_free>
	page_free(pp1);
f0101556:	89 34 24             	mov    %esi,(%esp)
f0101559:	e8 99 f9 ff ff       	call   f0100ef7 <page_free>
	page_free(pp2);
f010155e:	83 c4 04             	add    $0x4,%esp
f0101561:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101564:	e8 8e f9 ff ff       	call   f0100ef7 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101569:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101570:	e8 12 f9 ff ff       	call   f0100e87 <page_alloc>
f0101575:	89 c6                	mov    %eax,%esi
f0101577:	83 c4 10             	add    $0x10,%esp
f010157a:	85 c0                	test   %eax,%eax
f010157c:	75 19                	jne    f0101597 <mem_init+0x367>
f010157e:	68 3e 72 10 f0       	push   $0xf010723e
f0101583:	68 5f 71 10 f0       	push   $0xf010715f
f0101588:	68 46 03 00 00       	push   $0x346
f010158d:	68 39 71 10 f0       	push   $0xf0107139
f0101592:	e8 a9 ea ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0101597:	83 ec 0c             	sub    $0xc,%esp
f010159a:	6a 00                	push   $0x0
f010159c:	e8 e6 f8 ff ff       	call   f0100e87 <page_alloc>
f01015a1:	89 c7                	mov    %eax,%edi
f01015a3:	83 c4 10             	add    $0x10,%esp
f01015a6:	85 c0                	test   %eax,%eax
f01015a8:	75 19                	jne    f01015c3 <mem_init+0x393>
f01015aa:	68 54 72 10 f0       	push   $0xf0107254
f01015af:	68 5f 71 10 f0       	push   $0xf010715f
f01015b4:	68 47 03 00 00       	push   $0x347
f01015b9:	68 39 71 10 f0       	push   $0xf0107139
f01015be:	e8 7d ea ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f01015c3:	83 ec 0c             	sub    $0xc,%esp
f01015c6:	6a 00                	push   $0x0
f01015c8:	e8 ba f8 ff ff       	call   f0100e87 <page_alloc>
f01015cd:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01015d0:	83 c4 10             	add    $0x10,%esp
f01015d3:	85 c0                	test   %eax,%eax
f01015d5:	75 19                	jne    f01015f0 <mem_init+0x3c0>
f01015d7:	68 6a 72 10 f0       	push   $0xf010726a
f01015dc:	68 5f 71 10 f0       	push   $0xf010715f
f01015e1:	68 48 03 00 00       	push   $0x348
f01015e6:	68 39 71 10 f0       	push   $0xf0107139
f01015eb:	e8 50 ea ff ff       	call   f0100040 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01015f0:	39 fe                	cmp    %edi,%esi
f01015f2:	75 19                	jne    f010160d <mem_init+0x3dd>
f01015f4:	68 80 72 10 f0       	push   $0xf0107280
f01015f9:	68 5f 71 10 f0       	push   $0xf010715f
f01015fe:	68 4a 03 00 00       	push   $0x34a
f0101603:	68 39 71 10 f0       	push   $0xf0107139
f0101608:	e8 33 ea ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010160d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101610:	39 c7                	cmp    %eax,%edi
f0101612:	74 04                	je     f0101618 <mem_init+0x3e8>
f0101614:	39 c6                	cmp    %eax,%esi
f0101616:	75 19                	jne    f0101631 <mem_init+0x401>
f0101618:	68 5c 69 10 f0       	push   $0xf010695c
f010161d:	68 5f 71 10 f0       	push   $0xf010715f
f0101622:	68 4b 03 00 00       	push   $0x34b
f0101627:	68 39 71 10 f0       	push   $0xf0107139
f010162c:	e8 0f ea ff ff       	call   f0100040 <_panic>
	assert(!page_alloc(0));
f0101631:	83 ec 0c             	sub    $0xc,%esp
f0101634:	6a 00                	push   $0x0
f0101636:	e8 4c f8 ff ff       	call   f0100e87 <page_alloc>
f010163b:	83 c4 10             	add    $0x10,%esp
f010163e:	85 c0                	test   %eax,%eax
f0101640:	74 19                	je     f010165b <mem_init+0x42b>
f0101642:	68 e9 72 10 f0       	push   $0xf01072e9
f0101647:	68 5f 71 10 f0       	push   $0xf010715f
f010164c:	68 4c 03 00 00       	push   $0x34c
f0101651:	68 39 71 10 f0       	push   $0xf0107139
f0101656:	e8 e5 e9 ff ff       	call   f0100040 <_panic>
f010165b:	89 f0                	mov    %esi,%eax
f010165d:	2b 05 90 fe 22 f0    	sub    0xf022fe90,%eax
f0101663:	c1 f8 03             	sar    $0x3,%eax
f0101666:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101669:	89 c2                	mov    %eax,%edx
f010166b:	c1 ea 0c             	shr    $0xc,%edx
f010166e:	3b 15 88 fe 22 f0    	cmp    0xf022fe88,%edx
f0101674:	72 12                	jb     f0101688 <mem_init+0x458>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101676:	50                   	push   %eax
f0101677:	68 24 63 10 f0       	push   $0xf0106324
f010167c:	6a 58                	push   $0x58
f010167e:	68 45 71 10 f0       	push   $0xf0107145
f0101683:	e8 b8 e9 ff ff       	call   f0100040 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101688:	83 ec 04             	sub    $0x4,%esp
f010168b:	68 00 10 00 00       	push   $0x1000
f0101690:	6a 01                	push   $0x1
f0101692:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101697:	50                   	push   %eax
f0101698:	e8 9c 3f 00 00       	call   f0105639 <memset>
	page_free(pp0);
f010169d:	89 34 24             	mov    %esi,(%esp)
f01016a0:	e8 52 f8 ff ff       	call   f0100ef7 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01016a5:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01016ac:	e8 d6 f7 ff ff       	call   f0100e87 <page_alloc>
f01016b1:	83 c4 10             	add    $0x10,%esp
f01016b4:	85 c0                	test   %eax,%eax
f01016b6:	75 19                	jne    f01016d1 <mem_init+0x4a1>
f01016b8:	68 f8 72 10 f0       	push   $0xf01072f8
f01016bd:	68 5f 71 10 f0       	push   $0xf010715f
f01016c2:	68 51 03 00 00       	push   $0x351
f01016c7:	68 39 71 10 f0       	push   $0xf0107139
f01016cc:	e8 6f e9 ff ff       	call   f0100040 <_panic>
	assert(pp && pp0 == pp);
f01016d1:	39 c6                	cmp    %eax,%esi
f01016d3:	74 19                	je     f01016ee <mem_init+0x4be>
f01016d5:	68 16 73 10 f0       	push   $0xf0107316
f01016da:	68 5f 71 10 f0       	push   $0xf010715f
f01016df:	68 52 03 00 00       	push   $0x352
f01016e4:	68 39 71 10 f0       	push   $0xf0107139
f01016e9:	e8 52 e9 ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01016ee:	89 f0                	mov    %esi,%eax
f01016f0:	2b 05 90 fe 22 f0    	sub    0xf022fe90,%eax
f01016f6:	c1 f8 03             	sar    $0x3,%eax
f01016f9:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01016fc:	89 c2                	mov    %eax,%edx
f01016fe:	c1 ea 0c             	shr    $0xc,%edx
f0101701:	3b 15 88 fe 22 f0    	cmp    0xf022fe88,%edx
f0101707:	72 12                	jb     f010171b <mem_init+0x4eb>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101709:	50                   	push   %eax
f010170a:	68 24 63 10 f0       	push   $0xf0106324
f010170f:	6a 58                	push   $0x58
f0101711:	68 45 71 10 f0       	push   $0xf0107145
f0101716:	e8 25 e9 ff ff       	call   f0100040 <_panic>
f010171b:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f0101721:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f0101727:	80 38 00             	cmpb   $0x0,(%eax)
f010172a:	74 19                	je     f0101745 <mem_init+0x515>
f010172c:	68 26 73 10 f0       	push   $0xf0107326
f0101731:	68 5f 71 10 f0       	push   $0xf010715f
f0101736:	68 55 03 00 00       	push   $0x355
f010173b:	68 39 71 10 f0       	push   $0xf0107139
f0101740:	e8 fb e8 ff ff       	call   f0100040 <_panic>
f0101745:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f0101748:	39 d0                	cmp    %edx,%eax
f010174a:	75 db                	jne    f0101727 <mem_init+0x4f7>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f010174c:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010174f:	a3 40 f2 22 f0       	mov    %eax,0xf022f240

	// free the pages we took
	page_free(pp0);
f0101754:	83 ec 0c             	sub    $0xc,%esp
f0101757:	56                   	push   %esi
f0101758:	e8 9a f7 ff ff       	call   f0100ef7 <page_free>
	page_free(pp1);
f010175d:	89 3c 24             	mov    %edi,(%esp)
f0101760:	e8 92 f7 ff ff       	call   f0100ef7 <page_free>
	page_free(pp2);
f0101765:	83 c4 04             	add    $0x4,%esp
f0101768:	ff 75 d4             	pushl  -0x2c(%ebp)
f010176b:	e8 87 f7 ff ff       	call   f0100ef7 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101770:	a1 40 f2 22 f0       	mov    0xf022f240,%eax
f0101775:	83 c4 10             	add    $0x10,%esp
f0101778:	eb 05                	jmp    f010177f <mem_init+0x54f>
		--nfree;
f010177a:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010177d:	8b 00                	mov    (%eax),%eax
f010177f:	85 c0                	test   %eax,%eax
f0101781:	75 f7                	jne    f010177a <mem_init+0x54a>
		--nfree;
	assert(nfree == 0);
f0101783:	85 db                	test   %ebx,%ebx
f0101785:	74 19                	je     f01017a0 <mem_init+0x570>
f0101787:	68 30 73 10 f0       	push   $0xf0107330
f010178c:	68 5f 71 10 f0       	push   $0xf010715f
f0101791:	68 62 03 00 00       	push   $0x362
f0101796:	68 39 71 10 f0       	push   $0xf0107139
f010179b:	e8 a0 e8 ff ff       	call   f0100040 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f01017a0:	83 ec 0c             	sub    $0xc,%esp
f01017a3:	68 7c 69 10 f0       	push   $0xf010697c
f01017a8:	e8 af 1f 00 00       	call   f010375c <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01017ad:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01017b4:	e8 ce f6 ff ff       	call   f0100e87 <page_alloc>
f01017b9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01017bc:	83 c4 10             	add    $0x10,%esp
f01017bf:	85 c0                	test   %eax,%eax
f01017c1:	75 19                	jne    f01017dc <mem_init+0x5ac>
f01017c3:	68 3e 72 10 f0       	push   $0xf010723e
f01017c8:	68 5f 71 10 f0       	push   $0xf010715f
f01017cd:	68 c8 03 00 00       	push   $0x3c8
f01017d2:	68 39 71 10 f0       	push   $0xf0107139
f01017d7:	e8 64 e8 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f01017dc:	83 ec 0c             	sub    $0xc,%esp
f01017df:	6a 00                	push   $0x0
f01017e1:	e8 a1 f6 ff ff       	call   f0100e87 <page_alloc>
f01017e6:	89 c3                	mov    %eax,%ebx
f01017e8:	83 c4 10             	add    $0x10,%esp
f01017eb:	85 c0                	test   %eax,%eax
f01017ed:	75 19                	jne    f0101808 <mem_init+0x5d8>
f01017ef:	68 54 72 10 f0       	push   $0xf0107254
f01017f4:	68 5f 71 10 f0       	push   $0xf010715f
f01017f9:	68 c9 03 00 00       	push   $0x3c9
f01017fe:	68 39 71 10 f0       	push   $0xf0107139
f0101803:	e8 38 e8 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0101808:	83 ec 0c             	sub    $0xc,%esp
f010180b:	6a 00                	push   $0x0
f010180d:	e8 75 f6 ff ff       	call   f0100e87 <page_alloc>
f0101812:	89 c6                	mov    %eax,%esi
f0101814:	83 c4 10             	add    $0x10,%esp
f0101817:	85 c0                	test   %eax,%eax
f0101819:	75 19                	jne    f0101834 <mem_init+0x604>
f010181b:	68 6a 72 10 f0       	push   $0xf010726a
f0101820:	68 5f 71 10 f0       	push   $0xf010715f
f0101825:	68 ca 03 00 00       	push   $0x3ca
f010182a:	68 39 71 10 f0       	push   $0xf0107139
f010182f:	e8 0c e8 ff ff       	call   f0100040 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101834:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0101837:	75 19                	jne    f0101852 <mem_init+0x622>
f0101839:	68 80 72 10 f0       	push   $0xf0107280
f010183e:	68 5f 71 10 f0       	push   $0xf010715f
f0101843:	68 cd 03 00 00       	push   $0x3cd
f0101848:	68 39 71 10 f0       	push   $0xf0107139
f010184d:	e8 ee e7 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101852:	39 c3                	cmp    %eax,%ebx
f0101854:	74 05                	je     f010185b <mem_init+0x62b>
f0101856:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101859:	75 19                	jne    f0101874 <mem_init+0x644>
f010185b:	68 5c 69 10 f0       	push   $0xf010695c
f0101860:	68 5f 71 10 f0       	push   $0xf010715f
f0101865:	68 ce 03 00 00       	push   $0x3ce
f010186a:	68 39 71 10 f0       	push   $0xf0107139
f010186f:	e8 cc e7 ff ff       	call   f0100040 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101874:	a1 40 f2 22 f0       	mov    0xf022f240,%eax
f0101879:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f010187c:	c7 05 40 f2 22 f0 00 	movl   $0x0,0xf022f240
f0101883:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101886:	83 ec 0c             	sub    $0xc,%esp
f0101889:	6a 00                	push   $0x0
f010188b:	e8 f7 f5 ff ff       	call   f0100e87 <page_alloc>
f0101890:	83 c4 10             	add    $0x10,%esp
f0101893:	85 c0                	test   %eax,%eax
f0101895:	74 19                	je     f01018b0 <mem_init+0x680>
f0101897:	68 e9 72 10 f0       	push   $0xf01072e9
f010189c:	68 5f 71 10 f0       	push   $0xf010715f
f01018a1:	68 d5 03 00 00       	push   $0x3d5
f01018a6:	68 39 71 10 f0       	push   $0xf0107139
f01018ab:	e8 90 e7 ff ff       	call   f0100040 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f01018b0:	83 ec 04             	sub    $0x4,%esp
f01018b3:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01018b6:	50                   	push   %eax
f01018b7:	6a 00                	push   $0x0
f01018b9:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f01018bf:	e8 88 f7 ff ff       	call   f010104c <page_lookup>
f01018c4:	83 c4 10             	add    $0x10,%esp
f01018c7:	85 c0                	test   %eax,%eax
f01018c9:	74 19                	je     f01018e4 <mem_init+0x6b4>
f01018cb:	68 9c 69 10 f0       	push   $0xf010699c
f01018d0:	68 5f 71 10 f0       	push   $0xf010715f
f01018d5:	68 d8 03 00 00       	push   $0x3d8
f01018da:	68 39 71 10 f0       	push   $0xf0107139
f01018df:	e8 5c e7 ff ff       	call   f0100040 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f01018e4:	6a 02                	push   $0x2
f01018e6:	6a 00                	push   $0x0
f01018e8:	53                   	push   %ebx
f01018e9:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f01018ef:	e8 48 f8 ff ff       	call   f010113c <page_insert>
f01018f4:	83 c4 10             	add    $0x10,%esp
f01018f7:	85 c0                	test   %eax,%eax
f01018f9:	78 19                	js     f0101914 <mem_init+0x6e4>
f01018fb:	68 d4 69 10 f0       	push   $0xf01069d4
f0101900:	68 5f 71 10 f0       	push   $0xf010715f
f0101905:	68 db 03 00 00       	push   $0x3db
f010190a:	68 39 71 10 f0       	push   $0xf0107139
f010190f:	e8 2c e7 ff ff       	call   f0100040 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101914:	83 ec 0c             	sub    $0xc,%esp
f0101917:	ff 75 d4             	pushl  -0x2c(%ebp)
f010191a:	e8 d8 f5 ff ff       	call   f0100ef7 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f010191f:	6a 02                	push   $0x2
f0101921:	6a 00                	push   $0x0
f0101923:	53                   	push   %ebx
f0101924:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f010192a:	e8 0d f8 ff ff       	call   f010113c <page_insert>
f010192f:	83 c4 20             	add    $0x20,%esp
f0101932:	85 c0                	test   %eax,%eax
f0101934:	74 19                	je     f010194f <mem_init+0x71f>
f0101936:	68 04 6a 10 f0       	push   $0xf0106a04
f010193b:	68 5f 71 10 f0       	push   $0xf010715f
f0101940:	68 df 03 00 00       	push   $0x3df
f0101945:	68 39 71 10 f0       	push   $0xf0107139
f010194a:	e8 f1 e6 ff ff       	call   f0100040 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010194f:	8b 3d 8c fe 22 f0    	mov    0xf022fe8c,%edi
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101955:	a1 90 fe 22 f0       	mov    0xf022fe90,%eax
f010195a:	89 c1                	mov    %eax,%ecx
f010195c:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010195f:	8b 17                	mov    (%edi),%edx
f0101961:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101967:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010196a:	29 c8                	sub    %ecx,%eax
f010196c:	c1 f8 03             	sar    $0x3,%eax
f010196f:	c1 e0 0c             	shl    $0xc,%eax
f0101972:	39 c2                	cmp    %eax,%edx
f0101974:	74 19                	je     f010198f <mem_init+0x75f>
f0101976:	68 34 6a 10 f0       	push   $0xf0106a34
f010197b:	68 5f 71 10 f0       	push   $0xf010715f
f0101980:	68 e0 03 00 00       	push   $0x3e0
f0101985:	68 39 71 10 f0       	push   $0xf0107139
f010198a:	e8 b1 e6 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f010198f:	ba 00 00 00 00       	mov    $0x0,%edx
f0101994:	89 f8                	mov    %edi,%eax
f0101996:	e8 94 f0 ff ff       	call   f0100a2f <check_va2pa>
f010199b:	89 da                	mov    %ebx,%edx
f010199d:	2b 55 cc             	sub    -0x34(%ebp),%edx
f01019a0:	c1 fa 03             	sar    $0x3,%edx
f01019a3:	c1 e2 0c             	shl    $0xc,%edx
f01019a6:	39 d0                	cmp    %edx,%eax
f01019a8:	74 19                	je     f01019c3 <mem_init+0x793>
f01019aa:	68 5c 6a 10 f0       	push   $0xf0106a5c
f01019af:	68 5f 71 10 f0       	push   $0xf010715f
f01019b4:	68 e1 03 00 00       	push   $0x3e1
f01019b9:	68 39 71 10 f0       	push   $0xf0107139
f01019be:	e8 7d e6 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f01019c3:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01019c8:	74 19                	je     f01019e3 <mem_init+0x7b3>
f01019ca:	68 3b 73 10 f0       	push   $0xf010733b
f01019cf:	68 5f 71 10 f0       	push   $0xf010715f
f01019d4:	68 e2 03 00 00       	push   $0x3e2
f01019d9:	68 39 71 10 f0       	push   $0xf0107139
f01019de:	e8 5d e6 ff ff       	call   f0100040 <_panic>
	assert(pp0->pp_ref == 1);
f01019e3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01019e6:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f01019eb:	74 19                	je     f0101a06 <mem_init+0x7d6>
f01019ed:	68 4c 73 10 f0       	push   $0xf010734c
f01019f2:	68 5f 71 10 f0       	push   $0xf010715f
f01019f7:	68 e3 03 00 00       	push   $0x3e3
f01019fc:	68 39 71 10 f0       	push   $0xf0107139
f0101a01:	e8 3a e6 ff ff       	call   f0100040 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101a06:	6a 02                	push   $0x2
f0101a08:	68 00 10 00 00       	push   $0x1000
f0101a0d:	56                   	push   %esi
f0101a0e:	57                   	push   %edi
f0101a0f:	e8 28 f7 ff ff       	call   f010113c <page_insert>
f0101a14:	83 c4 10             	add    $0x10,%esp
f0101a17:	85 c0                	test   %eax,%eax
f0101a19:	74 19                	je     f0101a34 <mem_init+0x804>
f0101a1b:	68 8c 6a 10 f0       	push   $0xf0106a8c
f0101a20:	68 5f 71 10 f0       	push   $0xf010715f
f0101a25:	68 e6 03 00 00       	push   $0x3e6
f0101a2a:	68 39 71 10 f0       	push   $0xf0107139
f0101a2f:	e8 0c e6 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101a34:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101a39:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
f0101a3e:	e8 ec ef ff ff       	call   f0100a2f <check_va2pa>
f0101a43:	89 f2                	mov    %esi,%edx
f0101a45:	2b 15 90 fe 22 f0    	sub    0xf022fe90,%edx
f0101a4b:	c1 fa 03             	sar    $0x3,%edx
f0101a4e:	c1 e2 0c             	shl    $0xc,%edx
f0101a51:	39 d0                	cmp    %edx,%eax
f0101a53:	74 19                	je     f0101a6e <mem_init+0x83e>
f0101a55:	68 c8 6a 10 f0       	push   $0xf0106ac8
f0101a5a:	68 5f 71 10 f0       	push   $0xf010715f
f0101a5f:	68 e7 03 00 00       	push   $0x3e7
f0101a64:	68 39 71 10 f0       	push   $0xf0107139
f0101a69:	e8 d2 e5 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101a6e:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101a73:	74 19                	je     f0101a8e <mem_init+0x85e>
f0101a75:	68 5d 73 10 f0       	push   $0xf010735d
f0101a7a:	68 5f 71 10 f0       	push   $0xf010715f
f0101a7f:	68 e8 03 00 00       	push   $0x3e8
f0101a84:	68 39 71 10 f0       	push   $0xf0107139
f0101a89:	e8 b2 e5 ff ff       	call   f0100040 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101a8e:	83 ec 0c             	sub    $0xc,%esp
f0101a91:	6a 00                	push   $0x0
f0101a93:	e8 ef f3 ff ff       	call   f0100e87 <page_alloc>
f0101a98:	83 c4 10             	add    $0x10,%esp
f0101a9b:	85 c0                	test   %eax,%eax
f0101a9d:	74 19                	je     f0101ab8 <mem_init+0x888>
f0101a9f:	68 e9 72 10 f0       	push   $0xf01072e9
f0101aa4:	68 5f 71 10 f0       	push   $0xf010715f
f0101aa9:	68 eb 03 00 00       	push   $0x3eb
f0101aae:	68 39 71 10 f0       	push   $0xf0107139
f0101ab3:	e8 88 e5 ff ff       	call   f0100040 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101ab8:	6a 02                	push   $0x2
f0101aba:	68 00 10 00 00       	push   $0x1000
f0101abf:	56                   	push   %esi
f0101ac0:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0101ac6:	e8 71 f6 ff ff       	call   f010113c <page_insert>
f0101acb:	83 c4 10             	add    $0x10,%esp
f0101ace:	85 c0                	test   %eax,%eax
f0101ad0:	74 19                	je     f0101aeb <mem_init+0x8bb>
f0101ad2:	68 8c 6a 10 f0       	push   $0xf0106a8c
f0101ad7:	68 5f 71 10 f0       	push   $0xf010715f
f0101adc:	68 ee 03 00 00       	push   $0x3ee
f0101ae1:	68 39 71 10 f0       	push   $0xf0107139
f0101ae6:	e8 55 e5 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101aeb:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101af0:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
f0101af5:	e8 35 ef ff ff       	call   f0100a2f <check_va2pa>
f0101afa:	89 f2                	mov    %esi,%edx
f0101afc:	2b 15 90 fe 22 f0    	sub    0xf022fe90,%edx
f0101b02:	c1 fa 03             	sar    $0x3,%edx
f0101b05:	c1 e2 0c             	shl    $0xc,%edx
f0101b08:	39 d0                	cmp    %edx,%eax
f0101b0a:	74 19                	je     f0101b25 <mem_init+0x8f5>
f0101b0c:	68 c8 6a 10 f0       	push   $0xf0106ac8
f0101b11:	68 5f 71 10 f0       	push   $0xf010715f
f0101b16:	68 ef 03 00 00       	push   $0x3ef
f0101b1b:	68 39 71 10 f0       	push   $0xf0107139
f0101b20:	e8 1b e5 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101b25:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101b2a:	74 19                	je     f0101b45 <mem_init+0x915>
f0101b2c:	68 5d 73 10 f0       	push   $0xf010735d
f0101b31:	68 5f 71 10 f0       	push   $0xf010715f
f0101b36:	68 f0 03 00 00       	push   $0x3f0
f0101b3b:	68 39 71 10 f0       	push   $0xf0107139
f0101b40:	e8 fb e4 ff ff       	call   f0100040 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101b45:	83 ec 0c             	sub    $0xc,%esp
f0101b48:	6a 00                	push   $0x0
f0101b4a:	e8 38 f3 ff ff       	call   f0100e87 <page_alloc>
f0101b4f:	83 c4 10             	add    $0x10,%esp
f0101b52:	85 c0                	test   %eax,%eax
f0101b54:	74 19                	je     f0101b6f <mem_init+0x93f>
f0101b56:	68 e9 72 10 f0       	push   $0xf01072e9
f0101b5b:	68 5f 71 10 f0       	push   $0xf010715f
f0101b60:	68 f4 03 00 00       	push   $0x3f4
f0101b65:	68 39 71 10 f0       	push   $0xf0107139
f0101b6a:	e8 d1 e4 ff ff       	call   f0100040 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101b6f:	8b 15 8c fe 22 f0    	mov    0xf022fe8c,%edx
f0101b75:	8b 02                	mov    (%edx),%eax
f0101b77:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101b7c:	89 c1                	mov    %eax,%ecx
f0101b7e:	c1 e9 0c             	shr    $0xc,%ecx
f0101b81:	3b 0d 88 fe 22 f0    	cmp    0xf022fe88,%ecx
f0101b87:	72 15                	jb     f0101b9e <mem_init+0x96e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101b89:	50                   	push   %eax
f0101b8a:	68 24 63 10 f0       	push   $0xf0106324
f0101b8f:	68 f7 03 00 00       	push   $0x3f7
f0101b94:	68 39 71 10 f0       	push   $0xf0107139
f0101b99:	e8 a2 e4 ff ff       	call   f0100040 <_panic>
f0101b9e:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101ba3:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101ba6:	83 ec 04             	sub    $0x4,%esp
f0101ba9:	6a 00                	push   $0x0
f0101bab:	68 00 10 00 00       	push   $0x1000
f0101bb0:	52                   	push   %edx
f0101bb1:	e8 a3 f3 ff ff       	call   f0100f59 <pgdir_walk>
f0101bb6:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101bb9:	8d 51 04             	lea    0x4(%ecx),%edx
f0101bbc:	83 c4 10             	add    $0x10,%esp
f0101bbf:	39 d0                	cmp    %edx,%eax
f0101bc1:	74 19                	je     f0101bdc <mem_init+0x9ac>
f0101bc3:	68 f8 6a 10 f0       	push   $0xf0106af8
f0101bc8:	68 5f 71 10 f0       	push   $0xf010715f
f0101bcd:	68 f8 03 00 00       	push   $0x3f8
f0101bd2:	68 39 71 10 f0       	push   $0xf0107139
f0101bd7:	e8 64 e4 ff ff       	call   f0100040 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101bdc:	6a 06                	push   $0x6
f0101bde:	68 00 10 00 00       	push   $0x1000
f0101be3:	56                   	push   %esi
f0101be4:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0101bea:	e8 4d f5 ff ff       	call   f010113c <page_insert>
f0101bef:	83 c4 10             	add    $0x10,%esp
f0101bf2:	85 c0                	test   %eax,%eax
f0101bf4:	74 19                	je     f0101c0f <mem_init+0x9df>
f0101bf6:	68 38 6b 10 f0       	push   $0xf0106b38
f0101bfb:	68 5f 71 10 f0       	push   $0xf010715f
f0101c00:	68 fb 03 00 00       	push   $0x3fb
f0101c05:	68 39 71 10 f0       	push   $0xf0107139
f0101c0a:	e8 31 e4 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101c0f:	8b 3d 8c fe 22 f0    	mov    0xf022fe8c,%edi
f0101c15:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c1a:	89 f8                	mov    %edi,%eax
f0101c1c:	e8 0e ee ff ff       	call   f0100a2f <check_va2pa>
f0101c21:	89 f2                	mov    %esi,%edx
f0101c23:	2b 15 90 fe 22 f0    	sub    0xf022fe90,%edx
f0101c29:	c1 fa 03             	sar    $0x3,%edx
f0101c2c:	c1 e2 0c             	shl    $0xc,%edx
f0101c2f:	39 d0                	cmp    %edx,%eax
f0101c31:	74 19                	je     f0101c4c <mem_init+0xa1c>
f0101c33:	68 c8 6a 10 f0       	push   $0xf0106ac8
f0101c38:	68 5f 71 10 f0       	push   $0xf010715f
f0101c3d:	68 fc 03 00 00       	push   $0x3fc
f0101c42:	68 39 71 10 f0       	push   $0xf0107139
f0101c47:	e8 f4 e3 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101c4c:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101c51:	74 19                	je     f0101c6c <mem_init+0xa3c>
f0101c53:	68 5d 73 10 f0       	push   $0xf010735d
f0101c58:	68 5f 71 10 f0       	push   $0xf010715f
f0101c5d:	68 fd 03 00 00       	push   $0x3fd
f0101c62:	68 39 71 10 f0       	push   $0xf0107139
f0101c67:	e8 d4 e3 ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101c6c:	83 ec 04             	sub    $0x4,%esp
f0101c6f:	6a 00                	push   $0x0
f0101c71:	68 00 10 00 00       	push   $0x1000
f0101c76:	57                   	push   %edi
f0101c77:	e8 dd f2 ff ff       	call   f0100f59 <pgdir_walk>
f0101c7c:	83 c4 10             	add    $0x10,%esp
f0101c7f:	f6 00 04             	testb  $0x4,(%eax)
f0101c82:	75 19                	jne    f0101c9d <mem_init+0xa6d>
f0101c84:	68 78 6b 10 f0       	push   $0xf0106b78
f0101c89:	68 5f 71 10 f0       	push   $0xf010715f
f0101c8e:	68 fe 03 00 00       	push   $0x3fe
f0101c93:	68 39 71 10 f0       	push   $0xf0107139
f0101c98:	e8 a3 e3 ff ff       	call   f0100040 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101c9d:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
f0101ca2:	f6 00 04             	testb  $0x4,(%eax)
f0101ca5:	75 19                	jne    f0101cc0 <mem_init+0xa90>
f0101ca7:	68 6e 73 10 f0       	push   $0xf010736e
f0101cac:	68 5f 71 10 f0       	push   $0xf010715f
f0101cb1:	68 ff 03 00 00       	push   $0x3ff
f0101cb6:	68 39 71 10 f0       	push   $0xf0107139
f0101cbb:	e8 80 e3 ff ff       	call   f0100040 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101cc0:	6a 02                	push   $0x2
f0101cc2:	68 00 10 00 00       	push   $0x1000
f0101cc7:	56                   	push   %esi
f0101cc8:	50                   	push   %eax
f0101cc9:	e8 6e f4 ff ff       	call   f010113c <page_insert>
f0101cce:	83 c4 10             	add    $0x10,%esp
f0101cd1:	85 c0                	test   %eax,%eax
f0101cd3:	74 19                	je     f0101cee <mem_init+0xabe>
f0101cd5:	68 8c 6a 10 f0       	push   $0xf0106a8c
f0101cda:	68 5f 71 10 f0       	push   $0xf010715f
f0101cdf:	68 02 04 00 00       	push   $0x402
f0101ce4:	68 39 71 10 f0       	push   $0xf0107139
f0101ce9:	e8 52 e3 ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101cee:	83 ec 04             	sub    $0x4,%esp
f0101cf1:	6a 00                	push   $0x0
f0101cf3:	68 00 10 00 00       	push   $0x1000
f0101cf8:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0101cfe:	e8 56 f2 ff ff       	call   f0100f59 <pgdir_walk>
f0101d03:	83 c4 10             	add    $0x10,%esp
f0101d06:	f6 00 02             	testb  $0x2,(%eax)
f0101d09:	75 19                	jne    f0101d24 <mem_init+0xaf4>
f0101d0b:	68 ac 6b 10 f0       	push   $0xf0106bac
f0101d10:	68 5f 71 10 f0       	push   $0xf010715f
f0101d15:	68 03 04 00 00       	push   $0x403
f0101d1a:	68 39 71 10 f0       	push   $0xf0107139
f0101d1f:	e8 1c e3 ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101d24:	83 ec 04             	sub    $0x4,%esp
f0101d27:	6a 00                	push   $0x0
f0101d29:	68 00 10 00 00       	push   $0x1000
f0101d2e:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0101d34:	e8 20 f2 ff ff       	call   f0100f59 <pgdir_walk>
f0101d39:	83 c4 10             	add    $0x10,%esp
f0101d3c:	f6 00 04             	testb  $0x4,(%eax)
f0101d3f:	74 19                	je     f0101d5a <mem_init+0xb2a>
f0101d41:	68 e0 6b 10 f0       	push   $0xf0106be0
f0101d46:	68 5f 71 10 f0       	push   $0xf010715f
f0101d4b:	68 04 04 00 00       	push   $0x404
f0101d50:	68 39 71 10 f0       	push   $0xf0107139
f0101d55:	e8 e6 e2 ff ff       	call   f0100040 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101d5a:	6a 02                	push   $0x2
f0101d5c:	68 00 00 40 00       	push   $0x400000
f0101d61:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101d64:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0101d6a:	e8 cd f3 ff ff       	call   f010113c <page_insert>
f0101d6f:	83 c4 10             	add    $0x10,%esp
f0101d72:	85 c0                	test   %eax,%eax
f0101d74:	78 19                	js     f0101d8f <mem_init+0xb5f>
f0101d76:	68 18 6c 10 f0       	push   $0xf0106c18
f0101d7b:	68 5f 71 10 f0       	push   $0xf010715f
f0101d80:	68 07 04 00 00       	push   $0x407
f0101d85:	68 39 71 10 f0       	push   $0xf0107139
f0101d8a:	e8 b1 e2 ff ff       	call   f0100040 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101d8f:	6a 02                	push   $0x2
f0101d91:	68 00 10 00 00       	push   $0x1000
f0101d96:	53                   	push   %ebx
f0101d97:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0101d9d:	e8 9a f3 ff ff       	call   f010113c <page_insert>
f0101da2:	83 c4 10             	add    $0x10,%esp
f0101da5:	85 c0                	test   %eax,%eax
f0101da7:	74 19                	je     f0101dc2 <mem_init+0xb92>
f0101da9:	68 50 6c 10 f0       	push   $0xf0106c50
f0101dae:	68 5f 71 10 f0       	push   $0xf010715f
f0101db3:	68 0a 04 00 00       	push   $0x40a
f0101db8:	68 39 71 10 f0       	push   $0xf0107139
f0101dbd:	e8 7e e2 ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101dc2:	83 ec 04             	sub    $0x4,%esp
f0101dc5:	6a 00                	push   $0x0
f0101dc7:	68 00 10 00 00       	push   $0x1000
f0101dcc:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0101dd2:	e8 82 f1 ff ff       	call   f0100f59 <pgdir_walk>
f0101dd7:	83 c4 10             	add    $0x10,%esp
f0101dda:	f6 00 04             	testb  $0x4,(%eax)
f0101ddd:	74 19                	je     f0101df8 <mem_init+0xbc8>
f0101ddf:	68 e0 6b 10 f0       	push   $0xf0106be0
f0101de4:	68 5f 71 10 f0       	push   $0xf010715f
f0101de9:	68 0b 04 00 00       	push   $0x40b
f0101dee:	68 39 71 10 f0       	push   $0xf0107139
f0101df3:	e8 48 e2 ff ff       	call   f0100040 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101df8:	8b 3d 8c fe 22 f0    	mov    0xf022fe8c,%edi
f0101dfe:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e03:	89 f8                	mov    %edi,%eax
f0101e05:	e8 25 ec ff ff       	call   f0100a2f <check_va2pa>
f0101e0a:	89 c1                	mov    %eax,%ecx
f0101e0c:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101e0f:	89 d8                	mov    %ebx,%eax
f0101e11:	2b 05 90 fe 22 f0    	sub    0xf022fe90,%eax
f0101e17:	c1 f8 03             	sar    $0x3,%eax
f0101e1a:	c1 e0 0c             	shl    $0xc,%eax
f0101e1d:	39 c1                	cmp    %eax,%ecx
f0101e1f:	74 19                	je     f0101e3a <mem_init+0xc0a>
f0101e21:	68 8c 6c 10 f0       	push   $0xf0106c8c
f0101e26:	68 5f 71 10 f0       	push   $0xf010715f
f0101e2b:	68 0e 04 00 00       	push   $0x40e
f0101e30:	68 39 71 10 f0       	push   $0xf0107139
f0101e35:	e8 06 e2 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101e3a:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e3f:	89 f8                	mov    %edi,%eax
f0101e41:	e8 e9 eb ff ff       	call   f0100a2f <check_va2pa>
f0101e46:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101e49:	74 19                	je     f0101e64 <mem_init+0xc34>
f0101e4b:	68 b8 6c 10 f0       	push   $0xf0106cb8
f0101e50:	68 5f 71 10 f0       	push   $0xf010715f
f0101e55:	68 0f 04 00 00       	push   $0x40f
f0101e5a:	68 39 71 10 f0       	push   $0xf0107139
f0101e5f:	e8 dc e1 ff ff       	call   f0100040 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101e64:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101e69:	74 19                	je     f0101e84 <mem_init+0xc54>
f0101e6b:	68 84 73 10 f0       	push   $0xf0107384
f0101e70:	68 5f 71 10 f0       	push   $0xf010715f
f0101e75:	68 11 04 00 00       	push   $0x411
f0101e7a:	68 39 71 10 f0       	push   $0xf0107139
f0101e7f:	e8 bc e1 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f0101e84:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101e89:	74 19                	je     f0101ea4 <mem_init+0xc74>
f0101e8b:	68 95 73 10 f0       	push   $0xf0107395
f0101e90:	68 5f 71 10 f0       	push   $0xf010715f
f0101e95:	68 12 04 00 00       	push   $0x412
f0101e9a:	68 39 71 10 f0       	push   $0xf0107139
f0101e9f:	e8 9c e1 ff ff       	call   f0100040 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101ea4:	83 ec 0c             	sub    $0xc,%esp
f0101ea7:	6a 00                	push   $0x0
f0101ea9:	e8 d9 ef ff ff       	call   f0100e87 <page_alloc>
f0101eae:	83 c4 10             	add    $0x10,%esp
f0101eb1:	85 c0                	test   %eax,%eax
f0101eb3:	74 04                	je     f0101eb9 <mem_init+0xc89>
f0101eb5:	39 c6                	cmp    %eax,%esi
f0101eb7:	74 19                	je     f0101ed2 <mem_init+0xca2>
f0101eb9:	68 e8 6c 10 f0       	push   $0xf0106ce8
f0101ebe:	68 5f 71 10 f0       	push   $0xf010715f
f0101ec3:	68 15 04 00 00       	push   $0x415
f0101ec8:	68 39 71 10 f0       	push   $0xf0107139
f0101ecd:	e8 6e e1 ff ff       	call   f0100040 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101ed2:	83 ec 08             	sub    $0x8,%esp
f0101ed5:	6a 00                	push   $0x0
f0101ed7:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0101edd:	e8 01 f2 ff ff       	call   f01010e3 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101ee2:	8b 3d 8c fe 22 f0    	mov    0xf022fe8c,%edi
f0101ee8:	ba 00 00 00 00       	mov    $0x0,%edx
f0101eed:	89 f8                	mov    %edi,%eax
f0101eef:	e8 3b eb ff ff       	call   f0100a2f <check_va2pa>
f0101ef4:	83 c4 10             	add    $0x10,%esp
f0101ef7:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101efa:	74 19                	je     f0101f15 <mem_init+0xce5>
f0101efc:	68 0c 6d 10 f0       	push   $0xf0106d0c
f0101f01:	68 5f 71 10 f0       	push   $0xf010715f
f0101f06:	68 19 04 00 00       	push   $0x419
f0101f0b:	68 39 71 10 f0       	push   $0xf0107139
f0101f10:	e8 2b e1 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101f15:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101f1a:	89 f8                	mov    %edi,%eax
f0101f1c:	e8 0e eb ff ff       	call   f0100a2f <check_va2pa>
f0101f21:	89 da                	mov    %ebx,%edx
f0101f23:	2b 15 90 fe 22 f0    	sub    0xf022fe90,%edx
f0101f29:	c1 fa 03             	sar    $0x3,%edx
f0101f2c:	c1 e2 0c             	shl    $0xc,%edx
f0101f2f:	39 d0                	cmp    %edx,%eax
f0101f31:	74 19                	je     f0101f4c <mem_init+0xd1c>
f0101f33:	68 b8 6c 10 f0       	push   $0xf0106cb8
f0101f38:	68 5f 71 10 f0       	push   $0xf010715f
f0101f3d:	68 1a 04 00 00       	push   $0x41a
f0101f42:	68 39 71 10 f0       	push   $0xf0107139
f0101f47:	e8 f4 e0 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f0101f4c:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101f51:	74 19                	je     f0101f6c <mem_init+0xd3c>
f0101f53:	68 3b 73 10 f0       	push   $0xf010733b
f0101f58:	68 5f 71 10 f0       	push   $0xf010715f
f0101f5d:	68 1b 04 00 00       	push   $0x41b
f0101f62:	68 39 71 10 f0       	push   $0xf0107139
f0101f67:	e8 d4 e0 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f0101f6c:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101f71:	74 19                	je     f0101f8c <mem_init+0xd5c>
f0101f73:	68 95 73 10 f0       	push   $0xf0107395
f0101f78:	68 5f 71 10 f0       	push   $0xf010715f
f0101f7d:	68 1c 04 00 00       	push   $0x41c
f0101f82:	68 39 71 10 f0       	push   $0xf0107139
f0101f87:	e8 b4 e0 ff ff       	call   f0100040 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101f8c:	6a 00                	push   $0x0
f0101f8e:	68 00 10 00 00       	push   $0x1000
f0101f93:	53                   	push   %ebx
f0101f94:	57                   	push   %edi
f0101f95:	e8 a2 f1 ff ff       	call   f010113c <page_insert>
f0101f9a:	83 c4 10             	add    $0x10,%esp
f0101f9d:	85 c0                	test   %eax,%eax
f0101f9f:	74 19                	je     f0101fba <mem_init+0xd8a>
f0101fa1:	68 30 6d 10 f0       	push   $0xf0106d30
f0101fa6:	68 5f 71 10 f0       	push   $0xf010715f
f0101fab:	68 1f 04 00 00       	push   $0x41f
f0101fb0:	68 39 71 10 f0       	push   $0xf0107139
f0101fb5:	e8 86 e0 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref);
f0101fba:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101fbf:	75 19                	jne    f0101fda <mem_init+0xdaa>
f0101fc1:	68 a6 73 10 f0       	push   $0xf01073a6
f0101fc6:	68 5f 71 10 f0       	push   $0xf010715f
f0101fcb:	68 20 04 00 00       	push   $0x420
f0101fd0:	68 39 71 10 f0       	push   $0xf0107139
f0101fd5:	e8 66 e0 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_link == NULL);
f0101fda:	83 3b 00             	cmpl   $0x0,(%ebx)
f0101fdd:	74 19                	je     f0101ff8 <mem_init+0xdc8>
f0101fdf:	68 b2 73 10 f0       	push   $0xf01073b2
f0101fe4:	68 5f 71 10 f0       	push   $0xf010715f
f0101fe9:	68 21 04 00 00       	push   $0x421
f0101fee:	68 39 71 10 f0       	push   $0xf0107139
f0101ff3:	e8 48 e0 ff ff       	call   f0100040 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101ff8:	83 ec 08             	sub    $0x8,%esp
f0101ffb:	68 00 10 00 00       	push   $0x1000
f0102000:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0102006:	e8 d8 f0 ff ff       	call   f01010e3 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f010200b:	8b 3d 8c fe 22 f0    	mov    0xf022fe8c,%edi
f0102011:	ba 00 00 00 00       	mov    $0x0,%edx
f0102016:	89 f8                	mov    %edi,%eax
f0102018:	e8 12 ea ff ff       	call   f0100a2f <check_va2pa>
f010201d:	83 c4 10             	add    $0x10,%esp
f0102020:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102023:	74 19                	je     f010203e <mem_init+0xe0e>
f0102025:	68 0c 6d 10 f0       	push   $0xf0106d0c
f010202a:	68 5f 71 10 f0       	push   $0xf010715f
f010202f:	68 25 04 00 00       	push   $0x425
f0102034:	68 39 71 10 f0       	push   $0xf0107139
f0102039:	e8 02 e0 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f010203e:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102043:	89 f8                	mov    %edi,%eax
f0102045:	e8 e5 e9 ff ff       	call   f0100a2f <check_va2pa>
f010204a:	83 f8 ff             	cmp    $0xffffffff,%eax
f010204d:	74 19                	je     f0102068 <mem_init+0xe38>
f010204f:	68 68 6d 10 f0       	push   $0xf0106d68
f0102054:	68 5f 71 10 f0       	push   $0xf010715f
f0102059:	68 26 04 00 00       	push   $0x426
f010205e:	68 39 71 10 f0       	push   $0xf0107139
f0102063:	e8 d8 df ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f0102068:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f010206d:	74 19                	je     f0102088 <mem_init+0xe58>
f010206f:	68 c7 73 10 f0       	push   $0xf01073c7
f0102074:	68 5f 71 10 f0       	push   $0xf010715f
f0102079:	68 27 04 00 00       	push   $0x427
f010207e:	68 39 71 10 f0       	push   $0xf0107139
f0102083:	e8 b8 df ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f0102088:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f010208d:	74 19                	je     f01020a8 <mem_init+0xe78>
f010208f:	68 95 73 10 f0       	push   $0xf0107395
f0102094:	68 5f 71 10 f0       	push   $0xf010715f
f0102099:	68 28 04 00 00       	push   $0x428
f010209e:	68 39 71 10 f0       	push   $0xf0107139
f01020a3:	e8 98 df ff ff       	call   f0100040 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f01020a8:	83 ec 0c             	sub    $0xc,%esp
f01020ab:	6a 00                	push   $0x0
f01020ad:	e8 d5 ed ff ff       	call   f0100e87 <page_alloc>
f01020b2:	83 c4 10             	add    $0x10,%esp
f01020b5:	39 c3                	cmp    %eax,%ebx
f01020b7:	75 04                	jne    f01020bd <mem_init+0xe8d>
f01020b9:	85 c0                	test   %eax,%eax
f01020bb:	75 19                	jne    f01020d6 <mem_init+0xea6>
f01020bd:	68 90 6d 10 f0       	push   $0xf0106d90
f01020c2:	68 5f 71 10 f0       	push   $0xf010715f
f01020c7:	68 2b 04 00 00       	push   $0x42b
f01020cc:	68 39 71 10 f0       	push   $0xf0107139
f01020d1:	e8 6a df ff ff       	call   f0100040 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f01020d6:	83 ec 0c             	sub    $0xc,%esp
f01020d9:	6a 00                	push   $0x0
f01020db:	e8 a7 ed ff ff       	call   f0100e87 <page_alloc>
f01020e0:	83 c4 10             	add    $0x10,%esp
f01020e3:	85 c0                	test   %eax,%eax
f01020e5:	74 19                	je     f0102100 <mem_init+0xed0>
f01020e7:	68 e9 72 10 f0       	push   $0xf01072e9
f01020ec:	68 5f 71 10 f0       	push   $0xf010715f
f01020f1:	68 2e 04 00 00       	push   $0x42e
f01020f6:	68 39 71 10 f0       	push   $0xf0107139
f01020fb:	e8 40 df ff ff       	call   f0100040 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102100:	8b 0d 8c fe 22 f0    	mov    0xf022fe8c,%ecx
f0102106:	8b 11                	mov    (%ecx),%edx
f0102108:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010210e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102111:	2b 05 90 fe 22 f0    	sub    0xf022fe90,%eax
f0102117:	c1 f8 03             	sar    $0x3,%eax
f010211a:	c1 e0 0c             	shl    $0xc,%eax
f010211d:	39 c2                	cmp    %eax,%edx
f010211f:	74 19                	je     f010213a <mem_init+0xf0a>
f0102121:	68 34 6a 10 f0       	push   $0xf0106a34
f0102126:	68 5f 71 10 f0       	push   $0xf010715f
f010212b:	68 31 04 00 00       	push   $0x431
f0102130:	68 39 71 10 f0       	push   $0xf0107139
f0102135:	e8 06 df ff ff       	call   f0100040 <_panic>
	kern_pgdir[0] = 0;
f010213a:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102140:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102143:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0102148:	74 19                	je     f0102163 <mem_init+0xf33>
f010214a:	68 4c 73 10 f0       	push   $0xf010734c
f010214f:	68 5f 71 10 f0       	push   $0xf010715f
f0102154:	68 33 04 00 00       	push   $0x433
f0102159:	68 39 71 10 f0       	push   $0xf0107139
f010215e:	e8 dd de ff ff       	call   f0100040 <_panic>
	pp0->pp_ref = 0;
f0102163:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102166:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f010216c:	83 ec 0c             	sub    $0xc,%esp
f010216f:	50                   	push   %eax
f0102170:	e8 82 ed ff ff       	call   f0100ef7 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0102175:	83 c4 0c             	add    $0xc,%esp
f0102178:	6a 01                	push   $0x1
f010217a:	68 00 10 40 00       	push   $0x401000
f010217f:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0102185:	e8 cf ed ff ff       	call   f0100f59 <pgdir_walk>
f010218a:	89 c7                	mov    %eax,%edi
f010218c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f010218f:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
f0102194:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102197:	8b 40 04             	mov    0x4(%eax),%eax
f010219a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010219f:	8b 0d 88 fe 22 f0    	mov    0xf022fe88,%ecx
f01021a5:	89 c2                	mov    %eax,%edx
f01021a7:	c1 ea 0c             	shr    $0xc,%edx
f01021aa:	83 c4 10             	add    $0x10,%esp
f01021ad:	39 ca                	cmp    %ecx,%edx
f01021af:	72 15                	jb     f01021c6 <mem_init+0xf96>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01021b1:	50                   	push   %eax
f01021b2:	68 24 63 10 f0       	push   $0xf0106324
f01021b7:	68 3a 04 00 00       	push   $0x43a
f01021bc:	68 39 71 10 f0       	push   $0xf0107139
f01021c1:	e8 7a de ff ff       	call   f0100040 <_panic>
	assert(ptep == ptep1 + PTX(va));
f01021c6:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f01021cb:	39 c7                	cmp    %eax,%edi
f01021cd:	74 19                	je     f01021e8 <mem_init+0xfb8>
f01021cf:	68 d8 73 10 f0       	push   $0xf01073d8
f01021d4:	68 5f 71 10 f0       	push   $0xf010715f
f01021d9:	68 3b 04 00 00       	push   $0x43b
f01021de:	68 39 71 10 f0       	push   $0xf0107139
f01021e3:	e8 58 de ff ff       	call   f0100040 <_panic>
	kern_pgdir[PDX(va)] = 0;
f01021e8:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01021eb:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f01021f2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01021f5:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01021fb:	2b 05 90 fe 22 f0    	sub    0xf022fe90,%eax
f0102201:	c1 f8 03             	sar    $0x3,%eax
f0102204:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102207:	89 c2                	mov    %eax,%edx
f0102209:	c1 ea 0c             	shr    $0xc,%edx
f010220c:	39 d1                	cmp    %edx,%ecx
f010220e:	77 12                	ja     f0102222 <mem_init+0xff2>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102210:	50                   	push   %eax
f0102211:	68 24 63 10 f0       	push   $0xf0106324
f0102216:	6a 58                	push   $0x58
f0102218:	68 45 71 10 f0       	push   $0xf0107145
f010221d:	e8 1e de ff ff       	call   f0100040 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102222:	83 ec 04             	sub    $0x4,%esp
f0102225:	68 00 10 00 00       	push   $0x1000
f010222a:	68 ff 00 00 00       	push   $0xff
f010222f:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102234:	50                   	push   %eax
f0102235:	e8 ff 33 00 00       	call   f0105639 <memset>
	page_free(pp0);
f010223a:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010223d:	89 3c 24             	mov    %edi,(%esp)
f0102240:	e8 b2 ec ff ff       	call   f0100ef7 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0102245:	83 c4 0c             	add    $0xc,%esp
f0102248:	6a 01                	push   $0x1
f010224a:	6a 00                	push   $0x0
f010224c:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0102252:	e8 02 ed ff ff       	call   f0100f59 <pgdir_walk>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102257:	89 fa                	mov    %edi,%edx
f0102259:	2b 15 90 fe 22 f0    	sub    0xf022fe90,%edx
f010225f:	c1 fa 03             	sar    $0x3,%edx
f0102262:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102265:	89 d0                	mov    %edx,%eax
f0102267:	c1 e8 0c             	shr    $0xc,%eax
f010226a:	83 c4 10             	add    $0x10,%esp
f010226d:	3b 05 88 fe 22 f0    	cmp    0xf022fe88,%eax
f0102273:	72 12                	jb     f0102287 <mem_init+0x1057>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102275:	52                   	push   %edx
f0102276:	68 24 63 10 f0       	push   $0xf0106324
f010227b:	6a 58                	push   $0x58
f010227d:	68 45 71 10 f0       	push   $0xf0107145
f0102282:	e8 b9 dd ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0102287:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f010228d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102290:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102296:	f6 00 01             	testb  $0x1,(%eax)
f0102299:	74 19                	je     f01022b4 <mem_init+0x1084>
f010229b:	68 f0 73 10 f0       	push   $0xf01073f0
f01022a0:	68 5f 71 10 f0       	push   $0xf010715f
f01022a5:	68 45 04 00 00       	push   $0x445
f01022aa:	68 39 71 10 f0       	push   $0xf0107139
f01022af:	e8 8c dd ff ff       	call   f0100040 <_panic>
f01022b4:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f01022b7:	39 d0                	cmp    %edx,%eax
f01022b9:	75 db                	jne    f0102296 <mem_init+0x1066>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f01022bb:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
f01022c0:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f01022c6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01022c9:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f01022cf:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f01022d2:	89 0d 40 f2 22 f0    	mov    %ecx,0xf022f240

	// free the pages we took
	page_free(pp0);
f01022d8:	83 ec 0c             	sub    $0xc,%esp
f01022db:	50                   	push   %eax
f01022dc:	e8 16 ec ff ff       	call   f0100ef7 <page_free>
	page_free(pp1);
f01022e1:	89 1c 24             	mov    %ebx,(%esp)
f01022e4:	e8 0e ec ff ff       	call   f0100ef7 <page_free>
	page_free(pp2);
f01022e9:	89 34 24             	mov    %esi,(%esp)
f01022ec:	e8 06 ec ff ff       	call   f0100ef7 <page_free>

	// test mmio_map_region
	mm1 = (uintptr_t) mmio_map_region(0, 4097);
f01022f1:	83 c4 08             	add    $0x8,%esp
f01022f4:	68 01 10 00 00       	push   $0x1001
f01022f9:	6a 00                	push   $0x0
f01022fb:	e8 c6 ee ff ff       	call   f01011c6 <mmio_map_region>
f0102300:	89 c3                	mov    %eax,%ebx
	mm2 = (uintptr_t) mmio_map_region(0, 4096);
f0102302:	83 c4 08             	add    $0x8,%esp
f0102305:	68 00 10 00 00       	push   $0x1000
f010230a:	6a 00                	push   $0x0
f010230c:	e8 b5 ee ff ff       	call   f01011c6 <mmio_map_region>
f0102311:	89 c6                	mov    %eax,%esi
	// check that they're in the right region
	assert(mm1 >= MMIOBASE && mm1 + 8096 < MMIOLIM);
f0102313:	8d 83 a0 1f 00 00    	lea    0x1fa0(%ebx),%eax
f0102319:	83 c4 10             	add    $0x10,%esp
f010231c:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f0102322:	76 07                	jbe    f010232b <mem_init+0x10fb>
f0102324:	3d ff ff bf ef       	cmp    $0xefbfffff,%eax
f0102329:	76 19                	jbe    f0102344 <mem_init+0x1114>
f010232b:	68 b4 6d 10 f0       	push   $0xf0106db4
f0102330:	68 5f 71 10 f0       	push   $0xf010715f
f0102335:	68 55 04 00 00       	push   $0x455
f010233a:	68 39 71 10 f0       	push   $0xf0107139
f010233f:	e8 fc dc ff ff       	call   f0100040 <_panic>
	assert(mm2 >= MMIOBASE && mm2 + 8096 < MMIOLIM);
f0102344:	8d 96 a0 1f 00 00    	lea    0x1fa0(%esi),%edx
f010234a:	81 fa ff ff bf ef    	cmp    $0xefbfffff,%edx
f0102350:	77 08                	ja     f010235a <mem_init+0x112a>
f0102352:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0102358:	77 19                	ja     f0102373 <mem_init+0x1143>
f010235a:	68 dc 6d 10 f0       	push   $0xf0106ddc
f010235f:	68 5f 71 10 f0       	push   $0xf010715f
f0102364:	68 56 04 00 00       	push   $0x456
f0102369:	68 39 71 10 f0       	push   $0xf0107139
f010236e:	e8 cd dc ff ff       	call   f0100040 <_panic>
	// check that they're page-aligned
	assert(mm1 % PGSIZE == 0 && mm2 % PGSIZE == 0);
f0102373:	89 da                	mov    %ebx,%edx
f0102375:	09 f2                	or     %esi,%edx
f0102377:	f7 c2 ff 0f 00 00    	test   $0xfff,%edx
f010237d:	74 19                	je     f0102398 <mem_init+0x1168>
f010237f:	68 04 6e 10 f0       	push   $0xf0106e04
f0102384:	68 5f 71 10 f0       	push   $0xf010715f
f0102389:	68 58 04 00 00       	push   $0x458
f010238e:	68 39 71 10 f0       	push   $0xf0107139
f0102393:	e8 a8 dc ff ff       	call   f0100040 <_panic>
	// check that they don't overlap
	assert(mm1 + 8096 <= mm2);
f0102398:	39 c6                	cmp    %eax,%esi
f010239a:	73 19                	jae    f01023b5 <mem_init+0x1185>
f010239c:	68 07 74 10 f0       	push   $0xf0107407
f01023a1:	68 5f 71 10 f0       	push   $0xf010715f
f01023a6:	68 5a 04 00 00       	push   $0x45a
f01023ab:	68 39 71 10 f0       	push   $0xf0107139
f01023b0:	e8 8b dc ff ff       	call   f0100040 <_panic>
	// check page mappings
	assert(check_va2pa(kern_pgdir, mm1) == 0);
f01023b5:	8b 3d 8c fe 22 f0    	mov    0xf022fe8c,%edi
f01023bb:	89 da                	mov    %ebx,%edx
f01023bd:	89 f8                	mov    %edi,%eax
f01023bf:	e8 6b e6 ff ff       	call   f0100a2f <check_va2pa>
f01023c4:	85 c0                	test   %eax,%eax
f01023c6:	74 19                	je     f01023e1 <mem_init+0x11b1>
f01023c8:	68 2c 6e 10 f0       	push   $0xf0106e2c
f01023cd:	68 5f 71 10 f0       	push   $0xf010715f
f01023d2:	68 5c 04 00 00       	push   $0x45c
f01023d7:	68 39 71 10 f0       	push   $0xf0107139
f01023dc:	e8 5f dc ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm1+PGSIZE) == PGSIZE);
f01023e1:	8d 83 00 10 00 00    	lea    0x1000(%ebx),%eax
f01023e7:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01023ea:	89 c2                	mov    %eax,%edx
f01023ec:	89 f8                	mov    %edi,%eax
f01023ee:	e8 3c e6 ff ff       	call   f0100a2f <check_va2pa>
f01023f3:	3d 00 10 00 00       	cmp    $0x1000,%eax
f01023f8:	74 19                	je     f0102413 <mem_init+0x11e3>
f01023fa:	68 50 6e 10 f0       	push   $0xf0106e50
f01023ff:	68 5f 71 10 f0       	push   $0xf010715f
f0102404:	68 5d 04 00 00       	push   $0x45d
f0102409:	68 39 71 10 f0       	push   $0xf0107139
f010240e:	e8 2d dc ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2) == 0);
f0102413:	89 f2                	mov    %esi,%edx
f0102415:	89 f8                	mov    %edi,%eax
f0102417:	e8 13 e6 ff ff       	call   f0100a2f <check_va2pa>
f010241c:	85 c0                	test   %eax,%eax
f010241e:	74 19                	je     f0102439 <mem_init+0x1209>
f0102420:	68 80 6e 10 f0       	push   $0xf0106e80
f0102425:	68 5f 71 10 f0       	push   $0xf010715f
f010242a:	68 5e 04 00 00       	push   $0x45e
f010242f:	68 39 71 10 f0       	push   $0xf0107139
f0102434:	e8 07 dc ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2+PGSIZE) == ~0);
f0102439:	8d 96 00 10 00 00    	lea    0x1000(%esi),%edx
f010243f:	89 f8                	mov    %edi,%eax
f0102441:	e8 e9 e5 ff ff       	call   f0100a2f <check_va2pa>
f0102446:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102449:	74 19                	je     f0102464 <mem_init+0x1234>
f010244b:	68 a4 6e 10 f0       	push   $0xf0106ea4
f0102450:	68 5f 71 10 f0       	push   $0xf010715f
f0102455:	68 5f 04 00 00       	push   $0x45f
f010245a:	68 39 71 10 f0       	push   $0xf0107139
f010245f:	e8 dc db ff ff       	call   f0100040 <_panic>
	// check permissions
	assert(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & (PTE_W|PTE_PWT|PTE_PCD));
f0102464:	83 ec 04             	sub    $0x4,%esp
f0102467:	6a 00                	push   $0x0
f0102469:	53                   	push   %ebx
f010246a:	57                   	push   %edi
f010246b:	e8 e9 ea ff ff       	call   f0100f59 <pgdir_walk>
f0102470:	83 c4 10             	add    $0x10,%esp
f0102473:	f6 00 1a             	testb  $0x1a,(%eax)
f0102476:	75 19                	jne    f0102491 <mem_init+0x1261>
f0102478:	68 d0 6e 10 f0       	push   $0xf0106ed0
f010247d:	68 5f 71 10 f0       	push   $0xf010715f
f0102482:	68 61 04 00 00       	push   $0x461
f0102487:	68 39 71 10 f0       	push   $0xf0107139
f010248c:	e8 af db ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & PTE_U));
f0102491:	83 ec 04             	sub    $0x4,%esp
f0102494:	6a 00                	push   $0x0
f0102496:	53                   	push   %ebx
f0102497:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f010249d:	e8 b7 ea ff ff       	call   f0100f59 <pgdir_walk>
f01024a2:	8b 00                	mov    (%eax),%eax
f01024a4:	83 c4 10             	add    $0x10,%esp
f01024a7:	83 e0 04             	and    $0x4,%eax
f01024aa:	89 45 c8             	mov    %eax,-0x38(%ebp)
f01024ad:	74 19                	je     f01024c8 <mem_init+0x1298>
f01024af:	68 14 6f 10 f0       	push   $0xf0106f14
f01024b4:	68 5f 71 10 f0       	push   $0xf010715f
f01024b9:	68 62 04 00 00       	push   $0x462
f01024be:	68 39 71 10 f0       	push   $0xf0107139
f01024c3:	e8 78 db ff ff       	call   f0100040 <_panic>
	// clear the mappings
	*pgdir_walk(kern_pgdir, (void*) mm1, 0) = 0;
f01024c8:	83 ec 04             	sub    $0x4,%esp
f01024cb:	6a 00                	push   $0x0
f01024cd:	53                   	push   %ebx
f01024ce:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f01024d4:	e8 80 ea ff ff       	call   f0100f59 <pgdir_walk>
f01024d9:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm1 + PGSIZE, 0) = 0;
f01024df:	83 c4 0c             	add    $0xc,%esp
f01024e2:	6a 00                	push   $0x0
f01024e4:	ff 75 d4             	pushl  -0x2c(%ebp)
f01024e7:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f01024ed:	e8 67 ea ff ff       	call   f0100f59 <pgdir_walk>
f01024f2:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm2, 0) = 0;
f01024f8:	83 c4 0c             	add    $0xc,%esp
f01024fb:	6a 00                	push   $0x0
f01024fd:	56                   	push   %esi
f01024fe:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0102504:	e8 50 ea ff ff       	call   f0100f59 <pgdir_walk>
f0102509:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

	cprintf("check_page() succeeded!\n");
f010250f:	c7 04 24 19 74 10 f0 	movl   $0xf0107419,(%esp)
f0102516:	e8 41 12 00 00       	call   f010375c <cprintf>
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	int perm = PTE_U | PTE_P;
	int i=0;
	 n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f010251b:	a1 88 fe 22 f0       	mov    0xf022fe88,%eax
f0102520:	8d 1c c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%ebx
f0102527:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	 boot_map_region(kern_pgdir, UPAGES, n, PADDR(pages), perm);
f010252d:	a1 90 fe 22 f0       	mov    0xf022fe90,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102532:	83 c4 10             	add    $0x10,%esp
f0102535:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010253a:	77 15                	ja     f0102551 <mem_init+0x1321>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010253c:	50                   	push   %eax
f010253d:	68 48 63 10 f0       	push   $0xf0106348
f0102542:	68 bd 00 00 00       	push   $0xbd
f0102547:	68 39 71 10 f0       	push   $0xf0107139
f010254c:	e8 ef da ff ff       	call   f0100040 <_panic>
f0102551:	83 ec 08             	sub    $0x8,%esp
f0102554:	6a 05                	push   $0x5
f0102556:	05 00 00 00 10       	add    $0x10000000,%eax
f010255b:	50                   	push   %eax
f010255c:	89 d9                	mov    %ebx,%ecx
f010255e:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102563:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
f0102568:	e8 84 ea ff ff       	call   f0100ff1 <boot_map_region>
	 boot_map_region(kern_pgdir, (pte_t) pages, n, PADDR(pages), (PTE_W | PTE_P) );
f010256d:	8b 15 90 fe 22 f0    	mov    0xf022fe90,%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102573:	83 c4 10             	add    $0x10,%esp
f0102576:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f010257c:	77 15                	ja     f0102593 <mem_init+0x1363>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010257e:	52                   	push   %edx
f010257f:	68 48 63 10 f0       	push   $0xf0106348
f0102584:	68 be 00 00 00       	push   $0xbe
f0102589:	68 39 71 10 f0       	push   $0xf0107139
f010258e:	e8 ad da ff ff       	call   f0100040 <_panic>
f0102593:	83 ec 08             	sub    $0x8,%esp
f0102596:	6a 03                	push   $0x3
f0102598:	8d 82 00 00 00 10    	lea    0x10000000(%edx),%eax
f010259e:	50                   	push   %eax
f010259f:	89 d9                	mov    %ebx,%ecx
f01025a1:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
f01025a6:	e8 46 ea ff ff       	call   f0100ff1 <boot_map_region>
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.
	 perm = 0x0 | PTE_U | PTE_P;
	n = ROUNDUP(NENV*sizeof(struct Env) , PGSIZE);
	boot_map_region(kern_pgdir, UENVS, n, PADDR(envs), perm);
f01025ab:	a1 48 f2 22 f0       	mov    0xf022f248,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01025b0:	83 c4 10             	add    $0x10,%esp
f01025b3:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01025b8:	77 15                	ja     f01025cf <mem_init+0x139f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01025ba:	50                   	push   %eax
f01025bb:	68 48 63 10 f0       	push   $0xf0106348
f01025c0:	68 c8 00 00 00       	push   $0xc8
f01025c5:	68 39 71 10 f0       	push   $0xf0107139
f01025ca:	e8 71 da ff ff       	call   f0100040 <_panic>
f01025cf:	83 ec 08             	sub    $0x8,%esp
f01025d2:	6a 05                	push   $0x5
f01025d4:	05 00 00 00 10       	add    $0x10000000,%eax
f01025d9:	50                   	push   %eax
f01025da:	b9 00 f0 01 00       	mov    $0x1f000,%ecx
f01025df:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f01025e4:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
f01025e9:	e8 03 ea ff ff       	call   f0100ff1 <boot_map_region>
	boot_map_region(kern_pgdir, (pte_t) envs, n, PADDR(envs), (PTE_W | PTE_P));
f01025ee:	8b 15 48 f2 22 f0    	mov    0xf022f248,%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01025f4:	83 c4 10             	add    $0x10,%esp
f01025f7:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f01025fd:	77 15                	ja     f0102614 <mem_init+0x13e4>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01025ff:	52                   	push   %edx
f0102600:	68 48 63 10 f0       	push   $0xf0106348
f0102605:	68 c9 00 00 00       	push   $0xc9
f010260a:	68 39 71 10 f0       	push   $0xf0107139
f010260f:	e8 2c da ff ff       	call   f0100040 <_panic>
f0102614:	83 ec 08             	sub    $0x8,%esp
f0102617:	6a 03                	push   $0x3
f0102619:	8d 82 00 00 00 10    	lea    0x10000000(%edx),%eax
f010261f:	50                   	push   %eax
f0102620:	b9 00 f0 01 00       	mov    $0x1f000,%ecx
f0102625:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
f010262a:	e8 c2 e9 ff ff       	call   f0100ff1 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010262f:	83 c4 10             	add    $0x10,%esp
f0102632:	b8 00 60 11 f0       	mov    $0xf0116000,%eax
f0102637:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010263c:	77 15                	ja     f0102653 <mem_init+0x1423>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010263e:	50                   	push   %eax
f010263f:	68 48 63 10 f0       	push   $0xf0106348
f0102644:	68 d7 00 00 00       	push   $0xd7
f0102649:	68 39 71 10 f0       	push   $0xf0107139
f010264e:	e8 ed d9 ff ff       	call   f0100040 <_panic>
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	perm =0;
	perm = PTE_P |PTE_W;
	boot_map_region(kern_pgdir, KSTACKTOP-KSTKSIZE, ROUNDUP(KSTKSIZE, PGSIZE), PADDR(bootstack), perm);
f0102653:	83 ec 08             	sub    $0x8,%esp
f0102656:	6a 03                	push   $0x3
f0102658:	68 00 60 11 00       	push   $0x116000
f010265d:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102662:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f0102667:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
f010266c:	e8 80 e9 ff ff       	call   f0100ff1 <boot_map_region>
	int size = ~0;
	size = size - KERNBASE +1;
	size = ROUNDUP(size, PGSIZE);
	perm = 0;
	perm = PTE_P | PTE_W;
	boot_map_region(kern_pgdir, KERNBASE, size, 0, perm );
f0102671:	83 c4 08             	add    $0x8,%esp
f0102674:	6a 03                	push   $0x3
f0102676:	6a 00                	push   $0x0
f0102678:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f010267d:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0102682:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
f0102687:	e8 65 e9 ff ff       	call   f0100ff1 <boot_map_region>
f010268c:	c7 45 c4 00 10 23 f0 	movl   $0xf0231000,-0x3c(%ebp)
f0102693:	83 c4 10             	add    $0x10,%esp
f0102696:	bb 00 10 23 f0       	mov    $0xf0231000,%ebx
f010269b:	be 00 80 ff ef       	mov    $0xefff8000,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01026a0:	81 fb ff ff ff ef    	cmp    $0xefffffff,%ebx
f01026a6:	77 15                	ja     f01026bd <mem_init+0x148d>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01026a8:	53                   	push   %ebx
f01026a9:	68 48 63 10 f0       	push   $0xf0106348
f01026ae:	68 24 01 00 00       	push   $0x124
f01026b3:	68 39 71 10 f0       	push   $0xf0107139
f01026b8:	e8 83 d9 ff ff       	call   f0100040 <_panic>
    for (i = 0; i < NCPU; i++)
    {
        kstacktop_i = KSTACKTOP - i * (KSTKSIZE + KSTKGAP);
        //boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)

        boot_map_region(kern_pgdir,
f01026bd:	83 ec 08             	sub    $0x8,%esp
f01026c0:	6a 02                	push   $0x2
f01026c2:	8d 83 00 00 00 10    	lea    0x10000000(%ebx),%eax
f01026c8:	50                   	push   %eax
f01026c9:	b9 00 80 00 00       	mov    $0x8000,%ecx
f01026ce:	89 f2                	mov    %esi,%edx
f01026d0:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
f01026d5:	e8 17 e9 ff ff       	call   f0100ff1 <boot_map_region>
f01026da:	81 c3 00 80 00 00    	add    $0x8000,%ebx
f01026e0:	81 ee 00 00 01 00    	sub    $0x10000,%esi
	//
	// LAB 4: Your code here:
	 int i = 0;
    uintptr_t kstacktop_i;
    
    for (i = 0; i < NCPU; i++)
f01026e6:	83 c4 10             	add    $0x10,%esp
f01026e9:	b8 00 10 27 f0       	mov    $0xf0271000,%eax
f01026ee:	39 d8                	cmp    %ebx,%eax
f01026f0:	75 ae                	jne    f01026a0 <mem_init+0x1470>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f01026f2:	8b 3d 8c fe 22 f0    	mov    0xf022fe8c,%edi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f01026f8:	a1 88 fe 22 f0       	mov    0xf022fe88,%eax
f01026fd:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102700:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0102707:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010270c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f010270f:	8b 35 90 fe 22 f0    	mov    0xf022fe90,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102715:	89 75 d0             	mov    %esi,-0x30(%ebp)

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102718:	bb 00 00 00 00       	mov    $0x0,%ebx
f010271d:	eb 55                	jmp    f0102774 <mem_init+0x1544>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f010271f:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
f0102725:	89 f8                	mov    %edi,%eax
f0102727:	e8 03 e3 ff ff       	call   f0100a2f <check_va2pa>
f010272c:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f0102733:	77 15                	ja     f010274a <mem_init+0x151a>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102735:	56                   	push   %esi
f0102736:	68 48 63 10 f0       	push   $0xf0106348
f010273b:	68 7a 03 00 00       	push   $0x37a
f0102740:	68 39 71 10 f0       	push   $0xf0107139
f0102745:	e8 f6 d8 ff ff       	call   f0100040 <_panic>
f010274a:	8d 94 1e 00 00 00 10 	lea    0x10000000(%esi,%ebx,1),%edx
f0102751:	39 c2                	cmp    %eax,%edx
f0102753:	74 19                	je     f010276e <mem_init+0x153e>
f0102755:	68 48 6f 10 f0       	push   $0xf0106f48
f010275a:	68 5f 71 10 f0       	push   $0xf010715f
f010275f:	68 7a 03 00 00       	push   $0x37a
f0102764:	68 39 71 10 f0       	push   $0xf0107139
f0102769:	e8 d2 d8 ff ff       	call   f0100040 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f010276e:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102774:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0102777:	77 a6                	ja     f010271f <mem_init+0x14ef>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0102779:	8b 35 48 f2 22 f0    	mov    0xf022f248,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010277f:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f0102782:	bb 00 00 c0 ee       	mov    $0xeec00000,%ebx
f0102787:	89 da                	mov    %ebx,%edx
f0102789:	89 f8                	mov    %edi,%eax
f010278b:	e8 9f e2 ff ff       	call   f0100a2f <check_va2pa>
f0102790:	81 7d d4 ff ff ff ef 	cmpl   $0xefffffff,-0x2c(%ebp)
f0102797:	77 15                	ja     f01027ae <mem_init+0x157e>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102799:	56                   	push   %esi
f010279a:	68 48 63 10 f0       	push   $0xf0106348
f010279f:	68 7f 03 00 00       	push   $0x37f
f01027a4:	68 39 71 10 f0       	push   $0xf0107139
f01027a9:	e8 92 d8 ff ff       	call   f0100040 <_panic>
f01027ae:	8d 94 1e 00 00 40 21 	lea    0x21400000(%esi,%ebx,1),%edx
f01027b5:	39 d0                	cmp    %edx,%eax
f01027b7:	74 19                	je     f01027d2 <mem_init+0x15a2>
f01027b9:	68 7c 6f 10 f0       	push   $0xf0106f7c
f01027be:	68 5f 71 10 f0       	push   $0xf010715f
f01027c3:	68 7f 03 00 00       	push   $0x37f
f01027c8:	68 39 71 10 f0       	push   $0xf0107139
f01027cd:	e8 6e d8 ff ff       	call   f0100040 <_panic>
f01027d2:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01027d8:	81 fb 00 f0 c1 ee    	cmp    $0xeec1f000,%ebx
f01027de:	75 a7                	jne    f0102787 <mem_init+0x1557>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01027e0:	8b 75 cc             	mov    -0x34(%ebp),%esi
f01027e3:	c1 e6 0c             	shl    $0xc,%esi
f01027e6:	bb 00 00 00 00       	mov    $0x0,%ebx
f01027eb:	eb 30                	jmp    f010281d <mem_init+0x15ed>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f01027ed:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
f01027f3:	89 f8                	mov    %edi,%eax
f01027f5:	e8 35 e2 ff ff       	call   f0100a2f <check_va2pa>
f01027fa:	39 c3                	cmp    %eax,%ebx
f01027fc:	74 19                	je     f0102817 <mem_init+0x15e7>
f01027fe:	68 b0 6f 10 f0       	push   $0xf0106fb0
f0102803:	68 5f 71 10 f0       	push   $0xf010715f
f0102808:	68 83 03 00 00       	push   $0x383
f010280d:	68 39 71 10 f0       	push   $0xf0107139
f0102812:	e8 29 d8 ff ff       	call   f0100040 <_panic>
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102817:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f010281d:	39 f3                	cmp    %esi,%ebx
f010281f:	72 cc                	jb     f01027ed <mem_init+0x15bd>
f0102821:	be 00 80 ff ef       	mov    $0xefff8000,%esi
f0102826:	89 75 cc             	mov    %esi,-0x34(%ebp)
f0102829:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f010282c:	8b 45 cc             	mov    -0x34(%ebp),%eax
f010282f:	8d 88 00 80 00 00    	lea    0x8000(%eax),%ecx
f0102835:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0102838:	89 c3                	mov    %eax,%ebx
	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
f010283a:	8b 45 c8             	mov    -0x38(%ebp),%eax
f010283d:	05 00 80 00 20       	add    $0x20008000,%eax
f0102842:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102845:	89 da                	mov    %ebx,%edx
f0102847:	89 f8                	mov    %edi,%eax
f0102849:	e8 e1 e1 ff ff       	call   f0100a2f <check_va2pa>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010284e:	81 fe ff ff ff ef    	cmp    $0xefffffff,%esi
f0102854:	77 15                	ja     f010286b <mem_init+0x163b>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102856:	56                   	push   %esi
f0102857:	68 48 63 10 f0       	push   $0xf0106348
f010285c:	68 8b 03 00 00       	push   $0x38b
f0102861:	68 39 71 10 f0       	push   $0xf0107139
f0102866:	e8 d5 d7 ff ff       	call   f0100040 <_panic>
f010286b:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f010286e:	8d 94 0b 00 10 23 f0 	lea    -0xfdcf000(%ebx,%ecx,1),%edx
f0102875:	39 d0                	cmp    %edx,%eax
f0102877:	74 19                	je     f0102892 <mem_init+0x1662>
f0102879:	68 d8 6f 10 f0       	push   $0xf0106fd8
f010287e:	68 5f 71 10 f0       	push   $0xf010715f
f0102883:	68 8b 03 00 00       	push   $0x38b
f0102888:	68 39 71 10 f0       	push   $0xf0107139
f010288d:	e8 ae d7 ff ff       	call   f0100040 <_panic>
f0102892:	81 c3 00 10 00 00    	add    $0x1000,%ebx

	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102898:	3b 5d d4             	cmp    -0x2c(%ebp),%ebx
f010289b:	75 a8                	jne    f0102845 <mem_init+0x1615>
f010289d:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01028a0:	8d 98 00 80 ff ff    	lea    -0x8000(%eax),%ebx
f01028a6:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f01028a9:	89 c6                	mov    %eax,%esi
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
				== PADDR(percpu_kstacks[n]) + i);
		for (i = 0; i < KSTKGAP; i += PGSIZE)
			assert(check_va2pa(pgdir, base + i) == ~0);
f01028ab:	89 da                	mov    %ebx,%edx
f01028ad:	89 f8                	mov    %edi,%eax
f01028af:	e8 7b e1 ff ff       	call   f0100a2f <check_va2pa>
f01028b4:	83 f8 ff             	cmp    $0xffffffff,%eax
f01028b7:	74 19                	je     f01028d2 <mem_init+0x16a2>
f01028b9:	68 20 70 10 f0       	push   $0xf0107020
f01028be:	68 5f 71 10 f0       	push   $0xf010715f
f01028c3:	68 8d 03 00 00       	push   $0x38d
f01028c8:	68 39 71 10 f0       	push   $0xf0107139
f01028cd:	e8 6e d7 ff ff       	call   f0100040 <_panic>
f01028d2:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
				== PADDR(percpu_kstacks[n]) + i);
		for (i = 0; i < KSTKGAP; i += PGSIZE)
f01028d8:	39 de                	cmp    %ebx,%esi
f01028da:	75 cf                	jne    f01028ab <mem_init+0x167b>
f01028dc:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f01028df:	81 6d cc 00 00 01 00 	subl   $0x10000,-0x34(%ebp)
f01028e6:	81 45 c8 00 80 01 00 	addl   $0x18000,-0x38(%ebp)
f01028ed:	81 c6 00 80 00 00    	add    $0x8000,%esi
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
f01028f3:	81 fe 00 10 27 f0    	cmp    $0xf0271000,%esi
f01028f9:	0f 85 2d ff ff ff    	jne    f010282c <mem_init+0x15fc>
f01028ff:	b8 00 00 00 00       	mov    $0x0,%eax
f0102904:	eb 2a                	jmp    f0102930 <mem_init+0x1700>
			assert(check_va2pa(pgdir, base + i) == ~0);
	}

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f0102906:	8d 90 45 fc ff ff    	lea    -0x3bb(%eax),%edx
f010290c:	83 fa 04             	cmp    $0x4,%edx
f010290f:	77 1f                	ja     f0102930 <mem_init+0x1700>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
		case PDX(UENVS):
		case PDX(MMIOBASE):
			assert(pgdir[i] & PTE_P);
f0102911:	f6 04 87 01          	testb  $0x1,(%edi,%eax,4)
f0102915:	75 7e                	jne    f0102995 <mem_init+0x1765>
f0102917:	68 32 74 10 f0       	push   $0xf0107432
f010291c:	68 5f 71 10 f0       	push   $0xf010715f
f0102921:	68 98 03 00 00       	push   $0x398
f0102926:	68 39 71 10 f0       	push   $0xf0107139
f010292b:	e8 10 d7 ff ff       	call   f0100040 <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f0102930:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102935:	76 3f                	jbe    f0102976 <mem_init+0x1746>
				assert(pgdir[i] & PTE_P);
f0102937:	8b 14 87             	mov    (%edi,%eax,4),%edx
f010293a:	f6 c2 01             	test   $0x1,%dl
f010293d:	75 19                	jne    f0102958 <mem_init+0x1728>
f010293f:	68 32 74 10 f0       	push   $0xf0107432
f0102944:	68 5f 71 10 f0       	push   $0xf010715f
f0102949:	68 9c 03 00 00       	push   $0x39c
f010294e:	68 39 71 10 f0       	push   $0xf0107139
f0102953:	e8 e8 d6 ff ff       	call   f0100040 <_panic>
				assert(pgdir[i] & PTE_W);
f0102958:	f6 c2 02             	test   $0x2,%dl
f010295b:	75 38                	jne    f0102995 <mem_init+0x1765>
f010295d:	68 43 74 10 f0       	push   $0xf0107443
f0102962:	68 5f 71 10 f0       	push   $0xf010715f
f0102967:	68 9d 03 00 00       	push   $0x39d
f010296c:	68 39 71 10 f0       	push   $0xf0107139
f0102971:	e8 ca d6 ff ff       	call   f0100040 <_panic>
			} else
				assert(pgdir[i] == 0);
f0102976:	83 3c 87 00          	cmpl   $0x0,(%edi,%eax,4)
f010297a:	74 19                	je     f0102995 <mem_init+0x1765>
f010297c:	68 54 74 10 f0       	push   $0xf0107454
f0102981:	68 5f 71 10 f0       	push   $0xf010715f
f0102986:	68 9f 03 00 00       	push   $0x39f
f010298b:	68 39 71 10 f0       	push   $0xf0107139
f0102990:	e8 ab d6 ff ff       	call   f0100040 <_panic>
		for (i = 0; i < KSTKGAP; i += PGSIZE)
			assert(check_va2pa(pgdir, base + i) == ~0);
	}

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0102995:	83 c0 01             	add    $0x1,%eax
f0102998:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f010299d:	0f 86 63 ff ff ff    	jbe    f0102906 <mem_init+0x16d6>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f01029a3:	83 ec 0c             	sub    $0xc,%esp
f01029a6:	68 44 70 10 f0       	push   $0xf0107044
f01029ab:	e8 ac 0d 00 00       	call   f010375c <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f01029b0:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01029b5:	83 c4 10             	add    $0x10,%esp
f01029b8:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01029bd:	77 15                	ja     f01029d4 <mem_init+0x17a4>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01029bf:	50                   	push   %eax
f01029c0:	68 48 63 10 f0       	push   $0xf0106348
f01029c5:	68 f4 00 00 00       	push   $0xf4
f01029ca:	68 39 71 10 f0       	push   $0xf0107139
f01029cf:	e8 6c d6 ff ff       	call   f0100040 <_panic>
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f01029d4:	05 00 00 00 10       	add    $0x10000000,%eax
f01029d9:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f01029dc:	b8 00 00 00 00       	mov    $0x0,%eax
f01029e1:	e8 ad e0 ff ff       	call   f0100a93 <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f01029e6:	0f 20 c0             	mov    %cr0,%eax
f01029e9:	83 e0 f3             	and    $0xfffffff3,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f01029ec:	0d 23 00 05 80       	or     $0x80050023,%eax
f01029f1:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01029f4:	83 ec 0c             	sub    $0xc,%esp
f01029f7:	6a 00                	push   $0x0
f01029f9:	e8 89 e4 ff ff       	call   f0100e87 <page_alloc>
f01029fe:	89 c3                	mov    %eax,%ebx
f0102a00:	83 c4 10             	add    $0x10,%esp
f0102a03:	85 c0                	test   %eax,%eax
f0102a05:	75 19                	jne    f0102a20 <mem_init+0x17f0>
f0102a07:	68 3e 72 10 f0       	push   $0xf010723e
f0102a0c:	68 5f 71 10 f0       	push   $0xf010715f
f0102a11:	68 77 04 00 00       	push   $0x477
f0102a16:	68 39 71 10 f0       	push   $0xf0107139
f0102a1b:	e8 20 d6 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0102a20:	83 ec 0c             	sub    $0xc,%esp
f0102a23:	6a 00                	push   $0x0
f0102a25:	e8 5d e4 ff ff       	call   f0100e87 <page_alloc>
f0102a2a:	89 c7                	mov    %eax,%edi
f0102a2c:	83 c4 10             	add    $0x10,%esp
f0102a2f:	85 c0                	test   %eax,%eax
f0102a31:	75 19                	jne    f0102a4c <mem_init+0x181c>
f0102a33:	68 54 72 10 f0       	push   $0xf0107254
f0102a38:	68 5f 71 10 f0       	push   $0xf010715f
f0102a3d:	68 78 04 00 00       	push   $0x478
f0102a42:	68 39 71 10 f0       	push   $0xf0107139
f0102a47:	e8 f4 d5 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0102a4c:	83 ec 0c             	sub    $0xc,%esp
f0102a4f:	6a 00                	push   $0x0
f0102a51:	e8 31 e4 ff ff       	call   f0100e87 <page_alloc>
f0102a56:	89 c6                	mov    %eax,%esi
f0102a58:	83 c4 10             	add    $0x10,%esp
f0102a5b:	85 c0                	test   %eax,%eax
f0102a5d:	75 19                	jne    f0102a78 <mem_init+0x1848>
f0102a5f:	68 6a 72 10 f0       	push   $0xf010726a
f0102a64:	68 5f 71 10 f0       	push   $0xf010715f
f0102a69:	68 79 04 00 00       	push   $0x479
f0102a6e:	68 39 71 10 f0       	push   $0xf0107139
f0102a73:	e8 c8 d5 ff ff       	call   f0100040 <_panic>
	page_free(pp0);
f0102a78:	83 ec 0c             	sub    $0xc,%esp
f0102a7b:	53                   	push   %ebx
f0102a7c:	e8 76 e4 ff ff       	call   f0100ef7 <page_free>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102a81:	89 f8                	mov    %edi,%eax
f0102a83:	2b 05 90 fe 22 f0    	sub    0xf022fe90,%eax
f0102a89:	c1 f8 03             	sar    $0x3,%eax
f0102a8c:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102a8f:	89 c2                	mov    %eax,%edx
f0102a91:	c1 ea 0c             	shr    $0xc,%edx
f0102a94:	83 c4 10             	add    $0x10,%esp
f0102a97:	3b 15 88 fe 22 f0    	cmp    0xf022fe88,%edx
f0102a9d:	72 12                	jb     f0102ab1 <mem_init+0x1881>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102a9f:	50                   	push   %eax
f0102aa0:	68 24 63 10 f0       	push   $0xf0106324
f0102aa5:	6a 58                	push   $0x58
f0102aa7:	68 45 71 10 f0       	push   $0xf0107145
f0102aac:	e8 8f d5 ff ff       	call   f0100040 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f0102ab1:	83 ec 04             	sub    $0x4,%esp
f0102ab4:	68 00 10 00 00       	push   $0x1000
f0102ab9:	6a 01                	push   $0x1
f0102abb:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102ac0:	50                   	push   %eax
f0102ac1:	e8 73 2b 00 00       	call   f0105639 <memset>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102ac6:	89 f0                	mov    %esi,%eax
f0102ac8:	2b 05 90 fe 22 f0    	sub    0xf022fe90,%eax
f0102ace:	c1 f8 03             	sar    $0x3,%eax
f0102ad1:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102ad4:	89 c2                	mov    %eax,%edx
f0102ad6:	c1 ea 0c             	shr    $0xc,%edx
f0102ad9:	83 c4 10             	add    $0x10,%esp
f0102adc:	3b 15 88 fe 22 f0    	cmp    0xf022fe88,%edx
f0102ae2:	72 12                	jb     f0102af6 <mem_init+0x18c6>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102ae4:	50                   	push   %eax
f0102ae5:	68 24 63 10 f0       	push   $0xf0106324
f0102aea:	6a 58                	push   $0x58
f0102aec:	68 45 71 10 f0       	push   $0xf0107145
f0102af1:	e8 4a d5 ff ff       	call   f0100040 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0102af6:	83 ec 04             	sub    $0x4,%esp
f0102af9:	68 00 10 00 00       	push   $0x1000
f0102afe:	6a 02                	push   $0x2
f0102b00:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102b05:	50                   	push   %eax
f0102b06:	e8 2e 2b 00 00       	call   f0105639 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102b0b:	6a 02                	push   $0x2
f0102b0d:	68 00 10 00 00       	push   $0x1000
f0102b12:	57                   	push   %edi
f0102b13:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0102b19:	e8 1e e6 ff ff       	call   f010113c <page_insert>
	assert(pp1->pp_ref == 1);
f0102b1e:	83 c4 20             	add    $0x20,%esp
f0102b21:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102b26:	74 19                	je     f0102b41 <mem_init+0x1911>
f0102b28:	68 3b 73 10 f0       	push   $0xf010733b
f0102b2d:	68 5f 71 10 f0       	push   $0xf010715f
f0102b32:	68 7e 04 00 00       	push   $0x47e
f0102b37:	68 39 71 10 f0       	push   $0xf0107139
f0102b3c:	e8 ff d4 ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102b41:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102b48:	01 01 01 
f0102b4b:	74 19                	je     f0102b66 <mem_init+0x1936>
f0102b4d:	68 64 70 10 f0       	push   $0xf0107064
f0102b52:	68 5f 71 10 f0       	push   $0xf010715f
f0102b57:	68 7f 04 00 00       	push   $0x47f
f0102b5c:	68 39 71 10 f0       	push   $0xf0107139
f0102b61:	e8 da d4 ff ff       	call   f0100040 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102b66:	6a 02                	push   $0x2
f0102b68:	68 00 10 00 00       	push   $0x1000
f0102b6d:	56                   	push   %esi
f0102b6e:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0102b74:	e8 c3 e5 ff ff       	call   f010113c <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102b79:	83 c4 10             	add    $0x10,%esp
f0102b7c:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102b83:	02 02 02 
f0102b86:	74 19                	je     f0102ba1 <mem_init+0x1971>
f0102b88:	68 88 70 10 f0       	push   $0xf0107088
f0102b8d:	68 5f 71 10 f0       	push   $0xf010715f
f0102b92:	68 81 04 00 00       	push   $0x481
f0102b97:	68 39 71 10 f0       	push   $0xf0107139
f0102b9c:	e8 9f d4 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0102ba1:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102ba6:	74 19                	je     f0102bc1 <mem_init+0x1991>
f0102ba8:	68 5d 73 10 f0       	push   $0xf010735d
f0102bad:	68 5f 71 10 f0       	push   $0xf010715f
f0102bb2:	68 82 04 00 00       	push   $0x482
f0102bb7:	68 39 71 10 f0       	push   $0xf0107139
f0102bbc:	e8 7f d4 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f0102bc1:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102bc6:	74 19                	je     f0102be1 <mem_init+0x19b1>
f0102bc8:	68 c7 73 10 f0       	push   $0xf01073c7
f0102bcd:	68 5f 71 10 f0       	push   $0xf010715f
f0102bd2:	68 83 04 00 00       	push   $0x483
f0102bd7:	68 39 71 10 f0       	push   $0xf0107139
f0102bdc:	e8 5f d4 ff ff       	call   f0100040 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102be1:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102be8:	03 03 03 
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102beb:	89 f0                	mov    %esi,%eax
f0102bed:	2b 05 90 fe 22 f0    	sub    0xf022fe90,%eax
f0102bf3:	c1 f8 03             	sar    $0x3,%eax
f0102bf6:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102bf9:	89 c2                	mov    %eax,%edx
f0102bfb:	c1 ea 0c             	shr    $0xc,%edx
f0102bfe:	3b 15 88 fe 22 f0    	cmp    0xf022fe88,%edx
f0102c04:	72 12                	jb     f0102c18 <mem_init+0x19e8>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102c06:	50                   	push   %eax
f0102c07:	68 24 63 10 f0       	push   $0xf0106324
f0102c0c:	6a 58                	push   $0x58
f0102c0e:	68 45 71 10 f0       	push   $0xf0107145
f0102c13:	e8 28 d4 ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102c18:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102c1f:	03 03 03 
f0102c22:	74 19                	je     f0102c3d <mem_init+0x1a0d>
f0102c24:	68 ac 70 10 f0       	push   $0xf01070ac
f0102c29:	68 5f 71 10 f0       	push   $0xf010715f
f0102c2e:	68 85 04 00 00       	push   $0x485
f0102c33:	68 39 71 10 f0       	push   $0xf0107139
f0102c38:	e8 03 d4 ff ff       	call   f0100040 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102c3d:	83 ec 08             	sub    $0x8,%esp
f0102c40:	68 00 10 00 00       	push   $0x1000
f0102c45:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0102c4b:	e8 93 e4 ff ff       	call   f01010e3 <page_remove>
	assert(pp2->pp_ref == 0);
f0102c50:	83 c4 10             	add    $0x10,%esp
f0102c53:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102c58:	74 19                	je     f0102c73 <mem_init+0x1a43>
f0102c5a:	68 95 73 10 f0       	push   $0xf0107395
f0102c5f:	68 5f 71 10 f0       	push   $0xf010715f
f0102c64:	68 87 04 00 00       	push   $0x487
f0102c69:	68 39 71 10 f0       	push   $0xf0107139
f0102c6e:	e8 cd d3 ff ff       	call   f0100040 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102c73:	8b 0d 8c fe 22 f0    	mov    0xf022fe8c,%ecx
f0102c79:	8b 11                	mov    (%ecx),%edx
f0102c7b:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102c81:	89 d8                	mov    %ebx,%eax
f0102c83:	2b 05 90 fe 22 f0    	sub    0xf022fe90,%eax
f0102c89:	c1 f8 03             	sar    $0x3,%eax
f0102c8c:	c1 e0 0c             	shl    $0xc,%eax
f0102c8f:	39 c2                	cmp    %eax,%edx
f0102c91:	74 19                	je     f0102cac <mem_init+0x1a7c>
f0102c93:	68 34 6a 10 f0       	push   $0xf0106a34
f0102c98:	68 5f 71 10 f0       	push   $0xf010715f
f0102c9d:	68 8a 04 00 00       	push   $0x48a
f0102ca2:	68 39 71 10 f0       	push   $0xf0107139
f0102ca7:	e8 94 d3 ff ff       	call   f0100040 <_panic>
	kern_pgdir[0] = 0;
f0102cac:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102cb2:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102cb7:	74 19                	je     f0102cd2 <mem_init+0x1aa2>
f0102cb9:	68 4c 73 10 f0       	push   $0xf010734c
f0102cbe:	68 5f 71 10 f0       	push   $0xf010715f
f0102cc3:	68 8c 04 00 00       	push   $0x48c
f0102cc8:	68 39 71 10 f0       	push   $0xf0107139
f0102ccd:	e8 6e d3 ff ff       	call   f0100040 <_panic>
	pp0->pp_ref = 0;
f0102cd2:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f0102cd8:	83 ec 0c             	sub    $0xc,%esp
f0102cdb:	53                   	push   %ebx
f0102cdc:	e8 16 e2 ff ff       	call   f0100ef7 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102ce1:	c7 04 24 d8 70 10 f0 	movl   $0xf01070d8,(%esp)
f0102ce8:	e8 6f 0a 00 00       	call   f010375c <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0102ced:	83 c4 10             	add    $0x10,%esp
f0102cf0:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102cf3:	5b                   	pop    %ebx
f0102cf4:	5e                   	pop    %esi
f0102cf5:	5f                   	pop    %edi
f0102cf6:	5d                   	pop    %ebp
f0102cf7:	c3                   	ret    

f0102cf8 <user_mem_check>:
// Returns 0 if the user program can access this range of addresses,
// and -E_FAULT otherwise.
//
int
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
f0102cf8:	55                   	push   %ebp
f0102cf9:	89 e5                	mov    %esp,%ebp
f0102cfb:	57                   	push   %edi
f0102cfc:	56                   	push   %esi
f0102cfd:	53                   	push   %ebx
f0102cfe:	83 ec 1c             	sub    $0x1c,%esp
f0102d01:	8b 7d 08             	mov    0x8(%ebp),%edi
f0102d04:	8b 75 14             	mov    0x14(%ebp),%esi
	// LAB 3: Your code here.
pte_t * pte;
    	void * addr, *end;

    	addr = ROUNDDOWN((void *)va, PGSIZE);
f0102d07:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102d0a:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
    	end = ROUNDUP((void *)(va + len), PGSIZE);
f0102d10:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102d13:	03 45 10             	add    0x10(%ebp),%eax
f0102d16:	05 ff 0f 00 00       	add    $0xfff,%eax
f0102d1b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102d20:	89 45 e4             	mov    %eax,-0x1c(%ebp)

    if (addr >= (void *)ULIM)
f0102d23:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f0102d29:	76 57                	jbe    f0102d82 <user_mem_check+0x8a>
    {
        user_mem_check_addr = (uintptr_t)va;
f0102d2b:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102d2e:	a3 3c f2 22 f0       	mov    %eax,0xf022f23c
        return -E_FAULT;
f0102d33:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0102d38:	eb 52                	jmp    f0102d8c <user_mem_check+0x94>
    }

    for (; addr < end; addr += PGSIZE) {
        pte = pgdir_walk(env->env_pgdir, addr, 0);
f0102d3a:	83 ec 04             	sub    $0x4,%esp
f0102d3d:	6a 00                	push   $0x0
f0102d3f:	53                   	push   %ebx
f0102d40:	ff 77 60             	pushl  0x60(%edi)
f0102d43:	e8 11 e2 ff ff       	call   f0100f59 <pgdir_walk>
        if (!pte || !(*pte & PTE_P) || (*pte & perm) != perm)
f0102d48:	83 c4 10             	add    $0x10,%esp
f0102d4b:	85 c0                	test   %eax,%eax
f0102d4d:	74 0c                	je     f0102d5b <user_mem_check+0x63>
f0102d4f:	8b 00                	mov    (%eax),%eax
f0102d51:	a8 01                	test   $0x1,%al
f0102d53:	74 06                	je     f0102d5b <user_mem_check+0x63>
f0102d55:	21 f0                	and    %esi,%eax
f0102d57:	39 c6                	cmp    %eax,%esi
f0102d59:	74 21                	je     f0102d7c <user_mem_check+0x84>
        {
            if (addr < va)
f0102d5b:	3b 5d 0c             	cmp    0xc(%ebp),%ebx
f0102d5e:	73 0f                	jae    f0102d6f <user_mem_check+0x77>
            {
                user_mem_check_addr = (uintptr_t)va;
f0102d60:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102d63:	a3 3c f2 22 f0       	mov    %eax,0xf022f23c
            else
            {
                user_mem_check_addr = (uintptr_t)addr;
            }
            
            return -E_FAULT;
f0102d68:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0102d6d:	eb 1d                	jmp    f0102d8c <user_mem_check+0x94>
            {
                user_mem_check_addr = (uintptr_t)va;
            }
            else
            {
                user_mem_check_addr = (uintptr_t)addr;
f0102d6f:	89 1d 3c f2 22 f0    	mov    %ebx,0xf022f23c
            }
            
            return -E_FAULT;
f0102d75:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0102d7a:	eb 10                	jmp    f0102d8c <user_mem_check+0x94>
    {
        user_mem_check_addr = (uintptr_t)va;
        return -E_FAULT;
    }

    for (; addr < end; addr += PGSIZE) {
f0102d7c:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102d82:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f0102d85:	72 b3                	jb     f0102d3a <user_mem_check+0x42>
            
            return -E_FAULT;
        }
    }

	return 0;
f0102d87:	b8 00 00 00 00       	mov    $0x0,%eax

}
f0102d8c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102d8f:	5b                   	pop    %ebx
f0102d90:	5e                   	pop    %esi
f0102d91:	5f                   	pop    %edi
f0102d92:	5d                   	pop    %ebp
f0102d93:	c3                   	ret    

f0102d94 <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f0102d94:	55                   	push   %ebp
f0102d95:	89 e5                	mov    %esp,%ebp
f0102d97:	53                   	push   %ebx
f0102d98:	83 ec 04             	sub    $0x4,%esp
f0102d9b:	8b 5d 08             	mov    0x8(%ebp),%ebx
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
f0102d9e:	8b 45 14             	mov    0x14(%ebp),%eax
f0102da1:	83 c8 04             	or     $0x4,%eax
f0102da4:	50                   	push   %eax
f0102da5:	ff 75 10             	pushl  0x10(%ebp)
f0102da8:	ff 75 0c             	pushl  0xc(%ebp)
f0102dab:	53                   	push   %ebx
f0102dac:	e8 47 ff ff ff       	call   f0102cf8 <user_mem_check>
f0102db1:	83 c4 10             	add    $0x10,%esp
f0102db4:	85 c0                	test   %eax,%eax
f0102db6:	79 21                	jns    f0102dd9 <user_mem_assert+0x45>
		cprintf("[%08x] user_mem_check assertion failure for "
f0102db8:	83 ec 04             	sub    $0x4,%esp
f0102dbb:	ff 35 3c f2 22 f0    	pushl  0xf022f23c
f0102dc1:	ff 73 48             	pushl  0x48(%ebx)
f0102dc4:	68 04 71 10 f0       	push   $0xf0107104
f0102dc9:	e8 8e 09 00 00       	call   f010375c <cprintf>
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
f0102dce:	89 1c 24             	mov    %ebx,(%esp)
f0102dd1:	e8 67 06 00 00       	call   f010343d <env_destroy>
f0102dd6:	83 c4 10             	add    $0x10,%esp
	}
}
f0102dd9:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102ddc:	c9                   	leave  
f0102ddd:	c3                   	ret    

f0102dde <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f0102dde:	55                   	push   %ebp
f0102ddf:	89 e5                	mov    %esp,%ebp
f0102de1:	57                   	push   %edi
f0102de2:	56                   	push   %esi
f0102de3:	53                   	push   %ebx
f0102de4:	83 ec 1c             	sub    $0x1c,%esp
	//
	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	pde_t* pgdir = e->env_pgdir;
f0102de7:	8b 78 60             	mov    0x60(%eax),%edi
	int i=0;
	//page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
	//struct PageInfo *page_alloc(int alloc_flags)
	int npages = (ROUNDUP((pte_t)va + len, PGSIZE) - ROUNDDOWN((pte_t)va, PGSIZE)) / PGSIZE;
f0102dea:	8d 84 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%eax
f0102df1:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102df6:	89 d1                	mov    %edx,%ecx
f0102df8:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0102dfe:	29 c8                	sub    %ecx,%eax
f0102e00:	c1 e8 0c             	shr    $0xc,%eax
f0102e03:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for(;i<npages;i++){
f0102e06:	89 d3                	mov    %edx,%ebx
	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	pde_t* pgdir = e->env_pgdir;
	int i=0;
f0102e08:	be 00 00 00 00       	mov    $0x0,%esi
	//page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
	//struct PageInfo *page_alloc(int alloc_flags)
	int npages = (ROUNDUP((pte_t)va + len, PGSIZE) - ROUNDDOWN((pte_t)va, PGSIZE)) / PGSIZE;
	for(;i<npages;i++){
f0102e0d:	eb 59                	jmp    f0102e68 <region_alloc+0x8a>
		struct PageInfo* newPage = page_alloc(0);
f0102e0f:	83 ec 0c             	sub    $0xc,%esp
f0102e12:	6a 00                	push   $0x0
f0102e14:	e8 6e e0 ff ff       	call   f0100e87 <page_alloc>
		if(newPage == 0)
f0102e19:	83 c4 10             	add    $0x10,%esp
f0102e1c:	85 c0                	test   %eax,%eax
f0102e1e:	75 17                	jne    f0102e37 <region_alloc+0x59>
			panic("there is no more page to region_alloc for env\n");
f0102e20:	83 ec 04             	sub    $0x4,%esp
f0102e23:	68 64 74 10 f0       	push   $0xf0107464
f0102e28:	68 38 01 00 00       	push   $0x138
f0102e2d:	68 93 74 10 f0       	push   $0xf0107493
f0102e32:	e8 09 d2 ff ff       	call   f0100040 <_panic>
		int ret = page_insert(pgdir, newPage, va+i*PGSIZE, PTE_U|PTE_W );
f0102e37:	6a 06                	push   $0x6
f0102e39:	53                   	push   %ebx
f0102e3a:	50                   	push   %eax
f0102e3b:	57                   	push   %edi
f0102e3c:	e8 fb e2 ff ff       	call   f010113c <page_insert>
f0102e41:	81 c3 00 10 00 00    	add    $0x1000,%ebx
		if(ret)
f0102e47:	83 c4 10             	add    $0x10,%esp
f0102e4a:	85 c0                	test   %eax,%eax
f0102e4c:	74 17                	je     f0102e65 <region_alloc+0x87>
			panic("page_insert fail\n");
f0102e4e:	83 ec 04             	sub    $0x4,%esp
f0102e51:	68 9e 74 10 f0       	push   $0xf010749e
f0102e56:	68 3b 01 00 00       	push   $0x13b
f0102e5b:	68 93 74 10 f0       	push   $0xf0107493
f0102e60:	e8 db d1 ff ff       	call   f0100040 <_panic>
	pde_t* pgdir = e->env_pgdir;
	int i=0;
	//page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
	//struct PageInfo *page_alloc(int alloc_flags)
	int npages = (ROUNDUP((pte_t)va + len, PGSIZE) - ROUNDDOWN((pte_t)va, PGSIZE)) / PGSIZE;
	for(;i<npages;i++){
f0102e65:	83 c6 01             	add    $0x1,%esi
f0102e68:	3b 75 e4             	cmp    -0x1c(%ebp),%esi
f0102e6b:	7c a2                	jl     f0102e0f <region_alloc+0x31>
		if(ret)
			panic("page_insert fail\n");
	}
	return ;

}
f0102e6d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102e70:	5b                   	pop    %ebx
f0102e71:	5e                   	pop    %esi
f0102e72:	5f                   	pop    %edi
f0102e73:	5d                   	pop    %ebp
f0102e74:	c3                   	ret    

f0102e75 <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f0102e75:	55                   	push   %ebp
f0102e76:	89 e5                	mov    %esp,%ebp
f0102e78:	56                   	push   %esi
f0102e79:	53                   	push   %ebx
f0102e7a:	8b 45 08             	mov    0x8(%ebp),%eax
f0102e7d:	8b 55 10             	mov    0x10(%ebp),%edx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f0102e80:	85 c0                	test   %eax,%eax
f0102e82:	75 1a                	jne    f0102e9e <envid2env+0x29>
		*env_store = curenv;
f0102e84:	e8 d1 2d 00 00       	call   f0105c5a <cpunum>
f0102e89:	6b c0 74             	imul   $0x74,%eax,%eax
f0102e8c:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f0102e92:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0102e95:	89 01                	mov    %eax,(%ecx)
		return 0;
f0102e97:	b8 00 00 00 00       	mov    $0x0,%eax
f0102e9c:	eb 70                	jmp    f0102f0e <envid2env+0x99>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f0102e9e:	89 c3                	mov    %eax,%ebx
f0102ea0:	81 e3 ff 03 00 00    	and    $0x3ff,%ebx
f0102ea6:	6b db 7c             	imul   $0x7c,%ebx,%ebx
f0102ea9:	03 1d 48 f2 22 f0    	add    0xf022f248,%ebx
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f0102eaf:	83 7b 54 00          	cmpl   $0x0,0x54(%ebx)
f0102eb3:	74 05                	je     f0102eba <envid2env+0x45>
f0102eb5:	3b 43 48             	cmp    0x48(%ebx),%eax
f0102eb8:	74 10                	je     f0102eca <envid2env+0x55>
		// debug code
		//cprintf("the e->env_id =0x%x,  envid = 0x%x \n", e->env_id, envid);
		//cprintf("debug code\n\n");

		*env_store = 0;
f0102eba:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102ebd:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0102ec3:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0102ec8:	eb 44                	jmp    f0102f0e <envid2env+0x99>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f0102eca:	84 d2                	test   %dl,%dl
f0102ecc:	74 36                	je     f0102f04 <envid2env+0x8f>
f0102ece:	e8 87 2d 00 00       	call   f0105c5a <cpunum>
f0102ed3:	6b c0 74             	imul   $0x74,%eax,%eax
f0102ed6:	3b 98 28 00 23 f0    	cmp    -0xfdcffd8(%eax),%ebx
f0102edc:	74 26                	je     f0102f04 <envid2env+0x8f>
f0102ede:	8b 73 4c             	mov    0x4c(%ebx),%esi
f0102ee1:	e8 74 2d 00 00       	call   f0105c5a <cpunum>
f0102ee6:	6b c0 74             	imul   $0x74,%eax,%eax
f0102ee9:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f0102eef:	3b 70 48             	cmp    0x48(%eax),%esi
f0102ef2:	74 10                	je     f0102f04 <envid2env+0x8f>
		*env_store = 0;
f0102ef4:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102ef7:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0102efd:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0102f02:	eb 0a                	jmp    f0102f0e <envid2env+0x99>
	}

	*env_store = e;
f0102f04:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102f07:	89 18                	mov    %ebx,(%eax)
	return 0;
f0102f09:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102f0e:	5b                   	pop    %ebx
f0102f0f:	5e                   	pop    %esi
f0102f10:	5d                   	pop    %ebp
f0102f11:	c3                   	ret    

f0102f12 <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f0102f12:	55                   	push   %ebp
f0102f13:	89 e5                	mov    %esp,%ebp
}

static __inline void
lgdt(void *p)
{
	__asm __volatile("lgdt (%0)" : : "r" (p));
f0102f15:	b8 20 03 12 f0       	mov    $0xf0120320,%eax
f0102f1a:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" :: "a" (GD_UD|3));
f0102f1d:	b8 23 00 00 00       	mov    $0x23,%eax
f0102f22:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" :: "a" (GD_UD|3));
f0102f24:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" :: "a" (GD_KD));
f0102f26:	b8 10 00 00 00       	mov    $0x10,%eax
f0102f2b:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" :: "a" (GD_KD));
f0102f2d:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" :: "a" (GD_KD));
f0102f2f:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (GD_KT));
f0102f31:	ea 38 2f 10 f0 08 00 	ljmp   $0x8,$0xf0102f38
}

static __inline void
lldt(uint16_t sel)
{
	__asm __volatile("lldt %0" : : "r" (sel));
f0102f38:	b8 00 00 00 00       	mov    $0x0,%eax
f0102f3d:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f0102f40:	5d                   	pop    %ebp
f0102f41:	c3                   	ret    

f0102f42 <env_init>:
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f0102f42:	55                   	push   %ebp
f0102f43:	89 e5                	mov    %esp,%ebp
f0102f45:	56                   	push   %esi
f0102f46:	53                   	push   %ebx
	// Set up envs array
	// LAB 3: Your code here.
	env_free_list = 0;
	int i;
	for( i = NENV -1; i>=0; i--){
		envs[i].env_id = 0;
f0102f47:	8b 35 48 f2 22 f0    	mov    0xf022f248,%esi
f0102f4d:	8d 86 84 ef 01 00    	lea    0x1ef84(%esi),%eax
f0102f53:	8d 5e 84             	lea    -0x7c(%esi),%ebx
f0102f56:	ba 00 00 00 00       	mov    $0x0,%edx
f0102f5b:	89 c1                	mov    %eax,%ecx
f0102f5d:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
		envs[i].env_link = env_free_list;
f0102f64:	89 50 44             	mov    %edx,0x44(%eax)
f0102f67:	83 e8 7c             	sub    $0x7c,%eax
		env_free_list = &envs[i];
f0102f6a:	89 ca                	mov    %ecx,%edx
{
	// Set up envs array
	// LAB 3: Your code here.
	env_free_list = 0;
	int i;
	for( i = NENV -1; i>=0; i--){
f0102f6c:	39 d8                	cmp    %ebx,%eax
f0102f6e:	75 eb                	jne    f0102f5b <env_init+0x19>
f0102f70:	89 35 4c f2 22 f0    	mov    %esi,0xf022f24c
		envs[i].env_id = 0;
		envs[i].env_link = env_free_list;
		env_free_list = &envs[i];
	}
	// Per-CPU part of the initialization
	env_init_percpu();
f0102f76:	e8 97 ff ff ff       	call   f0102f12 <env_init_percpu>
}
f0102f7b:	5b                   	pop    %ebx
f0102f7c:	5e                   	pop    %esi
f0102f7d:	5d                   	pop    %ebp
f0102f7e:	c3                   	ret    

f0102f7f <env_alloc>:
//	-E_NO_FREE_ENV if all NENVS environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f0102f7f:	55                   	push   %ebp
f0102f80:	89 e5                	mov    %esp,%ebp
f0102f82:	53                   	push   %ebx
f0102f83:	83 ec 04             	sub    $0x4,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f0102f86:	8b 1d 4c f2 22 f0    	mov    0xf022f24c,%ebx
f0102f8c:	85 db                	test   %ebx,%ebx
f0102f8e:	0f 84 7c 01 00 00    	je     f0103110 <env_alloc+0x191>
{
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f0102f94:	83 ec 0c             	sub    $0xc,%esp
f0102f97:	6a 01                	push   $0x1
f0102f99:	e8 e9 de ff ff       	call   f0100e87 <page_alloc>
f0102f9e:	83 c4 10             	add    $0x10,%esp
f0102fa1:	85 c0                	test   %eax,%eax
f0102fa3:	0f 84 6e 01 00 00    	je     f0103117 <env_alloc+0x198>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102fa9:	89 c2                	mov    %eax,%edx
f0102fab:	2b 15 90 fe 22 f0    	sub    0xf022fe90,%edx
f0102fb1:	c1 fa 03             	sar    $0x3,%edx
f0102fb4:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102fb7:	89 d1                	mov    %edx,%ecx
f0102fb9:	c1 e9 0c             	shr    $0xc,%ecx
f0102fbc:	3b 0d 88 fe 22 f0    	cmp    0xf022fe88,%ecx
f0102fc2:	72 12                	jb     f0102fd6 <env_alloc+0x57>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102fc4:	52                   	push   %edx
f0102fc5:	68 24 63 10 f0       	push   $0xf0106324
f0102fca:	6a 58                	push   $0x58
f0102fcc:	68 45 71 10 f0       	push   $0xf0107145
f0102fd1:	e8 6a d0 ff ff       	call   f0100040 <_panic>
	//	is an exception -- you need to increment env_pgdir's
	//	pp_ref for env_free to work correctly.
	//    - The functions in kern/pmap.h are handy.

	// LAB 3: Your code here.
	e->env_pgdir =page2kva(p);
f0102fd6:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0102fdc:	89 53 60             	mov    %edx,0x60(%ebx)
	p->pp_ref++;
f0102fdf:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
	//照抄pgdir里面的东西,UTOP以上的。
	
	//i =  PDX(UTOP);
	//for(i ; i<1024; i++)
	//	e->env_pgdir[i] = kern_pgdir[i];
	memcpy(e->env_pgdir, kern_pgdir, PGSIZE);
f0102fe4:	83 ec 04             	sub    $0x4,%esp
f0102fe7:	68 00 10 00 00       	push   $0x1000
f0102fec:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0102ff2:	ff 73 60             	pushl  0x60(%ebx)
f0102ff5:	e8 f4 26 00 00       	call   f01056ee <memcpy>
	memset(e->env_pgdir, 0, UTOP>>PTSHIFT);
f0102ffa:	83 c4 0c             	add    $0xc,%esp
f0102ffd:	68 bb 03 00 00       	push   $0x3bb
f0103002:	6a 00                	push   $0x0
f0103004:	ff 73 60             	pushl  0x60(%ebx)
f0103007:	e8 2d 26 00 00       	call   f0105639 <memset>
	
	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f010300c:	8b 43 60             	mov    0x60(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010300f:	83 c4 10             	add    $0x10,%esp
f0103012:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103017:	77 15                	ja     f010302e <env_alloc+0xaf>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103019:	50                   	push   %eax
f010301a:	68 48 63 10 f0       	push   $0xf0106348
f010301f:	68 d0 00 00 00       	push   $0xd0
f0103024:	68 93 74 10 f0       	push   $0xf0107493
f0103029:	e8 12 d0 ff ff       	call   f0100040 <_panic>
f010302e:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0103034:	83 ca 05             	or     $0x5,%edx
f0103037:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f010303d:	8b 43 48             	mov    0x48(%ebx),%eax
f0103040:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f0103045:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f010304a:	ba 00 10 00 00       	mov    $0x1000,%edx
f010304f:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f0103052:	89 da                	mov    %ebx,%edx
f0103054:	2b 15 48 f2 22 f0    	sub    0xf022f248,%edx
f010305a:	c1 fa 02             	sar    $0x2,%edx
f010305d:	69 d2 df 7b ef bd    	imul   $0xbdef7bdf,%edx,%edx
f0103063:	09 d0                	or     %edx,%eax
f0103065:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f0103068:	8b 45 0c             	mov    0xc(%ebp),%eax
f010306b:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f010306e:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f0103075:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f010307c:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f0103083:	83 ec 04             	sub    $0x4,%esp
f0103086:	6a 44                	push   $0x44
f0103088:	6a 00                	push   $0x0
f010308a:	53                   	push   %ebx
f010308b:	e8 a9 25 00 00       	call   f0105639 <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f0103090:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f0103096:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f010309c:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f01030a2:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f01030a9:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)
	// You will set e->env_tf.tf_eip later.

	// Enable interrupts while in user mode.
	// LAB 4: Your code here.
	// time clock
	e->env_tf.tf_eflags |= FL_IF;
f01030af:	81 4b 38 00 02 00 00 	orl    $0x200,0x38(%ebx)
	
	// Clear the page fault handler until user installs one.
	e->env_pgfault_upcall = 0;
f01030b6:	c7 43 64 00 00 00 00 	movl   $0x0,0x64(%ebx)

	// Also clear the IPC receiving flag.
	//e->env_ipc_recving = 0;

	// commit the allocation
	env_free_list = e->env_link;
f01030bd:	8b 43 44             	mov    0x44(%ebx),%eax
f01030c0:	a3 4c f2 22 f0       	mov    %eax,0xf022f24c
	*newenv_store = e;
f01030c5:	8b 45 08             	mov    0x8(%ebp),%eax
f01030c8:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f01030ca:	8b 5b 48             	mov    0x48(%ebx),%ebx
f01030cd:	e8 88 2b 00 00       	call   f0105c5a <cpunum>
f01030d2:	6b c0 74             	imul   $0x74,%eax,%eax
f01030d5:	83 c4 10             	add    $0x10,%esp
f01030d8:	ba 00 00 00 00       	mov    $0x0,%edx
f01030dd:	83 b8 28 00 23 f0 00 	cmpl   $0x0,-0xfdcffd8(%eax)
f01030e4:	74 11                	je     f01030f7 <env_alloc+0x178>
f01030e6:	e8 6f 2b 00 00       	call   f0105c5a <cpunum>
f01030eb:	6b c0 74             	imul   $0x74,%eax,%eax
f01030ee:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f01030f4:	8b 50 48             	mov    0x48(%eax),%edx
f01030f7:	83 ec 04             	sub    $0x4,%esp
f01030fa:	53                   	push   %ebx
f01030fb:	52                   	push   %edx
f01030fc:	68 b0 74 10 f0       	push   $0xf01074b0
f0103101:	e8 56 06 00 00       	call   f010375c <cprintf>
	return 0;
f0103106:	83 c4 10             	add    $0x10,%esp
f0103109:	b8 00 00 00 00       	mov    $0x0,%eax
f010310e:	eb 0c                	jmp    f010311c <env_alloc+0x19d>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f0103110:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f0103115:	eb 05                	jmp    f010311c <env_alloc+0x19d>
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f0103117:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f010311c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010311f:	c9                   	leave  
f0103120:	c3                   	ret    

f0103121 <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f0103121:	55                   	push   %ebp
f0103122:	89 e5                	mov    %esp,%ebp
f0103124:	57                   	push   %edi
f0103125:	56                   	push   %esi
f0103126:	53                   	push   %ebx
f0103127:	83 ec 34             	sub    $0x34,%esp
	// LAB 3: Your code here.
	struct Env* env=0;
f010312a:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	int r = env_alloc(&env, 0);
f0103131:	6a 00                	push   $0x0
f0103133:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0103136:	50                   	push   %eax
f0103137:	e8 43 fe ff ff       	call   f0102f7f <env_alloc>
	if(r < 0)
f010313c:	83 c4 10             	add    $0x10,%esp
f010313f:	85 c0                	test   %eax,%eax
f0103141:	79 17                	jns    f010315a <env_create+0x39>
		panic("env_create fault\n");
f0103143:	83 ec 04             	sub    $0x4,%esp
f0103146:	68 c5 74 10 f0       	push   $0xf01074c5
f010314b:	68 ab 01 00 00       	push   $0x1ab
f0103150:	68 93 74 10 f0       	push   $0xf0107493
f0103155:	e8 e6 ce ff ff       	call   f0100040 <_panic>
	load_icode(env, binary);
f010315a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010315d:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	//  to make sure that the environment starts executing there.
	//  What?  (See env_run() and env_pop_tf() below.)

	// LAB 3: Your code here.
		struct Elf* elf = (struct Elf*) binary;
		if (elf->e_magic != ELF_MAGIC)
f0103160:	8b 45 08             	mov    0x8(%ebp),%eax
f0103163:	81 38 7f 45 4c 46    	cmpl   $0x464c457f,(%eax)
f0103169:	74 17                	je     f0103182 <env_create+0x61>
			panic("e_magic is not right\n");
f010316b:	83 ec 04             	sub    $0x4,%esp
f010316e:	68 d7 74 10 f0       	push   $0xf01074d7
f0103173:	68 79 01 00 00       	push   $0x179
f0103178:	68 93 74 10 f0       	push   $0xf0107493
f010317d:	e8 be ce ff ff       	call   f0100040 <_panic>
		//首先要更改私有地址的pgdir
		lcr3( PADDR(e->env_pgdir));		//程序头表
f0103182:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103185:	8b 40 60             	mov    0x60(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103188:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010318d:	77 15                	ja     f01031a4 <env_create+0x83>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010318f:	50                   	push   %eax
f0103190:	68 48 63 10 f0       	push   $0xf0106348
f0103195:	68 7b 01 00 00       	push   $0x17b
f010319a:	68 93 74 10 f0       	push   $0xf0107493
f010319f:	e8 9c ce ff ff       	call   f0100040 <_panic>
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f01031a4:	05 00 00 00 10       	add    $0x10000000,%eax
f01031a9:	0f 22 d8             	mov    %eax,%cr3
		struct Proghdr *ph =0;
		struct Proghdr *phEnd =0;
		int phNum=0;
		pte_t* va=0;

		ph = (struct Proghdr*) ( binary + elf->e_phoff );
f01031ac:	8b 45 08             	mov    0x8(%ebp),%eax
f01031af:	89 c3                	mov    %eax,%ebx
f01031b1:	03 58 1c             	add    0x1c(%eax),%ebx
	
		int num = elf->e_phnum;
f01031b4:	0f b7 78 2c          	movzwl 0x2c(%eax),%edi
		int i=0;
f01031b8:	be 00 00 00 00       	mov    $0x0,%esi
f01031bd:	eb 48                	jmp    f0103207 <env_create+0xe6>
		for(; i<num; i++){
			ph++;
f01031bf:	83 c3 20             	add    $0x20,%ebx
			//可载入段
			if(ph->p_type == ELF_PROG_LOAD){
f01031c2:	83 3b 01             	cmpl   $0x1,(%ebx)
f01031c5:	75 3d                	jne    f0103204 <env_create+0xe3>
				region_alloc(e, (void *)ph->p_va, ph->p_memsz);	//为va申请地址。
f01031c7:	8b 4b 14             	mov    0x14(%ebx),%ecx
f01031ca:	8b 53 08             	mov    0x8(%ebx),%edx
f01031cd:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01031d0:	e8 09 fc ff ff       	call   f0102dde <region_alloc>
				memmove((void*)ph->p_va,  (void*)(binary + ph->p_offset),  ph->p_filesz);
f01031d5:	83 ec 04             	sub    $0x4,%esp
f01031d8:	ff 73 10             	pushl  0x10(%ebx)
f01031db:	8b 45 08             	mov    0x8(%ebp),%eax
f01031de:	03 43 04             	add    0x4(%ebx),%eax
f01031e1:	50                   	push   %eax
f01031e2:	ff 73 08             	pushl  0x8(%ebx)
f01031e5:	e8 9c 24 00 00       	call   f0105686 <memmove>
				memset((void*) (ph->p_va + ph->p_filesz), 0, ph->p_memsz - ph->p_filesz);
f01031ea:	8b 43 10             	mov    0x10(%ebx),%eax
f01031ed:	83 c4 0c             	add    $0xc,%esp
f01031f0:	8b 53 14             	mov    0x14(%ebx),%edx
f01031f3:	29 c2                	sub    %eax,%edx
f01031f5:	52                   	push   %edx
f01031f6:	6a 00                	push   $0x0
f01031f8:	03 43 08             	add    0x8(%ebx),%eax
f01031fb:	50                   	push   %eax
f01031fc:	e8 38 24 00 00       	call   f0105639 <memset>
f0103201:	83 c4 10             	add    $0x10,%esp

		ph = (struct Proghdr*) ( binary + elf->e_phoff );
	
		int num = elf->e_phnum;
		int i=0;
		for(; i<num; i++){
f0103204:	83 c6 01             	add    $0x1,%esi
f0103207:	39 f7                	cmp    %esi,%edi
f0103209:	75 b4                	jne    f01031bf <env_create+0x9e>
	

		phEnd = ph + elf->e_phnum;


		e->env_tf.tf_eip = elf->e_entry;
f010320b:	8b 45 08             	mov    0x8(%ebp),%eax
f010320e:	8b 40 18             	mov    0x18(%eax),%eax
f0103211:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103214:	89 47 30             	mov    %eax,0x30(%edi)

	// Now map one page for the program's initial stack
	// at virtual address USTACKTOP - PGSIZE.
	// LAB 3: Your code here.
		    region_alloc(e,(void*)USTACKTOP - PGSIZE,PGSIZE);  
f0103217:	b9 00 10 00 00       	mov    $0x1000,%ecx
f010321c:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f0103221:	89 f8                	mov    %edi,%eax
f0103223:	e8 b6 fb ff ff       	call   f0102dde <region_alloc>
		    lcr3(PADDR(kern_pgdir));
f0103228:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010322d:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103232:	77 15                	ja     f0103249 <env_create+0x128>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103234:	50                   	push   %eax
f0103235:	68 48 63 10 f0       	push   $0xf0106348
f010323a:	68 99 01 00 00       	push   $0x199
f010323f:	68 93 74 10 f0       	push   $0xf0107493
f0103244:	e8 f7 cd ff ff       	call   f0100040 <_panic>
f0103249:	05 00 00 00 10       	add    $0x10000000,%eax
f010324e:	0f 22 d8             	mov    %eax,%cr3
	struct Env* env=0;
	int r = env_alloc(&env, 0);
	if(r < 0)
		panic("env_create fault\n");
	load_icode(env, binary);
	env->env_type = type;
f0103251:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103254:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103257:	89 50 50             	mov    %edx,0x50(%eax)
}
f010325a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010325d:	5b                   	pop    %ebx
f010325e:	5e                   	pop    %esi
f010325f:	5f                   	pop    %edi
f0103260:	5d                   	pop    %ebp
f0103261:	c3                   	ret    

f0103262 <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f0103262:	55                   	push   %ebp
f0103263:	89 e5                	mov    %esp,%ebp
f0103265:	57                   	push   %edi
f0103266:	56                   	push   %esi
f0103267:	53                   	push   %ebx
f0103268:	83 ec 1c             	sub    $0x1c,%esp
f010326b:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f010326e:	e8 e7 29 00 00       	call   f0105c5a <cpunum>
f0103273:	6b c0 74             	imul   $0x74,%eax,%eax
f0103276:	39 b8 28 00 23 f0    	cmp    %edi,-0xfdcffd8(%eax)
f010327c:	75 29                	jne    f01032a7 <env_free+0x45>
		lcr3(PADDR(kern_pgdir));
f010327e:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103283:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103288:	77 15                	ja     f010329f <env_free+0x3d>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010328a:	50                   	push   %eax
f010328b:	68 48 63 10 f0       	push   $0xf0106348
f0103290:	68 be 01 00 00       	push   $0x1be
f0103295:	68 93 74 10 f0       	push   $0xf0107493
f010329a:	e8 a1 cd ff ff       	call   f0100040 <_panic>
f010329f:	05 00 00 00 10       	add    $0x10000000,%eax
f01032a4:	0f 22 d8             	mov    %eax,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f01032a7:	8b 5f 48             	mov    0x48(%edi),%ebx
f01032aa:	e8 ab 29 00 00       	call   f0105c5a <cpunum>
f01032af:	6b c0 74             	imul   $0x74,%eax,%eax
f01032b2:	ba 00 00 00 00       	mov    $0x0,%edx
f01032b7:	83 b8 28 00 23 f0 00 	cmpl   $0x0,-0xfdcffd8(%eax)
f01032be:	74 11                	je     f01032d1 <env_free+0x6f>
f01032c0:	e8 95 29 00 00       	call   f0105c5a <cpunum>
f01032c5:	6b c0 74             	imul   $0x74,%eax,%eax
f01032c8:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f01032ce:	8b 50 48             	mov    0x48(%eax),%edx
f01032d1:	83 ec 04             	sub    $0x4,%esp
f01032d4:	53                   	push   %ebx
f01032d5:	52                   	push   %edx
f01032d6:	68 ed 74 10 f0       	push   $0xf01074ed
f01032db:	e8 7c 04 00 00       	call   f010375c <cprintf>
f01032e0:	83 c4 10             	add    $0x10,%esp

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f01032e3:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f01032ea:	8b 55 e0             	mov    -0x20(%ebp),%edx
f01032ed:	89 d0                	mov    %edx,%eax
f01032ef:	c1 e0 02             	shl    $0x2,%eax
f01032f2:	89 45 dc             	mov    %eax,-0x24(%ebp)

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f01032f5:	8b 47 60             	mov    0x60(%edi),%eax
f01032f8:	8b 34 90             	mov    (%eax,%edx,4),%esi
f01032fb:	f7 c6 01 00 00 00    	test   $0x1,%esi
f0103301:	0f 84 a8 00 00 00    	je     f01033af <env_free+0x14d>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f0103307:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010330d:	89 f0                	mov    %esi,%eax
f010330f:	c1 e8 0c             	shr    $0xc,%eax
f0103312:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103315:	39 05 88 fe 22 f0    	cmp    %eax,0xf022fe88
f010331b:	77 15                	ja     f0103332 <env_free+0xd0>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010331d:	56                   	push   %esi
f010331e:	68 24 63 10 f0       	push   $0xf0106324
f0103323:	68 cd 01 00 00       	push   $0x1cd
f0103328:	68 93 74 10 f0       	push   $0xf0107493
f010332d:	e8 0e cd ff ff       	call   f0100040 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0103332:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103335:	c1 e0 16             	shl    $0x16,%eax
f0103338:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f010333b:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f0103340:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f0103347:	01 
f0103348:	74 17                	je     f0103361 <env_free+0xff>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f010334a:	83 ec 08             	sub    $0x8,%esp
f010334d:	89 d8                	mov    %ebx,%eax
f010334f:	c1 e0 0c             	shl    $0xc,%eax
f0103352:	0b 45 e4             	or     -0x1c(%ebp),%eax
f0103355:	50                   	push   %eax
f0103356:	ff 77 60             	pushl  0x60(%edi)
f0103359:	e8 85 dd ff ff       	call   f01010e3 <page_remove>
f010335e:	83 c4 10             	add    $0x10,%esp
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0103361:	83 c3 01             	add    $0x1,%ebx
f0103364:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f010336a:	75 d4                	jne    f0103340 <env_free+0xde>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f010336c:	8b 47 60             	mov    0x60(%edi),%eax
f010336f:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103372:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103379:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010337c:	3b 05 88 fe 22 f0    	cmp    0xf022fe88,%eax
f0103382:	72 14                	jb     f0103398 <env_free+0x136>
		panic("pa2page called with invalid pa");
f0103384:	83 ec 04             	sub    $0x4,%esp
f0103387:	68 e0 68 10 f0       	push   $0xf01068e0
f010338c:	6a 51                	push   $0x51
f010338e:	68 45 71 10 f0       	push   $0xf0107145
f0103393:	e8 a8 cc ff ff       	call   f0100040 <_panic>
		page_decref(pa2page(pa));
f0103398:	83 ec 0c             	sub    $0xc,%esp
f010339b:	a1 90 fe 22 f0       	mov    0xf022fe90,%eax
f01033a0:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01033a3:	8d 04 d0             	lea    (%eax,%edx,8),%eax
f01033a6:	50                   	push   %eax
f01033a7:	e8 86 db ff ff       	call   f0100f32 <page_decref>
f01033ac:	83 c4 10             	add    $0x10,%esp
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f01033af:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f01033b3:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01033b6:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f01033bb:	0f 85 29 ff ff ff    	jne    f01032ea <env_free+0x88>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f01033c1:	8b 47 60             	mov    0x60(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01033c4:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01033c9:	77 15                	ja     f01033e0 <env_free+0x17e>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01033cb:	50                   	push   %eax
f01033cc:	68 48 63 10 f0       	push   $0xf0106348
f01033d1:	68 db 01 00 00       	push   $0x1db
f01033d6:	68 93 74 10 f0       	push   $0xf0107493
f01033db:	e8 60 cc ff ff       	call   f0100040 <_panic>
	e->env_pgdir = 0;
f01033e0:	c7 47 60 00 00 00 00 	movl   $0x0,0x60(%edi)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01033e7:	05 00 00 00 10       	add    $0x10000000,%eax
f01033ec:	c1 e8 0c             	shr    $0xc,%eax
f01033ef:	3b 05 88 fe 22 f0    	cmp    0xf022fe88,%eax
f01033f5:	72 14                	jb     f010340b <env_free+0x1a9>
		panic("pa2page called with invalid pa");
f01033f7:	83 ec 04             	sub    $0x4,%esp
f01033fa:	68 e0 68 10 f0       	push   $0xf01068e0
f01033ff:	6a 51                	push   $0x51
f0103401:	68 45 71 10 f0       	push   $0xf0107145
f0103406:	e8 35 cc ff ff       	call   f0100040 <_panic>
	page_decref(pa2page(pa));
f010340b:	83 ec 0c             	sub    $0xc,%esp
f010340e:	8b 15 90 fe 22 f0    	mov    0xf022fe90,%edx
f0103414:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f0103417:	50                   	push   %eax
f0103418:	e8 15 db ff ff       	call   f0100f32 <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f010341d:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f0103424:	a1 4c f2 22 f0       	mov    0xf022f24c,%eax
f0103429:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f010342c:	89 3d 4c f2 22 f0    	mov    %edi,0xf022f24c
}
f0103432:	83 c4 10             	add    $0x10,%esp
f0103435:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103438:	5b                   	pop    %ebx
f0103439:	5e                   	pop    %esi
f010343a:	5f                   	pop    %edi
f010343b:	5d                   	pop    %ebp
f010343c:	c3                   	ret    

f010343d <env_destroy>:
// If e was the current env, then runs a new environment (and does not return
// to the caller).
//
void
env_destroy(struct Env *e)
{
f010343d:	55                   	push   %ebp
f010343e:	89 e5                	mov    %esp,%ebp
f0103440:	53                   	push   %ebx
f0103441:	83 ec 04             	sub    $0x4,%esp
f0103444:	8b 5d 08             	mov    0x8(%ebp),%ebx
	// If e is currently running on other CPUs, we change its state to
	// ENV_DYING. A zombie environment will be freed the next time
	// it traps to the kernel.
	if (e->env_status == ENV_RUNNING && curenv != e) {
f0103447:	83 7b 54 03          	cmpl   $0x3,0x54(%ebx)
f010344b:	75 19                	jne    f0103466 <env_destroy+0x29>
f010344d:	e8 08 28 00 00       	call   f0105c5a <cpunum>
f0103452:	6b c0 74             	imul   $0x74,%eax,%eax
f0103455:	3b 98 28 00 23 f0    	cmp    -0xfdcffd8(%eax),%ebx
f010345b:	74 09                	je     f0103466 <env_destroy+0x29>
		e->env_status = ENV_DYING;
f010345d:	c7 43 54 01 00 00 00 	movl   $0x1,0x54(%ebx)
		return;
f0103464:	eb 33                	jmp    f0103499 <env_destroy+0x5c>
	}

	env_free(e);
f0103466:	83 ec 0c             	sub    $0xc,%esp
f0103469:	53                   	push   %ebx
f010346a:	e8 f3 fd ff ff       	call   f0103262 <env_free>

	if (curenv == e) {
f010346f:	e8 e6 27 00 00       	call   f0105c5a <cpunum>
f0103474:	6b c0 74             	imul   $0x74,%eax,%eax
f0103477:	83 c4 10             	add    $0x10,%esp
f010347a:	3b 98 28 00 23 f0    	cmp    -0xfdcffd8(%eax),%ebx
f0103480:	75 17                	jne    f0103499 <env_destroy+0x5c>
		curenv = NULL;
f0103482:	e8 d3 27 00 00       	call   f0105c5a <cpunum>
f0103487:	6b c0 74             	imul   $0x74,%eax,%eax
f010348a:	c7 80 28 00 23 f0 00 	movl   $0x0,-0xfdcffd8(%eax)
f0103491:	00 00 00 
		sched_yield();
f0103494:	e8 3f 0f 00 00       	call   f01043d8 <sched_yield>
	}
}
f0103499:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010349c:	c9                   	leave  
f010349d:	c3                   	ret    

f010349e <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f010349e:	55                   	push   %ebp
f010349f:	89 e5                	mov    %esp,%ebp
f01034a1:	53                   	push   %ebx
f01034a2:	83 ec 04             	sub    $0x4,%esp
	// Record the CPU we are running on for user-space debugging
	curenv->env_cpunum = cpunum();
f01034a5:	e8 b0 27 00 00       	call   f0105c5a <cpunum>
f01034aa:	6b c0 74             	imul   $0x74,%eax,%eax
f01034ad:	8b 98 28 00 23 f0    	mov    -0xfdcffd8(%eax),%ebx
f01034b3:	e8 a2 27 00 00       	call   f0105c5a <cpunum>
f01034b8:	89 43 5c             	mov    %eax,0x5c(%ebx)

	__asm __volatile("movl %0,%%esp\n"
f01034bb:	8b 65 08             	mov    0x8(%ebp),%esp
f01034be:	61                   	popa   
f01034bf:	07                   	pop    %es
f01034c0:	1f                   	pop    %ds
f01034c1:	83 c4 08             	add    $0x8,%esp
f01034c4:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f01034c5:	83 ec 04             	sub    $0x4,%esp
f01034c8:	68 03 75 10 f0       	push   $0xf0107503
f01034cd:	68 11 02 00 00       	push   $0x211
f01034d2:	68 93 74 10 f0       	push   $0xf0107493
f01034d7:	e8 64 cb ff ff       	call   f0100040 <_panic>

f01034dc <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f01034dc:	55                   	push   %ebp
f01034dd:	89 e5                	mov    %esp,%ebp
f01034df:	53                   	push   %ebx
f01034e0:	83 ec 04             	sub    $0x4,%esp
f01034e3:	8b 5d 08             	mov    0x8(%ebp),%ebx
	//	e->env_tf.  Go back through the code you wrote above
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.
	if(curenv == 0)
f01034e6:	e8 6f 27 00 00       	call   f0105c5a <cpunum>
f01034eb:	6b c0 74             	imul   $0x74,%eax,%eax
f01034ee:	83 b8 28 00 23 f0 00 	cmpl   $0x0,-0xfdcffd8(%eax)
f01034f5:	75 10                	jne    f0103507 <env_run+0x2b>
		curenv = e;
f01034f7:	e8 5e 27 00 00       	call   f0105c5a <cpunum>
f01034fc:	6b c0 74             	imul   $0x74,%eax,%eax
f01034ff:	89 98 28 00 23 f0    	mov    %ebx,-0xfdcffd8(%eax)
f0103505:	eb 29                	jmp    f0103530 <env_run+0x54>
	else if(curenv->env_status == ENV_RUNNING)
f0103507:	e8 4e 27 00 00       	call   f0105c5a <cpunum>
f010350c:	6b c0 74             	imul   $0x74,%eax,%eax
f010350f:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f0103515:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0103519:	75 15                	jne    f0103530 <env_run+0x54>
		curenv->env_status = ENV_RUNNABLE;
f010351b:	e8 3a 27 00 00       	call   f0105c5a <cpunum>
f0103520:	6b c0 74             	imul   $0x74,%eax,%eax
f0103523:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f0103529:	c7 40 54 02 00 00 00 	movl   $0x2,0x54(%eax)
	curenv = e;
f0103530:	e8 25 27 00 00       	call   f0105c5a <cpunum>
f0103535:	6b c0 74             	imul   $0x74,%eax,%eax
f0103538:	89 98 28 00 23 f0    	mov    %ebx,-0xfdcffd8(%eax)
	curenv->env_status = ENV_RUNNING;
f010353e:	e8 17 27 00 00       	call   f0105c5a <cpunum>
f0103543:	6b c0 74             	imul   $0x74,%eax,%eax
f0103546:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f010354c:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
	curenv->env_runs++;
f0103553:	e8 02 27 00 00       	call   f0105c5a <cpunum>
f0103558:	6b c0 74             	imul   $0x74,%eax,%eax
f010355b:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f0103561:	83 40 58 01          	addl   $0x1,0x58(%eax)
	cprintf("before:%08x\n", e);
f0103565:	83 ec 08             	sub    $0x8,%esp
f0103568:	53                   	push   %ebx
f0103569:	68 0f 75 10 f0       	push   $0xf010750f
f010356e:	e8 e9 01 00 00       	call   f010375c <cprintf>
	lcr3( PADDR(curenv->env_pgdir) );
f0103573:	e8 e2 26 00 00       	call   f0105c5a <cpunum>
f0103578:	6b c0 74             	imul   $0x74,%eax,%eax
f010357b:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f0103581:	8b 40 60             	mov    0x60(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103584:	83 c4 10             	add    $0x10,%esp
f0103587:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010358c:	77 15                	ja     f01035a3 <env_run+0xc7>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010358e:	50                   	push   %eax
f010358f:	68 48 63 10 f0       	push   $0xf0106348
f0103594:	68 37 02 00 00       	push   $0x237
f0103599:	68 93 74 10 f0       	push   $0xf0107493
f010359e:	e8 9d ca ff ff       	call   f0100040 <_panic>
f01035a3:	05 00 00 00 10       	add    $0x10000000,%eax
f01035a8:	0f 22 d8             	mov    %eax,%cr3
	cprintf("after:%08x\n", e);
f01035ab:	83 ec 08             	sub    $0x8,%esp
f01035ae:	53                   	push   %ebx
f01035af:	68 1c 75 10 f0       	push   $0xf010751c
f01035b4:	e8 a3 01 00 00       	call   f010375c <cprintf>
}

static inline void
unlock_kernel(void)
{
	spin_unlock(&kernel_lock);
f01035b9:	c7 04 24 c0 03 12 f0 	movl   $0xf01203c0,(%esp)
f01035c0:	e8 a0 29 00 00       	call   f0105f65 <spin_unlock>

	// Normally we wouldn't need to do this, but QEMU only runs
	// one CPU at a time and has a long time-slice.  Without the
	// pause, this CPU is likely to reacquire the lock before
	// another CPU has even been given a chance to acquire it.
	asm volatile("pause");
f01035c5:	f3 90                	pause  
	//在env_pop_tf执行结束之后，就回到用户态了，所以一定要在此之前释放
	unlock_kernel();
	env_pop_tf(& (curenv->env_tf) );
f01035c7:	e8 8e 26 00 00       	call   f0105c5a <cpunum>
f01035cc:	83 c4 04             	add    $0x4,%esp
f01035cf:	6b c0 74             	imul   $0x74,%eax,%eax
f01035d2:	ff b0 28 00 23 f0    	pushl  -0xfdcffd8(%eax)
f01035d8:	e8 c1 fe ff ff       	call   f010349e <env_pop_tf>

f01035dd <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f01035dd:	55                   	push   %ebp
f01035de:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01035e0:	ba 70 00 00 00       	mov    $0x70,%edx
f01035e5:	8b 45 08             	mov    0x8(%ebp),%eax
f01035e8:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01035e9:	ba 71 00 00 00       	mov    $0x71,%edx
f01035ee:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f01035ef:	0f b6 c0             	movzbl %al,%eax
}
f01035f2:	5d                   	pop    %ebp
f01035f3:	c3                   	ret    

f01035f4 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f01035f4:	55                   	push   %ebp
f01035f5:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01035f7:	ba 70 00 00 00       	mov    $0x70,%edx
f01035fc:	8b 45 08             	mov    0x8(%ebp),%eax
f01035ff:	ee                   	out    %al,(%dx)
f0103600:	ba 71 00 00 00       	mov    $0x71,%edx
f0103605:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103608:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0103609:	5d                   	pop    %ebp
f010360a:	c3                   	ret    

f010360b <irq_setmask_8259A>:
		irq_setmask_8259A(irq_mask_8259A);
}

void
irq_setmask_8259A(uint16_t mask)
{
f010360b:	55                   	push   %ebp
f010360c:	89 e5                	mov    %esp,%ebp
f010360e:	56                   	push   %esi
f010360f:	53                   	push   %ebx
f0103610:	8b 45 08             	mov    0x8(%ebp),%eax
	int i;
	irq_mask_8259A = mask;
f0103613:	66 a3 a8 03 12 f0    	mov    %ax,0xf01203a8
	if (!didinit)
f0103619:	80 3d 50 f2 22 f0 00 	cmpb   $0x0,0xf022f250
f0103620:	74 5a                	je     f010367c <irq_setmask_8259A+0x71>
f0103622:	89 c6                	mov    %eax,%esi
f0103624:	ba 21 00 00 00       	mov    $0x21,%edx
f0103629:	ee                   	out    %al,(%dx)
f010362a:	66 c1 e8 08          	shr    $0x8,%ax
f010362e:	ba a1 00 00 00       	mov    $0xa1,%edx
f0103633:	ee                   	out    %al,(%dx)
		return;
	outb(IO_PIC1+1, (char)mask);
	outb(IO_PIC2+1, (char)(mask >> 8));
	cprintf("enabled interrupts:");
f0103634:	83 ec 0c             	sub    $0xc,%esp
f0103637:	68 28 75 10 f0       	push   $0xf0107528
f010363c:	e8 1b 01 00 00       	call   f010375c <cprintf>
f0103641:	83 c4 10             	add    $0x10,%esp
	for (i = 0; i < 16; i++)
f0103644:	bb 00 00 00 00       	mov    $0x0,%ebx
		if (~mask & (1<<i))
f0103649:	0f b7 f6             	movzwl %si,%esi
f010364c:	f7 d6                	not    %esi
f010364e:	0f a3 de             	bt     %ebx,%esi
f0103651:	73 11                	jae    f0103664 <irq_setmask_8259A+0x59>
			cprintf(" %d", i);
f0103653:	83 ec 08             	sub    $0x8,%esp
f0103656:	53                   	push   %ebx
f0103657:	68 fb 79 10 f0       	push   $0xf01079fb
f010365c:	e8 fb 00 00 00       	call   f010375c <cprintf>
f0103661:	83 c4 10             	add    $0x10,%esp
	if (!didinit)
		return;
	outb(IO_PIC1+1, (char)mask);
	outb(IO_PIC2+1, (char)(mask >> 8));
	cprintf("enabled interrupts:");
	for (i = 0; i < 16; i++)
f0103664:	83 c3 01             	add    $0x1,%ebx
f0103667:	83 fb 10             	cmp    $0x10,%ebx
f010366a:	75 e2                	jne    f010364e <irq_setmask_8259A+0x43>
		if (~mask & (1<<i))
			cprintf(" %d", i);
	cprintf("\n");
f010366c:	83 ec 0c             	sub    $0xc,%esp
f010366f:	68 30 74 10 f0       	push   $0xf0107430
f0103674:	e8 e3 00 00 00       	call   f010375c <cprintf>
f0103679:	83 c4 10             	add    $0x10,%esp
}
f010367c:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010367f:	5b                   	pop    %ebx
f0103680:	5e                   	pop    %esi
f0103681:	5d                   	pop    %ebp
f0103682:	c3                   	ret    

f0103683 <pic_init>:

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
	didinit = 1;
f0103683:	c6 05 50 f2 22 f0 01 	movb   $0x1,0xf022f250
f010368a:	ba 21 00 00 00       	mov    $0x21,%edx
f010368f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103694:	ee                   	out    %al,(%dx)
f0103695:	ba a1 00 00 00       	mov    $0xa1,%edx
f010369a:	ee                   	out    %al,(%dx)
f010369b:	ba 20 00 00 00       	mov    $0x20,%edx
f01036a0:	b8 11 00 00 00       	mov    $0x11,%eax
f01036a5:	ee                   	out    %al,(%dx)
f01036a6:	ba 21 00 00 00       	mov    $0x21,%edx
f01036ab:	b8 20 00 00 00       	mov    $0x20,%eax
f01036b0:	ee                   	out    %al,(%dx)
f01036b1:	b8 04 00 00 00       	mov    $0x4,%eax
f01036b6:	ee                   	out    %al,(%dx)
f01036b7:	b8 03 00 00 00       	mov    $0x3,%eax
f01036bc:	ee                   	out    %al,(%dx)
f01036bd:	ba a0 00 00 00       	mov    $0xa0,%edx
f01036c2:	b8 11 00 00 00       	mov    $0x11,%eax
f01036c7:	ee                   	out    %al,(%dx)
f01036c8:	ba a1 00 00 00       	mov    $0xa1,%edx
f01036cd:	b8 28 00 00 00       	mov    $0x28,%eax
f01036d2:	ee                   	out    %al,(%dx)
f01036d3:	b8 02 00 00 00       	mov    $0x2,%eax
f01036d8:	ee                   	out    %al,(%dx)
f01036d9:	b8 01 00 00 00       	mov    $0x1,%eax
f01036de:	ee                   	out    %al,(%dx)
f01036df:	ba 20 00 00 00       	mov    $0x20,%edx
f01036e4:	b8 68 00 00 00       	mov    $0x68,%eax
f01036e9:	ee                   	out    %al,(%dx)
f01036ea:	b8 0a 00 00 00       	mov    $0xa,%eax
f01036ef:	ee                   	out    %al,(%dx)
f01036f0:	ba a0 00 00 00       	mov    $0xa0,%edx
f01036f5:	b8 68 00 00 00       	mov    $0x68,%eax
f01036fa:	ee                   	out    %al,(%dx)
f01036fb:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103700:	ee                   	out    %al,(%dx)
	outb(IO_PIC1, 0x0a);             /* read IRR by default */

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irq_mask_8259A != 0xFFFF)
f0103701:	0f b7 05 a8 03 12 f0 	movzwl 0xf01203a8,%eax
f0103708:	66 83 f8 ff          	cmp    $0xffff,%ax
f010370c:	74 13                	je     f0103721 <pic_init+0x9e>
static bool didinit;

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
f010370e:	55                   	push   %ebp
f010370f:	89 e5                	mov    %esp,%ebp
f0103711:	83 ec 14             	sub    $0x14,%esp

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irq_mask_8259A != 0xFFFF)
		irq_setmask_8259A(irq_mask_8259A);
f0103714:	0f b7 c0             	movzwl %ax,%eax
f0103717:	50                   	push   %eax
f0103718:	e8 ee fe ff ff       	call   f010360b <irq_setmask_8259A>
f010371d:	83 c4 10             	add    $0x10,%esp
}
f0103720:	c9                   	leave  
f0103721:	f3 c3                	repz ret 

f0103723 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0103723:	55                   	push   %ebp
f0103724:	89 e5                	mov    %esp,%ebp
f0103726:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0103729:	ff 75 08             	pushl  0x8(%ebp)
f010372c:	e8 43 d0 ff ff       	call   f0100774 <cputchar>
	*cnt++;
}
f0103731:	83 c4 10             	add    $0x10,%esp
f0103734:	c9                   	leave  
f0103735:	c3                   	ret    

f0103736 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0103736:	55                   	push   %ebp
f0103737:	89 e5                	mov    %esp,%ebp
f0103739:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f010373c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0103743:	ff 75 0c             	pushl  0xc(%ebp)
f0103746:	ff 75 08             	pushl  0x8(%ebp)
f0103749:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010374c:	50                   	push   %eax
f010374d:	68 23 37 10 f0       	push   $0xf0103723
f0103752:	e8 bd 17 00 00       	call   f0104f14 <vprintfmt>
	return cnt;
}
f0103757:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010375a:	c9                   	leave  
f010375b:	c3                   	ret    

f010375c <cprintf>:

int
cprintf(const char *fmt, ...)
{
f010375c:	55                   	push   %ebp
f010375d:	89 e5                	mov    %esp,%ebp
f010375f:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0103762:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0103765:	50                   	push   %eax
f0103766:	ff 75 08             	pushl  0x8(%ebp)
f0103769:	e8 c8 ff ff ff       	call   f0103736 <vcprintf>
	va_end(ap);

	return cnt;
}
f010376e:	c9                   	leave  
f010376f:	c3                   	ret    

f0103770 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f0103770:	55                   	push   %ebp
f0103771:	89 e5                	mov    %esp,%ebp
f0103773:	57                   	push   %edi
f0103774:	56                   	push   %esi
f0103775:	53                   	push   %ebx
f0103776:	83 ec 0c             	sub    $0xc,%esp
	// wrong, you may not get a fault until you try to return from
	// user space on that CPU.
	//
	// LAB 4: Your code here:
	
	int cpu_id = thiscpu->cpu_id;
f0103779:	e8 dc 24 00 00       	call   f0105c5a <cpunum>
f010377e:	6b c0 74             	imul   $0x74,%eax,%eax
f0103781:	0f b6 98 20 00 23 f0 	movzbl -0xfdcffe0(%eax),%ebx
	cprintf("cpu_id == %d\n",cpu_id );
f0103788:	83 ec 08             	sub    $0x8,%esp
f010378b:	53                   	push   %ebx
f010378c:	68 3c 75 10 f0       	push   $0xf010753c
f0103791:	e8 c6 ff ff ff       	call   f010375c <cprintf>
	thiscpu->cpu_ts.ts_esp0 = KSTACKTOP - cpu_id*( KSTKSIZE  + KSTKGAP);
f0103796:	e8 bf 24 00 00       	call   f0105c5a <cpunum>
f010379b:	6b c0 74             	imul   $0x74,%eax,%eax
f010379e:	89 d9                	mov    %ebx,%ecx
f01037a0:	c1 e1 10             	shl    $0x10,%ecx
f01037a3:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f01037a8:	29 ca                	sub    %ecx,%edx
f01037aa:	89 90 30 00 23 f0    	mov    %edx,-0xfdcffd0(%eax)
	thiscpu->cpu_ts.ts_ss0 = GD_KD;
f01037b0:	e8 a5 24 00 00       	call   f0105c5a <cpunum>
f01037b5:	6b c0 74             	imul   $0x74,%eax,%eax
f01037b8:	66 c7 80 34 00 23 f0 	movw   $0x10,-0xfdcffcc(%eax)
f01037bf:	10 00 
	gdt[ (GD_TSS0 >> 3) + cpu_id] = SEG16(STS_T32A, (uint32_t) (& (thiscpu->cpu_ts) ),
f01037c1:	83 c3 05             	add    $0x5,%ebx
f01037c4:	e8 91 24 00 00       	call   f0105c5a <cpunum>
f01037c9:	89 c7                	mov    %eax,%edi
f01037cb:	e8 8a 24 00 00       	call   f0105c5a <cpunum>
f01037d0:	89 c6                	mov    %eax,%esi
f01037d2:	e8 83 24 00 00       	call   f0105c5a <cpunum>
f01037d7:	66 c7 04 dd 40 03 12 	movw   $0x67,-0xfedfcc0(,%ebx,8)
f01037de:	f0 67 00 
f01037e1:	6b ff 74             	imul   $0x74,%edi,%edi
f01037e4:	81 c7 2c 00 23 f0    	add    $0xf023002c,%edi
f01037ea:	66 89 3c dd 42 03 12 	mov    %di,-0xfedfcbe(,%ebx,8)
f01037f1:	f0 
f01037f2:	6b d6 74             	imul   $0x74,%esi,%edx
f01037f5:	81 c2 2c 00 23 f0    	add    $0xf023002c,%edx
f01037fb:	c1 ea 10             	shr    $0x10,%edx
f01037fe:	88 14 dd 44 03 12 f0 	mov    %dl,-0xfedfcbc(,%ebx,8)
f0103805:	c6 04 dd 46 03 12 f0 	movb   $0x40,-0xfedfcba(,%ebx,8)
f010380c:	40 
f010380d:	6b c0 74             	imul   $0x74,%eax,%eax
f0103810:	05 2c 00 23 f0       	add    $0xf023002c,%eax
f0103815:	c1 e8 18             	shr    $0x18,%eax
f0103818:	88 04 dd 47 03 12 f0 	mov    %al,-0xfedfcb9(,%ebx,8)
					sizeof(struct Taskstate) - 1, 0);
	gdt[(GD_TSS0 >> 3) + cpu_id].sd_s = 0;
f010381f:	c6 04 dd 45 03 12 f0 	movb   $0x89,-0xfedfcbb(,%ebx,8)
f0103826:	89 
}

static __inline void
ltr(uint16_t sel)
{
	__asm __volatile("ltr %0" : : "r" (sel));
f0103827:	c1 e3 03             	shl    $0x3,%ebx
f010382a:	0f 00 db             	ltr    %bx
}

static __inline void
lidt(void *p)
{
	__asm __volatile("lidt (%0)" : : "r" (p));
f010382d:	b8 ac 03 12 f0       	mov    $0xf01203ac,%eax
f0103832:	0f 01 18             	lidtl  (%eax)
	// Load the IDT
	lidt(&idt_pd);
	*/


}
f0103835:	83 c4 10             	add    $0x10,%esp
f0103838:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010383b:	5b                   	pop    %ebx
f010383c:	5e                   	pop    %esi
f010383d:	5f                   	pop    %edi
f010383e:	5d                   	pop    %ebp
f010383f:	c3                   	ret    

f0103840 <trap_init>:
}


void
trap_init(void)
{
f0103840:	55                   	push   %ebp
f0103841:	89 e5                	mov    %esp,%ebp
f0103843:	83 ec 08             	sub    $0x8,%esp
    void handlerIRQ7();
    void handlerIRQ14();
    void handlerIRQ19();
 

    SETGATE(idt[0], 0, GD_KT, handler0, 0);
f0103846:	b8 52 42 10 f0       	mov    $0xf0104252,%eax
f010384b:	66 a3 60 f2 22 f0    	mov    %ax,0xf022f260
f0103851:	66 c7 05 62 f2 22 f0 	movw   $0x8,0xf022f262
f0103858:	08 00 
f010385a:	c6 05 64 f2 22 f0 00 	movb   $0x0,0xf022f264
f0103861:	c6 05 65 f2 22 f0 8e 	movb   $0x8e,0xf022f265
f0103868:	c1 e8 10             	shr    $0x10,%eax
f010386b:	66 a3 66 f2 22 f0    	mov    %ax,0xf022f266
    SETGATE(idt[1], 0, GD_KT, handler1, 0);
f0103871:	b8 5c 42 10 f0       	mov    $0xf010425c,%eax
f0103876:	66 a3 68 f2 22 f0    	mov    %ax,0xf022f268
f010387c:	66 c7 05 6a f2 22 f0 	movw   $0x8,0xf022f26a
f0103883:	08 00 
f0103885:	c6 05 6c f2 22 f0 00 	movb   $0x0,0xf022f26c
f010388c:	c6 05 6d f2 22 f0 8e 	movb   $0x8e,0xf022f26d
f0103893:	c1 e8 10             	shr    $0x10,%eax
f0103896:	66 a3 6e f2 22 f0    	mov    %ax,0xf022f26e
    SETGATE(idt[2], 0, GD_KT, handler2, 0);
f010389c:	b8 66 42 10 f0       	mov    $0xf0104266,%eax
f01038a1:	66 a3 70 f2 22 f0    	mov    %ax,0xf022f270
f01038a7:	66 c7 05 72 f2 22 f0 	movw   $0x8,0xf022f272
f01038ae:	08 00 
f01038b0:	c6 05 74 f2 22 f0 00 	movb   $0x0,0xf022f274
f01038b7:	c6 05 75 f2 22 f0 8e 	movb   $0x8e,0xf022f275
f01038be:	c1 e8 10             	shr    $0x10,%eax
f01038c1:	66 a3 76 f2 22 f0    	mov    %ax,0xf022f276
    SETGATE(idt[3], 0, GD_KT, handler3, 3);
f01038c7:	b8 70 42 10 f0       	mov    $0xf0104270,%eax
f01038cc:	66 a3 78 f2 22 f0    	mov    %ax,0xf022f278
f01038d2:	66 c7 05 7a f2 22 f0 	movw   $0x8,0xf022f27a
f01038d9:	08 00 
f01038db:	c6 05 7c f2 22 f0 00 	movb   $0x0,0xf022f27c
f01038e2:	c6 05 7d f2 22 f0 ee 	movb   $0xee,0xf022f27d
f01038e9:	c1 e8 10             	shr    $0x10,%eax
f01038ec:	66 a3 7e f2 22 f0    	mov    %ax,0xf022f27e
    SETGATE(idt[4], 0, GD_KT, handler4, 0);
f01038f2:	b8 76 42 10 f0       	mov    $0xf0104276,%eax
f01038f7:	66 a3 80 f2 22 f0    	mov    %ax,0xf022f280
f01038fd:	66 c7 05 82 f2 22 f0 	movw   $0x8,0xf022f282
f0103904:	08 00 
f0103906:	c6 05 84 f2 22 f0 00 	movb   $0x0,0xf022f284
f010390d:	c6 05 85 f2 22 f0 8e 	movb   $0x8e,0xf022f285
f0103914:	c1 e8 10             	shr    $0x10,%eax
f0103917:	66 a3 86 f2 22 f0    	mov    %ax,0xf022f286
    SETGATE(idt[5], 0, GD_KT, handler5, 0);
f010391d:	b8 7c 42 10 f0       	mov    $0xf010427c,%eax
f0103922:	66 a3 88 f2 22 f0    	mov    %ax,0xf022f288
f0103928:	66 c7 05 8a f2 22 f0 	movw   $0x8,0xf022f28a
f010392f:	08 00 
f0103931:	c6 05 8c f2 22 f0 00 	movb   $0x0,0xf022f28c
f0103938:	c6 05 8d f2 22 f0 8e 	movb   $0x8e,0xf022f28d
f010393f:	c1 e8 10             	shr    $0x10,%eax
f0103942:	66 a3 8e f2 22 f0    	mov    %ax,0xf022f28e
    SETGATE(idt[6], 0, GD_KT, handler6, 0);
f0103948:	b8 82 42 10 f0       	mov    $0xf0104282,%eax
f010394d:	66 a3 90 f2 22 f0    	mov    %ax,0xf022f290
f0103953:	66 c7 05 92 f2 22 f0 	movw   $0x8,0xf022f292
f010395a:	08 00 
f010395c:	c6 05 94 f2 22 f0 00 	movb   $0x0,0xf022f294
f0103963:	c6 05 95 f2 22 f0 8e 	movb   $0x8e,0xf022f295
f010396a:	c1 e8 10             	shr    $0x10,%eax
f010396d:	66 a3 96 f2 22 f0    	mov    %ax,0xf022f296
    SETGATE(idt[7], 0, GD_KT, handler7, 0);
f0103973:	b8 88 42 10 f0       	mov    $0xf0104288,%eax
f0103978:	66 a3 98 f2 22 f0    	mov    %ax,0xf022f298
f010397e:	66 c7 05 9a f2 22 f0 	movw   $0x8,0xf022f29a
f0103985:	08 00 
f0103987:	c6 05 9c f2 22 f0 00 	movb   $0x0,0xf022f29c
f010398e:	c6 05 9d f2 22 f0 8e 	movb   $0x8e,0xf022f29d
f0103995:	c1 e8 10             	shr    $0x10,%eax
f0103998:	66 a3 9e f2 22 f0    	mov    %ax,0xf022f29e
    SETGATE(idt[8], 0, GD_KT, handler8, 0);
f010399e:	b8 8e 42 10 f0       	mov    $0xf010428e,%eax
f01039a3:	66 a3 a0 f2 22 f0    	mov    %ax,0xf022f2a0
f01039a9:	66 c7 05 a2 f2 22 f0 	movw   $0x8,0xf022f2a2
f01039b0:	08 00 
f01039b2:	c6 05 a4 f2 22 f0 00 	movb   $0x0,0xf022f2a4
f01039b9:	c6 05 a5 f2 22 f0 8e 	movb   $0x8e,0xf022f2a5
f01039c0:	c1 e8 10             	shr    $0x10,%eax
f01039c3:	66 a3 a6 f2 22 f0    	mov    %ax,0xf022f2a6
    SETGATE(idt[9], 0, GD_KT, handler9, 0);
f01039c9:	b8 92 42 10 f0       	mov    $0xf0104292,%eax
f01039ce:	66 a3 a8 f2 22 f0    	mov    %ax,0xf022f2a8
f01039d4:	66 c7 05 aa f2 22 f0 	movw   $0x8,0xf022f2aa
f01039db:	08 00 
f01039dd:	c6 05 ac f2 22 f0 00 	movb   $0x0,0xf022f2ac
f01039e4:	c6 05 ad f2 22 f0 8e 	movb   $0x8e,0xf022f2ad
f01039eb:	c1 e8 10             	shr    $0x10,%eax
f01039ee:	66 a3 ae f2 22 f0    	mov    %ax,0xf022f2ae
    SETGATE(idt[10], 0, GD_KT, handler10, 0);
f01039f4:	b8 98 42 10 f0       	mov    $0xf0104298,%eax
f01039f9:	66 a3 b0 f2 22 f0    	mov    %ax,0xf022f2b0
f01039ff:	66 c7 05 b2 f2 22 f0 	movw   $0x8,0xf022f2b2
f0103a06:	08 00 
f0103a08:	c6 05 b4 f2 22 f0 00 	movb   $0x0,0xf022f2b4
f0103a0f:	c6 05 b5 f2 22 f0 8e 	movb   $0x8e,0xf022f2b5
f0103a16:	c1 e8 10             	shr    $0x10,%eax
f0103a19:	66 a3 b6 f2 22 f0    	mov    %ax,0xf022f2b6
    SETGATE(idt[11], 0, GD_KT, handler11, 0);
f0103a1f:	b8 9c 42 10 f0       	mov    $0xf010429c,%eax
f0103a24:	66 a3 b8 f2 22 f0    	mov    %ax,0xf022f2b8
f0103a2a:	66 c7 05 ba f2 22 f0 	movw   $0x8,0xf022f2ba
f0103a31:	08 00 
f0103a33:	c6 05 bc f2 22 f0 00 	movb   $0x0,0xf022f2bc
f0103a3a:	c6 05 bd f2 22 f0 8e 	movb   $0x8e,0xf022f2bd
f0103a41:	c1 e8 10             	shr    $0x10,%eax
f0103a44:	66 a3 be f2 22 f0    	mov    %ax,0xf022f2be
    SETGATE(idt[12], 0, GD_KT, handler12, 0);
f0103a4a:	b8 a0 42 10 f0       	mov    $0xf01042a0,%eax
f0103a4f:	66 a3 c0 f2 22 f0    	mov    %ax,0xf022f2c0
f0103a55:	66 c7 05 c2 f2 22 f0 	movw   $0x8,0xf022f2c2
f0103a5c:	08 00 
f0103a5e:	c6 05 c4 f2 22 f0 00 	movb   $0x0,0xf022f2c4
f0103a65:	c6 05 c5 f2 22 f0 8e 	movb   $0x8e,0xf022f2c5
f0103a6c:	c1 e8 10             	shr    $0x10,%eax
f0103a6f:	66 a3 c6 f2 22 f0    	mov    %ax,0xf022f2c6
    SETGATE(idt[13], 0, GD_KT, handler13, 0);
f0103a75:	b8 a4 42 10 f0       	mov    $0xf01042a4,%eax
f0103a7a:	66 a3 c8 f2 22 f0    	mov    %ax,0xf022f2c8
f0103a80:	66 c7 05 ca f2 22 f0 	movw   $0x8,0xf022f2ca
f0103a87:	08 00 
f0103a89:	c6 05 cc f2 22 f0 00 	movb   $0x0,0xf022f2cc
f0103a90:	c6 05 cd f2 22 f0 8e 	movb   $0x8e,0xf022f2cd
f0103a97:	c1 e8 10             	shr    $0x10,%eax
f0103a9a:	66 a3 ce f2 22 f0    	mov    %ax,0xf022f2ce
    SETGATE(idt[14], 0, GD_KT, handler14, 0);
f0103aa0:	b8 a8 42 10 f0       	mov    $0xf01042a8,%eax
f0103aa5:	66 a3 d0 f2 22 f0    	mov    %ax,0xf022f2d0
f0103aab:	66 c7 05 d2 f2 22 f0 	movw   $0x8,0xf022f2d2
f0103ab2:	08 00 
f0103ab4:	c6 05 d4 f2 22 f0 00 	movb   $0x0,0xf022f2d4
f0103abb:	c6 05 d5 f2 22 f0 8e 	movb   $0x8e,0xf022f2d5
f0103ac2:	c1 e8 10             	shr    $0x10,%eax
f0103ac5:	66 a3 d6 f2 22 f0    	mov    %ax,0xf022f2d6
    SETGATE(idt[15], 0, GD_KT, handler15, 0);
f0103acb:	b8 ac 42 10 f0       	mov    $0xf01042ac,%eax
f0103ad0:	66 a3 d8 f2 22 f0    	mov    %ax,0xf022f2d8
f0103ad6:	66 c7 05 da f2 22 f0 	movw   $0x8,0xf022f2da
f0103add:	08 00 
f0103adf:	c6 05 dc f2 22 f0 00 	movb   $0x0,0xf022f2dc
f0103ae6:	c6 05 dd f2 22 f0 8e 	movb   $0x8e,0xf022f2dd
f0103aed:	c1 e8 10             	shr    $0x10,%eax
f0103af0:	66 a3 de f2 22 f0    	mov    %ax,0xf022f2de
    SETGATE(idt[16], 0, GD_KT, handler16, 0);
f0103af6:	b8 b2 42 10 f0       	mov    $0xf01042b2,%eax
f0103afb:	66 a3 e0 f2 22 f0    	mov    %ax,0xf022f2e0
f0103b01:	66 c7 05 e2 f2 22 f0 	movw   $0x8,0xf022f2e2
f0103b08:	08 00 
f0103b0a:	c6 05 e4 f2 22 f0 00 	movb   $0x0,0xf022f2e4
f0103b11:	c6 05 e5 f2 22 f0 8e 	movb   $0x8e,0xf022f2e5
f0103b18:	c1 e8 10             	shr    $0x10,%eax
f0103b1b:	66 a3 e6 f2 22 f0    	mov    %ax,0xf022f2e6
    SETGATE(idt[17], 0, GD_KT, handler17, 0);
f0103b21:	b8 b8 42 10 f0       	mov    $0xf01042b8,%eax
f0103b26:	66 a3 e8 f2 22 f0    	mov    %ax,0xf022f2e8
f0103b2c:	66 c7 05 ea f2 22 f0 	movw   $0x8,0xf022f2ea
f0103b33:	08 00 
f0103b35:	c6 05 ec f2 22 f0 00 	movb   $0x0,0xf022f2ec
f0103b3c:	c6 05 ed f2 22 f0 8e 	movb   $0x8e,0xf022f2ed
f0103b43:	c1 e8 10             	shr    $0x10,%eax
f0103b46:	66 a3 ee f2 22 f0    	mov    %ax,0xf022f2ee
    SETGATE(idt[18], 0, GD_KT, handler18, 0);
f0103b4c:	b8 bc 42 10 f0       	mov    $0xf01042bc,%eax
f0103b51:	66 a3 f0 f2 22 f0    	mov    %ax,0xf022f2f0
f0103b57:	66 c7 05 f2 f2 22 f0 	movw   $0x8,0xf022f2f2
f0103b5e:	08 00 
f0103b60:	c6 05 f4 f2 22 f0 00 	movb   $0x0,0xf022f2f4
f0103b67:	c6 05 f5 f2 22 f0 8e 	movb   $0x8e,0xf022f2f5
f0103b6e:	c1 e8 10             	shr    $0x10,%eax
f0103b71:	66 a3 f6 f2 22 f0    	mov    %ax,0xf022f2f6
    SETGATE(idt[19], 0, GD_KT, handler19, 0);
f0103b77:	b8 c2 42 10 f0       	mov    $0xf01042c2,%eax
f0103b7c:	66 a3 f8 f2 22 f0    	mov    %ax,0xf022f2f8
f0103b82:	66 c7 05 fa f2 22 f0 	movw   $0x8,0xf022f2fa
f0103b89:	08 00 
f0103b8b:	c6 05 fc f2 22 f0 00 	movb   $0x0,0xf022f2fc
f0103b92:	c6 05 fd f2 22 f0 8e 	movb   $0x8e,0xf022f2fd
f0103b99:	c1 e8 10             	shr    $0x10,%eax
f0103b9c:	66 a3 fe f2 22 f0    	mov    %ax,0xf022f2fe

    SETGATE(idt[T_SYSCALL], 0, GD_KT, handler_syscall, 3);
f0103ba2:	b8 c8 42 10 f0       	mov    $0xf01042c8,%eax
f0103ba7:	66 a3 e0 f3 22 f0    	mov    %ax,0xf022f3e0
f0103bad:	66 c7 05 e2 f3 22 f0 	movw   $0x8,0xf022f3e2
f0103bb4:	08 00 
f0103bb6:	c6 05 e4 f3 22 f0 00 	movb   $0x0,0xf022f3e4
f0103bbd:	c6 05 e5 f3 22 f0 ee 	movb   $0xee,0xf022f3e5
f0103bc4:	c1 e8 10             	shr    $0x10,%eax
f0103bc7:	66 a3 e6 f3 22 f0    	mov    %ax,0xf022f3e6

    //lab4
    SETGATE(idt[IRQ_OFFSET+IRQ_TIMER], 	0, GD_KT, handlerIRQ0, 0);
f0103bcd:	b8 ce 42 10 f0       	mov    $0xf01042ce,%eax
f0103bd2:	66 a3 60 f3 22 f0    	mov    %ax,0xf022f360
f0103bd8:	66 c7 05 62 f3 22 f0 	movw   $0x8,0xf022f362
f0103bdf:	08 00 
f0103be1:	c6 05 64 f3 22 f0 00 	movb   $0x0,0xf022f364
f0103be8:	c6 05 65 f3 22 f0 8e 	movb   $0x8e,0xf022f365
f0103bef:	c1 e8 10             	shr    $0x10,%eax
f0103bf2:	66 a3 66 f3 22 f0    	mov    %ax,0xf022f366
    SETGATE(idt[IRQ_OFFSET+IRQ_KBD], 	0, GD_KT, handlerIRQ1, 0);
f0103bf8:	b8 d4 42 10 f0       	mov    $0xf01042d4,%eax
f0103bfd:	66 a3 68 f3 22 f0    	mov    %ax,0xf022f368
f0103c03:	66 c7 05 6a f3 22 f0 	movw   $0x8,0xf022f36a
f0103c0a:	08 00 
f0103c0c:	c6 05 6c f3 22 f0 00 	movb   $0x0,0xf022f36c
f0103c13:	c6 05 6d f3 22 f0 8e 	movb   $0x8e,0xf022f36d
f0103c1a:	c1 e8 10             	shr    $0x10,%eax
f0103c1d:	66 a3 6e f3 22 f0    	mov    %ax,0xf022f36e
    SETGATE(idt[IRQ_OFFSET+IRQ_SERIAL], 0, GD_KT, handlerIRQ4, 0);
f0103c23:	b8 da 42 10 f0       	mov    $0xf01042da,%eax
f0103c28:	66 a3 80 f3 22 f0    	mov    %ax,0xf022f380
f0103c2e:	66 c7 05 82 f3 22 f0 	movw   $0x8,0xf022f382
f0103c35:	08 00 
f0103c37:	c6 05 84 f3 22 f0 00 	movb   $0x0,0xf022f384
f0103c3e:	c6 05 85 f3 22 f0 8e 	movb   $0x8e,0xf022f385
f0103c45:	c1 e8 10             	shr    $0x10,%eax
f0103c48:	66 a3 86 f3 22 f0    	mov    %ax,0xf022f386
    SETGATE(idt[IRQ_OFFSET+IRQ_SPURIOUS], 0, GD_KT, handlerIRQ7, 0);
f0103c4e:	b8 e0 42 10 f0       	mov    $0xf01042e0,%eax
f0103c53:	66 a3 98 f3 22 f0    	mov    %ax,0xf022f398
f0103c59:	66 c7 05 9a f3 22 f0 	movw   $0x8,0xf022f39a
f0103c60:	08 00 
f0103c62:	c6 05 9c f3 22 f0 00 	movb   $0x0,0xf022f39c
f0103c69:	c6 05 9d f3 22 f0 8e 	movb   $0x8e,0xf022f39d
f0103c70:	c1 e8 10             	shr    $0x10,%eax
f0103c73:	66 a3 9e f3 22 f0    	mov    %ax,0xf022f39e
    SETGATE(idt[IRQ_OFFSET+IRQ_IDE], 	0, GD_KT, handlerIRQ14, 0);
f0103c79:	b8 e6 42 10 f0       	mov    $0xf01042e6,%eax
f0103c7e:	66 a3 d0 f3 22 f0    	mov    %ax,0xf022f3d0
f0103c84:	66 c7 05 d2 f3 22 f0 	movw   $0x8,0xf022f3d2
f0103c8b:	08 00 
f0103c8d:	c6 05 d4 f3 22 f0 00 	movb   $0x0,0xf022f3d4
f0103c94:	c6 05 d5 f3 22 f0 8e 	movb   $0x8e,0xf022f3d5
f0103c9b:	c1 e8 10             	shr    $0x10,%eax
f0103c9e:	66 a3 d6 f3 22 f0    	mov    %ax,0xf022f3d6
    SETGATE(idt[IRQ_OFFSET+IRQ_ERROR], 	0, GD_KT, handlerIRQ19, 0);
f0103ca4:	b8 ec 42 10 f0       	mov    $0xf01042ec,%eax
f0103ca9:	66 a3 f8 f3 22 f0    	mov    %ax,0xf022f3f8
f0103caf:	66 c7 05 fa f3 22 f0 	movw   $0x8,0xf022f3fa
f0103cb6:	08 00 
f0103cb8:	c6 05 fc f3 22 f0 00 	movb   $0x0,0xf022f3fc
f0103cbf:	c6 05 fd f3 22 f0 8e 	movb   $0x8e,0xf022f3fd
f0103cc6:	c1 e8 10             	shr    $0x10,%eax
f0103cc9:	66 a3 fe f3 22 f0    	mov    %ax,0xf022f3fe




	// Per-CPU setup 
	trap_init_percpu();
f0103ccf:	e8 9c fa ff ff       	call   f0103770 <trap_init_percpu>
}
f0103cd4:	c9                   	leave  
f0103cd5:	c3                   	ret    

f0103cd6 <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f0103cd6:	55                   	push   %ebp
f0103cd7:	89 e5                	mov    %esp,%ebp
f0103cd9:	53                   	push   %ebx
f0103cda:	83 ec 0c             	sub    $0xc,%esp
f0103cdd:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f0103ce0:	ff 33                	pushl  (%ebx)
f0103ce2:	68 4a 75 10 f0       	push   $0xf010754a
f0103ce7:	e8 70 fa ff ff       	call   f010375c <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f0103cec:	83 c4 08             	add    $0x8,%esp
f0103cef:	ff 73 04             	pushl  0x4(%ebx)
f0103cf2:	68 59 75 10 f0       	push   $0xf0107559
f0103cf7:	e8 60 fa ff ff       	call   f010375c <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f0103cfc:	83 c4 08             	add    $0x8,%esp
f0103cff:	ff 73 08             	pushl  0x8(%ebx)
f0103d02:	68 68 75 10 f0       	push   $0xf0107568
f0103d07:	e8 50 fa ff ff       	call   f010375c <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0103d0c:	83 c4 08             	add    $0x8,%esp
f0103d0f:	ff 73 0c             	pushl  0xc(%ebx)
f0103d12:	68 77 75 10 f0       	push   $0xf0107577
f0103d17:	e8 40 fa ff ff       	call   f010375c <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f0103d1c:	83 c4 08             	add    $0x8,%esp
f0103d1f:	ff 73 10             	pushl  0x10(%ebx)
f0103d22:	68 86 75 10 f0       	push   $0xf0107586
f0103d27:	e8 30 fa ff ff       	call   f010375c <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0103d2c:	83 c4 08             	add    $0x8,%esp
f0103d2f:	ff 73 14             	pushl  0x14(%ebx)
f0103d32:	68 95 75 10 f0       	push   $0xf0107595
f0103d37:	e8 20 fa ff ff       	call   f010375c <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0103d3c:	83 c4 08             	add    $0x8,%esp
f0103d3f:	ff 73 18             	pushl  0x18(%ebx)
f0103d42:	68 a4 75 10 f0       	push   $0xf01075a4
f0103d47:	e8 10 fa ff ff       	call   f010375c <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0103d4c:	83 c4 08             	add    $0x8,%esp
f0103d4f:	ff 73 1c             	pushl  0x1c(%ebx)
f0103d52:	68 b3 75 10 f0       	push   $0xf01075b3
f0103d57:	e8 00 fa ff ff       	call   f010375c <cprintf>
}
f0103d5c:	83 c4 10             	add    $0x10,%esp
f0103d5f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103d62:	c9                   	leave  
f0103d63:	c3                   	ret    

f0103d64 <print_trapframe>:

}

void
print_trapframe(struct Trapframe *tf)
{
f0103d64:	55                   	push   %ebp
f0103d65:	89 e5                	mov    %esp,%ebp
f0103d67:	56                   	push   %esi
f0103d68:	53                   	push   %ebx
f0103d69:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
f0103d6c:	e8 e9 1e 00 00       	call   f0105c5a <cpunum>
f0103d71:	83 ec 04             	sub    $0x4,%esp
f0103d74:	50                   	push   %eax
f0103d75:	53                   	push   %ebx
f0103d76:	68 17 76 10 f0       	push   $0xf0107617
f0103d7b:	e8 dc f9 ff ff       	call   f010375c <cprintf>
	print_regs(&tf->tf_regs);
f0103d80:	89 1c 24             	mov    %ebx,(%esp)
f0103d83:	e8 4e ff ff ff       	call   f0103cd6 <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f0103d88:	83 c4 08             	add    $0x8,%esp
f0103d8b:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f0103d8f:	50                   	push   %eax
f0103d90:	68 35 76 10 f0       	push   $0xf0107635
f0103d95:	e8 c2 f9 ff ff       	call   f010375c <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f0103d9a:	83 c4 08             	add    $0x8,%esp
f0103d9d:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f0103da1:	50                   	push   %eax
f0103da2:	68 48 76 10 f0       	push   $0xf0107648
f0103da7:	e8 b0 f9 ff ff       	call   f010375c <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103dac:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
f0103daf:	83 c4 10             	add    $0x10,%esp
f0103db2:	83 f8 13             	cmp    $0x13,%eax
f0103db5:	77 09                	ja     f0103dc0 <print_trapframe+0x5c>
		return excnames[trapno];
f0103db7:	8b 14 85 e0 78 10 f0 	mov    -0xfef8720(,%eax,4),%edx
f0103dbe:	eb 1f                	jmp    f0103ddf <print_trapframe+0x7b>
	if (trapno == T_SYSCALL)
f0103dc0:	83 f8 30             	cmp    $0x30,%eax
f0103dc3:	74 15                	je     f0103dda <print_trapframe+0x76>
		return "System call";
	if (trapno >= IRQ_OFFSET && trapno < IRQ_OFFSET + 16)
f0103dc5:	8d 50 e0             	lea    -0x20(%eax),%edx
		return "Hardware Interrupt";
	return "(unknown trap)";
f0103dc8:	83 fa 10             	cmp    $0x10,%edx
f0103dcb:	b9 e1 75 10 f0       	mov    $0xf01075e1,%ecx
f0103dd0:	ba ce 75 10 f0       	mov    $0xf01075ce,%edx
f0103dd5:	0f 43 d1             	cmovae %ecx,%edx
f0103dd8:	eb 05                	jmp    f0103ddf <print_trapframe+0x7b>
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
		return excnames[trapno];
	if (trapno == T_SYSCALL)
		return "System call";
f0103dda:	ba c2 75 10 f0       	mov    $0xf01075c2,%edx
{
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103ddf:	83 ec 04             	sub    $0x4,%esp
f0103de2:	52                   	push   %edx
f0103de3:	50                   	push   %eax
f0103de4:	68 5b 76 10 f0       	push   $0xf010765b
f0103de9:	e8 6e f9 ff ff       	call   f010375c <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0103dee:	83 c4 10             	add    $0x10,%esp
f0103df1:	3b 1d 60 fa 22 f0    	cmp    0xf022fa60,%ebx
f0103df7:	75 1a                	jne    f0103e13 <print_trapframe+0xaf>
f0103df9:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103dfd:	75 14                	jne    f0103e13 <print_trapframe+0xaf>

static __inline uint32_t
rcr2(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr2,%0" : "=r" (val));
f0103dff:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f0103e02:	83 ec 08             	sub    $0x8,%esp
f0103e05:	50                   	push   %eax
f0103e06:	68 6d 76 10 f0       	push   $0xf010766d
f0103e0b:	e8 4c f9 ff ff       	call   f010375c <cprintf>
f0103e10:	83 c4 10             	add    $0x10,%esp
	cprintf("  err  0x%08x", tf->tf_err);
f0103e13:	83 ec 08             	sub    $0x8,%esp
f0103e16:	ff 73 2c             	pushl  0x2c(%ebx)
f0103e19:	68 7c 76 10 f0       	push   $0xf010767c
f0103e1e:	e8 39 f9 ff ff       	call   f010375c <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f0103e23:	83 c4 10             	add    $0x10,%esp
f0103e26:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103e2a:	75 49                	jne    f0103e75 <print_trapframe+0x111>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f0103e2c:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f0103e2f:	89 c2                	mov    %eax,%edx
f0103e31:	83 e2 01             	and    $0x1,%edx
f0103e34:	ba fb 75 10 f0       	mov    $0xf01075fb,%edx
f0103e39:	b9 f0 75 10 f0       	mov    $0xf01075f0,%ecx
f0103e3e:	0f 44 ca             	cmove  %edx,%ecx
f0103e41:	89 c2                	mov    %eax,%edx
f0103e43:	83 e2 02             	and    $0x2,%edx
f0103e46:	ba 0d 76 10 f0       	mov    $0xf010760d,%edx
f0103e4b:	be 07 76 10 f0       	mov    $0xf0107607,%esi
f0103e50:	0f 45 d6             	cmovne %esi,%edx
f0103e53:	83 e0 04             	and    $0x4,%eax
f0103e56:	be 47 77 10 f0       	mov    $0xf0107747,%esi
f0103e5b:	b8 12 76 10 f0       	mov    $0xf0107612,%eax
f0103e60:	0f 44 c6             	cmove  %esi,%eax
f0103e63:	51                   	push   %ecx
f0103e64:	52                   	push   %edx
f0103e65:	50                   	push   %eax
f0103e66:	68 8a 76 10 f0       	push   $0xf010768a
f0103e6b:	e8 ec f8 ff ff       	call   f010375c <cprintf>
f0103e70:	83 c4 10             	add    $0x10,%esp
f0103e73:	eb 10                	jmp    f0103e85 <print_trapframe+0x121>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f0103e75:	83 ec 0c             	sub    $0xc,%esp
f0103e78:	68 30 74 10 f0       	push   $0xf0107430
f0103e7d:	e8 da f8 ff ff       	call   f010375c <cprintf>
f0103e82:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f0103e85:	83 ec 08             	sub    $0x8,%esp
f0103e88:	ff 73 30             	pushl  0x30(%ebx)
f0103e8b:	68 99 76 10 f0       	push   $0xf0107699
f0103e90:	e8 c7 f8 ff ff       	call   f010375c <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0103e95:	83 c4 08             	add    $0x8,%esp
f0103e98:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f0103e9c:	50                   	push   %eax
f0103e9d:	68 a8 76 10 f0       	push   $0xf01076a8
f0103ea2:	e8 b5 f8 ff ff       	call   f010375c <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f0103ea7:	83 c4 08             	add    $0x8,%esp
f0103eaa:	ff 73 38             	pushl  0x38(%ebx)
f0103ead:	68 bb 76 10 f0       	push   $0xf01076bb
f0103eb2:	e8 a5 f8 ff ff       	call   f010375c <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f0103eb7:	83 c4 10             	add    $0x10,%esp
f0103eba:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0103ebe:	74 25                	je     f0103ee5 <print_trapframe+0x181>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f0103ec0:	83 ec 08             	sub    $0x8,%esp
f0103ec3:	ff 73 3c             	pushl  0x3c(%ebx)
f0103ec6:	68 ca 76 10 f0       	push   $0xf01076ca
f0103ecb:	e8 8c f8 ff ff       	call   f010375c <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f0103ed0:	83 c4 08             	add    $0x8,%esp
f0103ed3:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f0103ed7:	50                   	push   %eax
f0103ed8:	68 d9 76 10 f0       	push   $0xf01076d9
f0103edd:	e8 7a f8 ff ff       	call   f010375c <cprintf>
f0103ee2:	83 c4 10             	add    $0x10,%esp
	}
}
f0103ee5:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0103ee8:	5b                   	pop    %ebx
f0103ee9:	5e                   	pop    %esi
f0103eea:	5d                   	pop    %ebp
f0103eeb:	c3                   	ret    

f0103eec <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f0103eec:	55                   	push   %ebp
f0103eed:	89 e5                	mov    %esp,%ebp
f0103eef:	57                   	push   %edi
f0103ef0:	56                   	push   %esi
f0103ef1:	53                   	push   %ebx
f0103ef2:	83 ec 4c             	sub    $0x4c,%esp
f0103ef5:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103ef8:	0f 20 d7             	mov    %cr2,%edi
	fault_va = rcr2();

	// Handle kernel-mode page faults.

	// LAB 3: Your code here.
	if(tf->tf_cs == GD_KT)
f0103efb:	66 83 7b 34 08       	cmpw   $0x8,0x34(%ebx)
f0103f00:	75 17                	jne    f0103f19 <page_fault_handler+0x2d>
		panic("page fault happens in the kern mode");
f0103f02:	83 ec 04             	sub    $0x4,%esp
f0103f05:	68 94 78 10 f0       	push   $0xf0107894
f0103f0a:	68 7b 01 00 00       	push   $0x17b
f0103f0f:	68 ec 76 10 f0       	push   $0xf01076ec
f0103f14:	e8 27 c1 ff ff       	call   f0100040 <_panic>
	//   user_mem_assert() and env_run() are useful here.
	//   To change what the user environment runs, modify 'curenv->env_tf'
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.
	if(!curenv->env_pgfault_upcall){
f0103f19:	e8 3c 1d 00 00       	call   f0105c5a <cpunum>
f0103f1e:	6b c0 74             	imul   $0x74,%eax,%eax
f0103f21:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f0103f27:	83 78 64 00          	cmpl   $0x0,0x64(%eax)
f0103f2b:	75 41                	jne    f0103f6e <page_fault_handler+0x82>
		// Destroy the environment that caused the fault.
		cprintf("[%08x] user fault va %08x ip %08x\n",
f0103f2d:	8b 73 30             	mov    0x30(%ebx),%esi
			curenv->env_id, fault_va, tf->tf_eip);
f0103f30:	e8 25 1d 00 00       	call   f0105c5a <cpunum>
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.
	if(!curenv->env_pgfault_upcall){
		// Destroy the environment that caused the fault.
		cprintf("[%08x] user fault va %08x ip %08x\n",
f0103f35:	56                   	push   %esi
f0103f36:	57                   	push   %edi
			curenv->env_id, fault_va, tf->tf_eip);
f0103f37:	6b c0 74             	imul   $0x74,%eax,%eax
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.
	if(!curenv->env_pgfault_upcall){
		// Destroy the environment that caused the fault.
		cprintf("[%08x] user fault va %08x ip %08x\n",
f0103f3a:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f0103f40:	ff 70 48             	pushl  0x48(%eax)
f0103f43:	68 b8 78 10 f0       	push   $0xf01078b8
f0103f48:	e8 0f f8 ff ff       	call   f010375c <cprintf>
			curenv->env_id, fault_va, tf->tf_eip);
		print_trapframe(tf);
f0103f4d:	89 1c 24             	mov    %ebx,(%esp)
f0103f50:	e8 0f fe ff ff       	call   f0103d64 <print_trapframe>
		env_destroy(curenv);
f0103f55:	e8 00 1d 00 00       	call   f0105c5a <cpunum>
f0103f5a:	83 c4 04             	add    $0x4,%esp
f0103f5d:	6b c0 74             	imul   $0x74,%eax,%eax
f0103f60:	ff b0 28 00 23 f0    	pushl  -0xfdcffd8(%eax)
f0103f66:	e8 d2 f4 ff ff       	call   f010343d <env_destroy>
f0103f6b:	83 c4 10             	add    $0x10,%esp

	unsigned int newEsp=0;
	struct UTrapframe UT;
	
	//the Exception has not been built
	if( tf->tf_esp < UXSTACKTOP-PGSIZE || tf->tf_esp >= UXSTACKTOP) {
f0103f6e:	8b 73 3c             	mov    0x3c(%ebx),%esi
f0103f71:	8d 86 00 10 40 11    	lea    0x11401000(%esi),%eax
		
		newEsp = UXSTACKTOP - sizeof(struct UTrapframe);
	}
	else
		//note: it is not like the requirement!!! there is two block
		newEsp = tf->tf_esp - sizeof(struct UTrapframe) -8;
f0103f77:	83 ee 3c             	sub    $0x3c,%esi
f0103f7a:	3d ff 0f 00 00       	cmp    $0xfff,%eax
f0103f7f:	b8 cc ff bf ee       	mov    $0xeebfffcc,%eax
f0103f84:	0f 47 f0             	cmova  %eax,%esi
	
	user_mem_assert(curenv, (void*)newEsp, 0, PTE_U|PTE_W|PTE_P);
f0103f87:	e8 ce 1c 00 00       	call   f0105c5a <cpunum>
f0103f8c:	6a 07                	push   $0x7
f0103f8e:	6a 00                	push   $0x0
f0103f90:	56                   	push   %esi
f0103f91:	6b c0 74             	imul   $0x74,%eax,%eax
f0103f94:	ff b0 28 00 23 f0    	pushl  -0xfdcffd8(%eax)
f0103f9a:	e8 f5 ed ff ff       	call   f0102d94 <user_mem_assert>

	UT.utf_err = tf->tf_err;
f0103f9f:	8b 43 2c             	mov    0x2c(%ebx),%eax
f0103fa2:	89 45 b8             	mov    %eax,-0x48(%ebp)
	UT.utf_regs = tf->tf_regs;
f0103fa5:	8b 03                	mov    (%ebx),%eax
f0103fa7:	89 45 bc             	mov    %eax,-0x44(%ebp)
f0103faa:	8b 43 04             	mov    0x4(%ebx),%eax
f0103fad:	89 45 c0             	mov    %eax,-0x40(%ebp)
f0103fb0:	8b 43 08             	mov    0x8(%ebx),%eax
f0103fb3:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0103fb6:	8b 43 0c             	mov    0xc(%ebx),%eax
f0103fb9:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0103fbc:	8b 43 10             	mov    0x10(%ebx),%eax
f0103fbf:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0103fc2:	8b 43 14             	mov    0x14(%ebx),%eax
f0103fc5:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0103fc8:	8b 43 18             	mov    0x18(%ebx),%eax
f0103fcb:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0103fce:	8b 43 1c             	mov    0x1c(%ebx),%eax
f0103fd1:	89 45 d8             	mov    %eax,-0x28(%ebp)
	UT.utf_eflags = tf->tf_eflags;
f0103fd4:	8b 43 38             	mov    0x38(%ebx),%eax
f0103fd7:	89 45 e0             	mov    %eax,-0x20(%ebp)
	UT.utf_eip = tf->tf_eip;
f0103fda:	8b 43 30             	mov    0x30(%ebx),%eax
f0103fdd:	89 45 dc             	mov    %eax,-0x24(%ebp)
	UT.utf_esp = tf->tf_esp;
f0103fe0:	8b 43 3c             	mov    0x3c(%ebx),%eax
f0103fe3:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	UT.utf_fault_va = fault_va;
f0103fe6:	89 7d b4             	mov    %edi,-0x4c(%ebp)

	user_mem_assert(curenv,(void*)newEsp, sizeof(struct UTrapframe),PTE_U|PTE_P|PTE_W );
f0103fe9:	e8 6c 1c 00 00       	call   f0105c5a <cpunum>
f0103fee:	6a 07                	push   $0x7
f0103ff0:	6a 34                	push   $0x34
f0103ff2:	56                   	push   %esi
f0103ff3:	6b c0 74             	imul   $0x74,%eax,%eax
f0103ff6:	ff b0 28 00 23 f0    	pushl  -0xfdcffd8(%eax)
f0103ffc:	e8 93 ed ff ff       	call   f0102d94 <user_mem_assert>
	memcpy((void*)newEsp, (&UT) ,sizeof(struct UTrapframe));
f0104001:	83 c4 1c             	add    $0x1c,%esp
f0104004:	6a 34                	push   $0x34
f0104006:	8d 45 b4             	lea    -0x4c(%ebp),%eax
f0104009:	50                   	push   %eax
f010400a:	56                   	push   %esi
f010400b:	e8 de 16 00 00       	call   f01056ee <memcpy>
	tf->tf_esp = newEsp;
f0104010:	89 73 3c             	mov    %esi,0x3c(%ebx)
	tf->tf_eip = (uintptr_t)curenv->env_pgfault_upcall;
f0104013:	e8 42 1c 00 00       	call   f0105c5a <cpunum>
f0104018:	6b c0 74             	imul   $0x74,%eax,%eax
f010401b:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f0104021:	8b 40 64             	mov    0x64(%eax),%eax
f0104024:	89 43 30             	mov    %eax,0x30(%ebx)
	env_run(curenv);
f0104027:	e8 2e 1c 00 00       	call   f0105c5a <cpunum>
f010402c:	83 c4 04             	add    $0x4,%esp
f010402f:	6b c0 74             	imul   $0x74,%eax,%eax
f0104032:	ff b0 28 00 23 f0    	pushl  -0xfdcffd8(%eax)
f0104038:	e8 9f f4 ff ff       	call   f01034dc <env_run>

f010403d <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f010403d:	55                   	push   %ebp
f010403e:	89 e5                	mov    %esp,%ebp
f0104040:	57                   	push   %edi
f0104041:	56                   	push   %esi
f0104042:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f0104045:	fc                   	cld    

	// Halt the CPU if some other CPU has called panic()
	extern char *panicstr;
	if (panicstr)
f0104046:	83 3d 80 fe 22 f0 00 	cmpl   $0x0,0xf022fe80
f010404d:	74 01                	je     f0104050 <trap+0x13>
		asm volatile("hlt");
f010404f:	f4                   	hlt    

	// Re-acqurie the big kernel lock if we were halted in
	// sched_yield()
	if (xchg(&thiscpu->cpu_status, CPU_STARTED) == CPU_HALTED)
f0104050:	e8 05 1c 00 00       	call   f0105c5a <cpunum>
f0104055:	6b d0 74             	imul   $0x74,%eax,%edx
f0104058:	81 c2 20 00 23 f0    	add    $0xf0230020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f010405e:	b8 01 00 00 00       	mov    $0x1,%eax
f0104063:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
f0104067:	83 f8 02             	cmp    $0x2,%eax
f010406a:	75 10                	jne    f010407c <trap+0x3f>
extern struct spinlock kernel_lock;

static inline void
lock_kernel(void)
{
	spin_lock(&kernel_lock);
f010406c:	83 ec 0c             	sub    $0xc,%esp
f010406f:	68 c0 03 12 f0       	push   $0xf01203c0
f0104074:	e8 4f 1e 00 00       	call   f0105ec8 <spin_lock>
f0104079:	83 c4 10             	add    $0x10,%esp

static __inline uint32_t
read_eflags(void)
{
	uint32_t eflags;
	__asm __volatile("pushfl; popl %0" : "=r" (eflags));
f010407c:	9c                   	pushf  
f010407d:	58                   	pop    %eax
		lock_kernel();
	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f010407e:	f6 c4 02             	test   $0x2,%ah
f0104081:	74 19                	je     f010409c <trap+0x5f>
f0104083:	68 f8 76 10 f0       	push   $0xf01076f8
f0104088:	68 5f 71 10 f0       	push   $0xf010715f
f010408d:	68 45 01 00 00       	push   $0x145
f0104092:	68 ec 76 10 f0       	push   $0xf01076ec
f0104097:	e8 a4 bf ff ff       	call   f0100040 <_panic>

	if ((tf->tf_cs & 3) == 3) {
f010409c:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f01040a0:	83 e0 03             	and    $0x3,%eax
f01040a3:	66 83 f8 03          	cmp    $0x3,%ax
f01040a7:	0f 85 a0 00 00 00    	jne    f010414d <trap+0x110>
f01040ad:	83 ec 0c             	sub    $0xc,%esp
f01040b0:	68 c0 03 12 f0       	push   $0xf01203c0
f01040b5:	e8 0e 1e 00 00       	call   f0105ec8 <spin_lock>
		// Trapped from user mode.
		// Acquire the big kernel lock before doing any
		// serious kernel work.
		// LAB 4: Your code here.如果是从用户态进入到内核态的话，需要获得锁
		lock_kernel();
		assert(curenv);
f01040ba:	e8 9b 1b 00 00       	call   f0105c5a <cpunum>
f01040bf:	6b c0 74             	imul   $0x74,%eax,%eax
f01040c2:	83 c4 10             	add    $0x10,%esp
f01040c5:	83 b8 28 00 23 f0 00 	cmpl   $0x0,-0xfdcffd8(%eax)
f01040cc:	75 19                	jne    f01040e7 <trap+0xaa>
f01040ce:	68 11 77 10 f0       	push   $0xf0107711
f01040d3:	68 5f 71 10 f0       	push   $0xf010715f
f01040d8:	68 4d 01 00 00       	push   $0x14d
f01040dd:	68 ec 76 10 f0       	push   $0xf01076ec
f01040e2:	e8 59 bf ff ff       	call   f0100040 <_panic>

		// Garbage collect if current enviroment is a zombie
		if (curenv->env_status == ENV_DYING) {
f01040e7:	e8 6e 1b 00 00       	call   f0105c5a <cpunum>
f01040ec:	6b c0 74             	imul   $0x74,%eax,%eax
f01040ef:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f01040f5:	83 78 54 01          	cmpl   $0x1,0x54(%eax)
f01040f9:	75 2d                	jne    f0104128 <trap+0xeb>
			env_free(curenv);
f01040fb:	e8 5a 1b 00 00       	call   f0105c5a <cpunum>
f0104100:	83 ec 0c             	sub    $0xc,%esp
f0104103:	6b c0 74             	imul   $0x74,%eax,%eax
f0104106:	ff b0 28 00 23 f0    	pushl  -0xfdcffd8(%eax)
f010410c:	e8 51 f1 ff ff       	call   f0103262 <env_free>
			curenv = NULL;
f0104111:	e8 44 1b 00 00       	call   f0105c5a <cpunum>
f0104116:	6b c0 74             	imul   $0x74,%eax,%eax
f0104119:	c7 80 28 00 23 f0 00 	movl   $0x0,-0xfdcffd8(%eax)
f0104120:	00 00 00 
			sched_yield();
f0104123:	e8 b0 02 00 00       	call   f01043d8 <sched_yield>
		}

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f0104128:	e8 2d 1b 00 00       	call   f0105c5a <cpunum>
f010412d:	6b c0 74             	imul   $0x74,%eax,%eax
f0104130:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f0104136:	b9 11 00 00 00       	mov    $0x11,%ecx
f010413b:	89 c7                	mov    %eax,%edi
f010413d:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f010413f:	e8 16 1b 00 00       	call   f0105c5a <cpunum>
f0104144:	6b c0 74             	imul   $0x74,%eax,%eax
f0104147:	8b b0 28 00 23 f0    	mov    -0xfdcffd8(%eax),%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f010414d:	89 35 60 fa 22 f0    	mov    %esi,0xf022fa60
static void
trap_dispatch(struct Trapframe *tf)
{
	// Handle processor exceptions.
	// LAB 3: Your code here.
	if(tf->tf_trapno == T_PGFLT){
f0104153:	8b 46 28             	mov    0x28(%esi),%eax
f0104156:	83 f8 0e             	cmp    $0xe,%eax
f0104159:	75 09                	jne    f0104164 <trap+0x127>
		page_fault_handler(tf);
f010415b:	83 ec 0c             	sub    $0xc,%esp
f010415e:	56                   	push   %esi
f010415f:	e8 88 fd ff ff       	call   f0103eec <page_fault_handler>
		return;
	}
	if(tf->tf_trapno == T_BRKPT){
f0104164:	83 f8 03             	cmp    $0x3,%eax
f0104167:	75 11                	jne    f010417a <trap+0x13d>
		monitor(tf);
f0104169:	83 ec 0c             	sub    $0xc,%esp
f010416c:	56                   	push   %esi
f010416d:	e8 1f c7 ff ff       	call   f0100891 <monitor>
f0104172:	83 c4 10             	add    $0x10,%esp
f0104175:	e9 97 00 00 00       	jmp    f0104211 <trap+0x1d4>
		return;
	}
	if(tf->tf_trapno == T_SYSCALL){
f010417a:	83 f8 30             	cmp    $0x30,%eax
f010417d:	75 21                	jne    f01041a0 <trap+0x163>
		tf->tf_regs.reg_eax= syscall(tf->tf_regs.reg_eax, 
f010417f:	83 ec 08             	sub    $0x8,%esp
f0104182:	ff 76 04             	pushl  0x4(%esi)
f0104185:	ff 36                	pushl  (%esi)
f0104187:	ff 76 10             	pushl  0x10(%esi)
f010418a:	ff 76 18             	pushl  0x18(%esi)
f010418d:	ff 76 14             	pushl  0x14(%esi)
f0104190:	ff 76 1c             	pushl  0x1c(%esi)
f0104193:	e8 c0 02 00 00       	call   f0104458 <syscall>
f0104198:	89 46 1c             	mov    %eax,0x1c(%esi)
f010419b:	83 c4 20             	add    $0x20,%esp
f010419e:	eb 71                	jmp    f0104211 <trap+0x1d4>
                            return;	
	}
	// Handle spurious interrupts
	// The hardware sometimes raises these because of noise on the
	// IRQ line or other reasons. We don't care.
	if (tf->tf_trapno == IRQ_OFFSET + IRQ_SPURIOUS) {
f01041a0:	83 f8 27             	cmp    $0x27,%eax
f01041a3:	75 1a                	jne    f01041bf <trap+0x182>
		cprintf("Spurious interrupt on irq 7\n");
f01041a5:	83 ec 0c             	sub    $0xc,%esp
f01041a8:	68 18 77 10 f0       	push   $0xf0107718
f01041ad:	e8 aa f5 ff ff       	call   f010375c <cprintf>
		print_trapframe(tf);
f01041b2:	89 34 24             	mov    %esi,(%esp)
f01041b5:	e8 aa fb ff ff       	call   f0103d64 <print_trapframe>
f01041ba:	83 c4 10             	add    $0x10,%esp
f01041bd:	eb 52                	jmp    f0104211 <trap+0x1d4>
	}

	// Handle clock interrupts. Don't forget to acknowledge the
	// interrupt using lapic_eoi() before calling the scheduler!
	// LAB 4: Your code here.
	if(tf->tf_trapno == IRQ_TIMER + IRQ_OFFSET){
f01041bf:	83 f8 20             	cmp    $0x20,%eax
f01041c2:	75 0a                	jne    f01041ce <trap+0x191>
		//cprintf("The Irq_Time is also work\n");
		lapic_eoi();
f01041c4:	e8 dc 1b 00 00       	call   f0105da5 <lapic_eoi>
		sched_yield();
f01041c9:	e8 0a 02 00 00       	call   f01043d8 <sched_yield>
		return;
	}

	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
f01041ce:	83 ec 0c             	sub    $0xc,%esp
f01041d1:	56                   	push   %esi
f01041d2:	e8 8d fb ff ff       	call   f0103d64 <print_trapframe>
	if (tf->tf_cs == GD_KT)
f01041d7:	83 c4 10             	add    $0x10,%esp
f01041da:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f01041df:	75 17                	jne    f01041f8 <trap+0x1bb>
		panic("unhandled trap in kernel");
f01041e1:	83 ec 04             	sub    $0x4,%esp
f01041e4:	68 35 77 10 f0       	push   $0xf0107735
f01041e9:	68 2b 01 00 00       	push   $0x12b
f01041ee:	68 ec 76 10 f0       	push   $0xf01076ec
f01041f3:	e8 48 be ff ff       	call   f0100040 <_panic>
	else {
		env_destroy(curenv);
f01041f8:	e8 5d 1a 00 00       	call   f0105c5a <cpunum>
f01041fd:	83 ec 0c             	sub    $0xc,%esp
f0104200:	6b c0 74             	imul   $0x74,%eax,%eax
f0104203:	ff b0 28 00 23 f0    	pushl  -0xfdcffd8(%eax)
f0104209:	e8 2f f2 ff ff       	call   f010343d <env_destroy>
f010420e:	83 c4 10             	add    $0x10,%esp
	trap_dispatch(tf);

	// If we made it to this point, then no other environment was
	// scheduled, so we should return to the current environment
	// if doing so makes sense.
	if (curenv && curenv->env_status == ENV_RUNNING)
f0104211:	e8 44 1a 00 00       	call   f0105c5a <cpunum>
f0104216:	6b c0 74             	imul   $0x74,%eax,%eax
f0104219:	83 b8 28 00 23 f0 00 	cmpl   $0x0,-0xfdcffd8(%eax)
f0104220:	74 2a                	je     f010424c <trap+0x20f>
f0104222:	e8 33 1a 00 00       	call   f0105c5a <cpunum>
f0104227:	6b c0 74             	imul   $0x74,%eax,%eax
f010422a:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f0104230:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0104234:	75 16                	jne    f010424c <trap+0x20f>
		env_run(curenv);
f0104236:	e8 1f 1a 00 00       	call   f0105c5a <cpunum>
f010423b:	83 ec 0c             	sub    $0xc,%esp
f010423e:	6b c0 74             	imul   $0x74,%eax,%eax
f0104241:	ff b0 28 00 23 f0    	pushl  -0xfdcffd8(%eax)
f0104247:	e8 90 f2 ff ff       	call   f01034dc <env_run>
	else
		sched_yield();
f010424c:	e8 87 01 00 00       	call   f01043d8 <sched_yield>
f0104251:	90                   	nop

f0104252 <handler0>:
.text

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */
TRAPHANDLER_NOEC(handler0, T_DIVIDE)
f0104252:	6a 00                	push   $0x0
f0104254:	6a 00                	push   $0x0
f0104256:	e9 97 00 00 00       	jmp    f01042f2 <_alltraps>
f010425b:	90                   	nop

f010425c <handler1>:
TRAPHANDLER_NOEC(handler1, T_DEBUG)
f010425c:	6a 00                	push   $0x0
f010425e:	6a 01                	push   $0x1
f0104260:	e9 8d 00 00 00       	jmp    f01042f2 <_alltraps>
f0104265:	90                   	nop

f0104266 <handler2>:
TRAPHANDLER_NOEC(handler2, T_NMI)
f0104266:	6a 00                	push   $0x0
f0104268:	6a 02                	push   $0x2
f010426a:	e9 83 00 00 00       	jmp    f01042f2 <_alltraps>
f010426f:	90                   	nop

f0104270 <handler3>:
TRAPHANDLER_NOEC(handler3, T_BRKPT)
f0104270:	6a 00                	push   $0x0
f0104272:	6a 03                	push   $0x3
f0104274:	eb 7c                	jmp    f01042f2 <_alltraps>

f0104276 <handler4>:
TRAPHANDLER_NOEC(handler4, T_OFLOW)
f0104276:	6a 00                	push   $0x0
f0104278:	6a 04                	push   $0x4
f010427a:	eb 76                	jmp    f01042f2 <_alltraps>

f010427c <handler5>:
TRAPHANDLER_NOEC(handler5, T_BOUND)
f010427c:	6a 00                	push   $0x0
f010427e:	6a 05                	push   $0x5
f0104280:	eb 70                	jmp    f01042f2 <_alltraps>

f0104282 <handler6>:
TRAPHANDLER_NOEC(handler6, T_ILLOP)
f0104282:	6a 00                	push   $0x0
f0104284:	6a 06                	push   $0x6
f0104286:	eb 6a                	jmp    f01042f2 <_alltraps>

f0104288 <handler7>:
TRAPHANDLER_NOEC(handler7, T_DEVICE)
f0104288:	6a 00                	push   $0x0
f010428a:	6a 07                	push   $0x7
f010428c:	eb 64                	jmp    f01042f2 <_alltraps>

f010428e <handler8>:
TRAPHANDLER(handler8, T_DBLFLT)
f010428e:	6a 08                	push   $0x8
f0104290:	eb 60                	jmp    f01042f2 <_alltraps>

f0104292 <handler9>:
TRAPHANDLER_NOEC(handler9, T_COPROC) /* reserved */
f0104292:	6a 00                	push   $0x0
f0104294:	6a 09                	push   $0x9
f0104296:	eb 5a                	jmp    f01042f2 <_alltraps>

f0104298 <handler10>:
TRAPHANDLER(handler10, T_TSS)
f0104298:	6a 0a                	push   $0xa
f010429a:	eb 56                	jmp    f01042f2 <_alltraps>

f010429c <handler11>:
TRAPHANDLER(handler11, T_SEGNP)
f010429c:	6a 0b                	push   $0xb
f010429e:	eb 52                	jmp    f01042f2 <_alltraps>

f01042a0 <handler12>:
TRAPHANDLER(handler12, T_STACK)
f01042a0:	6a 0c                	push   $0xc
f01042a2:	eb 4e                	jmp    f01042f2 <_alltraps>

f01042a4 <handler13>:
TRAPHANDLER(handler13, T_GPFLT)
f01042a4:	6a 0d                	push   $0xd
f01042a6:	eb 4a                	jmp    f01042f2 <_alltraps>

f01042a8 <handler14>:
TRAPHANDLER(handler14, T_PGFLT)
f01042a8:	6a 0e                	push   $0xe
f01042aa:	eb 46                	jmp    f01042f2 <_alltraps>

f01042ac <handler15>:
TRAPHANDLER_NOEC(handler15, T_RES)  /* reserved */
f01042ac:	6a 00                	push   $0x0
f01042ae:	6a 0f                	push   $0xf
f01042b0:	eb 40                	jmp    f01042f2 <_alltraps>

f01042b2 <handler16>:
TRAPHANDLER_NOEC(handler16, T_FPERR)
f01042b2:	6a 00                	push   $0x0
f01042b4:	6a 10                	push   $0x10
f01042b6:	eb 3a                	jmp    f01042f2 <_alltraps>

f01042b8 <handler17>:
TRAPHANDLER(handler17, T_ALIGN)
f01042b8:	6a 11                	push   $0x11
f01042ba:	eb 36                	jmp    f01042f2 <_alltraps>

f01042bc <handler18>:
TRAPHANDLER_NOEC(handler18, T_MCHK)
f01042bc:	6a 00                	push   $0x0
f01042be:	6a 12                	push   $0x12
f01042c0:	eb 30                	jmp    f01042f2 <_alltraps>

f01042c2 <handler19>:
TRAPHANDLER_NOEC(handler19, T_SIMDERR)
f01042c2:	6a 00                	push   $0x0
f01042c4:	6a 13                	push   $0x13
f01042c6:	eb 2a                	jmp    f01042f2 <_alltraps>

f01042c8 <handler_syscall>:

TRAPHANDLER_NOEC(handler_syscall, T_SYSCALL)
f01042c8:	6a 00                	push   $0x0
f01042ca:	6a 30                	push   $0x30
f01042cc:	eb 24                	jmp    f01042f2 <_alltraps>

f01042ce <handlerIRQ0>:

/*
* lab4
*/
	
TRAPHANDLER_NOEC(handlerIRQ0, IRQ_OFFSET+IRQ_TIMER)
f01042ce:	6a 00                	push   $0x0
f01042d0:	6a 20                	push   $0x20
f01042d2:	eb 1e                	jmp    f01042f2 <_alltraps>

f01042d4 <handlerIRQ1>:
TRAPHANDLER_NOEC(handlerIRQ1, IRQ_OFFSET+IRQ_KBD)
f01042d4:	6a 00                	push   $0x0
f01042d6:	6a 21                	push   $0x21
f01042d8:	eb 18                	jmp    f01042f2 <_alltraps>

f01042da <handlerIRQ4>:
TRAPHANDLER_NOEC(handlerIRQ4, IRQ_OFFSET+IRQ_SERIAL)
f01042da:	6a 00                	push   $0x0
f01042dc:	6a 24                	push   $0x24
f01042de:	eb 12                	jmp    f01042f2 <_alltraps>

f01042e0 <handlerIRQ7>:
TRAPHANDLER_NOEC(handlerIRQ7, IRQ_OFFSET+IRQ_SPURIOUS)
f01042e0:	6a 00                	push   $0x0
f01042e2:	6a 27                	push   $0x27
f01042e4:	eb 0c                	jmp    f01042f2 <_alltraps>

f01042e6 <handlerIRQ14>:
TRAPHANDLER_NOEC(handlerIRQ14, IRQ_OFFSET+IRQ_IDE)
f01042e6:	6a 00                	push   $0x0
f01042e8:	6a 2e                	push   $0x2e
f01042ea:	eb 06                	jmp    f01042f2 <_alltraps>

f01042ec <handlerIRQ19>:
TRAPHANDLER_NOEC(handlerIRQ19, IRQ_OFFSET+IRQ_ERROR)
f01042ec:	6a 00                	push   $0x0
f01042ee:	6a 33                	push   $0x33
f01042f0:	eb 00                	jmp    f01042f2 <_alltraps>

f01042f2 <_alltraps>:
/*
 * Lab 3: Your code here for _alltraps
 */
.globl _alltraps
_alltraps:
	pushl %ds
f01042f2:	1e                   	push   %ds
	pushl %es
f01042f3:	06                   	push   %es
	pushal
f01042f4:	60                   	pusha  
	movl $GD_KD, %eax
f01042f5:	b8 10 00 00 00       	mov    $0x10,%eax
	movw %ax, %ds
f01042fa:	8e d8                	mov    %eax,%ds
	movw %ax, %es
f01042fc:	8e c0                	mov    %eax,%es

	pushl %esp
f01042fe:	54                   	push   %esp
	call trap
f01042ff:	e8 39 fd ff ff       	call   f010403d <trap>

f0104304 <sched_halt>:
// Halt this CPU when there is nothing to do. Wait until the
// timer interrupt wakes it up. This function never returns.
//
void
sched_halt(void)
{
f0104304:	55                   	push   %ebp
f0104305:	89 e5                	mov    %esp,%ebp
f0104307:	83 ec 08             	sub    $0x8,%esp
f010430a:	a1 48 f2 22 f0       	mov    0xf022f248,%eax
f010430f:	8d 50 54             	lea    0x54(%eax),%edx
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f0104312:	b9 00 00 00 00       	mov    $0x0,%ecx
		if ((envs[i].env_status == ENV_RUNNABLE ||
f0104317:	8b 02                	mov    (%edx),%eax
f0104319:	83 e8 01             	sub    $0x1,%eax
f010431c:	83 f8 02             	cmp    $0x2,%eax
f010431f:	76 10                	jbe    f0104331 <sched_halt+0x2d>
{
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f0104321:	83 c1 01             	add    $0x1,%ecx
f0104324:	83 c2 7c             	add    $0x7c,%edx
f0104327:	81 f9 00 04 00 00    	cmp    $0x400,%ecx
f010432d:	75 e8                	jne    f0104317 <sched_halt+0x13>
f010432f:	eb 08                	jmp    f0104339 <sched_halt+0x35>
		if ((envs[i].env_status == ENV_RUNNABLE ||
		     envs[i].env_status == ENV_RUNNING ||
		     envs[i].env_status == ENV_DYING))
			break;
	}
	if (i == NENV) {
f0104331:	81 f9 00 04 00 00    	cmp    $0x400,%ecx
f0104337:	75 1f                	jne    f0104358 <sched_halt+0x54>
		cprintf("No runnable environments in the system!\n");
f0104339:	83 ec 0c             	sub    $0xc,%esp
f010433c:	68 30 79 10 f0       	push   $0xf0107930
f0104341:	e8 16 f4 ff ff       	call   f010375c <cprintf>
f0104346:	83 c4 10             	add    $0x10,%esp
		while (1)
			monitor(NULL);
f0104349:	83 ec 0c             	sub    $0xc,%esp
f010434c:	6a 00                	push   $0x0
f010434e:	e8 3e c5 ff ff       	call   f0100891 <monitor>
f0104353:	83 c4 10             	add    $0x10,%esp
f0104356:	eb f1                	jmp    f0104349 <sched_halt+0x45>
	}

	// Mark that no environment is running on this CPU
	curenv = NULL;
f0104358:	e8 fd 18 00 00       	call   f0105c5a <cpunum>
f010435d:	6b c0 74             	imul   $0x74,%eax,%eax
f0104360:	c7 80 28 00 23 f0 00 	movl   $0x0,-0xfdcffd8(%eax)
f0104367:	00 00 00 
	lcr3(PADDR(kern_pgdir));
f010436a:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010436f:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0104374:	77 12                	ja     f0104388 <sched_halt+0x84>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0104376:	50                   	push   %eax
f0104377:	68 48 63 10 f0       	push   $0xf0106348
f010437c:	6a 51                	push   $0x51
f010437e:	68 59 79 10 f0       	push   $0xf0107959
f0104383:	e8 b8 bc ff ff       	call   f0100040 <_panic>
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0104388:	05 00 00 00 10       	add    $0x10000000,%eax
f010438d:	0f 22 d8             	mov    %eax,%cr3

	// Mark that this CPU is in the HALT state, so that when
	// timer interupts come in, we know we should re-acquire the
	// big kernel lock
	xchg(&thiscpu->cpu_status, CPU_HALTED);
f0104390:	e8 c5 18 00 00       	call   f0105c5a <cpunum>
f0104395:	6b d0 74             	imul   $0x74,%eax,%edx
f0104398:	81 c2 20 00 23 f0    	add    $0xf0230020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f010439e:	b8 02 00 00 00       	mov    $0x2,%eax
f01043a3:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
}

static inline void
unlock_kernel(void)
{
	spin_unlock(&kernel_lock);
f01043a7:	83 ec 0c             	sub    $0xc,%esp
f01043aa:	68 c0 03 12 f0       	push   $0xf01203c0
f01043af:	e8 b1 1b 00 00       	call   f0105f65 <spin_unlock>

	// Normally we wouldn't need to do this, but QEMU only runs
	// one CPU at a time and has a long time-slice.  Without the
	// pause, this CPU is likely to reacquire the lock before
	// another CPU has even been given a chance to acquire it.
	asm volatile("pause");
f01043b4:	f3 90                	pause  
		"pushl $0\n"
		"sti\n"
		"1:\n"
		"hlt\n"
		"jmp 1b\n"
	: : "a" (thiscpu->cpu_ts.ts_esp0));
f01043b6:	e8 9f 18 00 00       	call   f0105c5a <cpunum>
f01043bb:	6b c0 74             	imul   $0x74,%eax,%eax

	// Release the big kernel lock as if we were "leaving" the kernel
	unlock_kernel();

	// Reset stack pointer, enable interrupts and then halt.
	asm volatile (
f01043be:	8b 80 30 00 23 f0    	mov    -0xfdcffd0(%eax),%eax
f01043c4:	bd 00 00 00 00       	mov    $0x0,%ebp
f01043c9:	89 c4                	mov    %eax,%esp
f01043cb:	6a 00                	push   $0x0
f01043cd:	6a 00                	push   $0x0
f01043cf:	fb                   	sti    
f01043d0:	f4                   	hlt    
f01043d1:	eb fd                	jmp    f01043d0 <sched_halt+0xcc>
		"sti\n"
		"1:\n"
		"hlt\n"
		"jmp 1b\n"
	: : "a" (thiscpu->cpu_ts.ts_esp0));
}
f01043d3:	83 c4 10             	add    $0x10,%esp
f01043d6:	c9                   	leave  
f01043d7:	c3                   	ret    

f01043d8 <sched_yield>:
void sched_halt(void);

// Choose a user environment to run and run it.
void
sched_yield(void)
{
f01043d8:	55                   	push   %ebp
f01043d9:	89 e5                	mov    %esp,%ebp
f01043db:	57                   	push   %edi
f01043dc:	56                   	push   %esi
f01043dd:	53                   	push   %ebx
f01043de:	83 ec 0c             	sub    $0xc,%esp
	// another CPU (env_status == ENV_RUNNING). If there are
	// no runnable environments, simply drop through to the code
	// below to halt the cpu.

	// LAB 4: Your code here.
	idle = curenv;
f01043e1:	e8 74 18 00 00       	call   f0105c5a <cpunum>
f01043e6:	6b c0 74             	imul   $0x74,%eax,%eax
f01043e9:	8b b8 28 00 23 f0    	mov    -0xfdcffd8(%eax),%edi
	size_t idx;
	if(idle!=NULL){
f01043ef:	85 ff                	test   %edi,%edi
f01043f1:	74 0a                	je     f01043fd <sched_yield+0x25>
	    idx=ENVX(idle->env_id);
f01043f3:	8b 47 48             	mov    0x48(%edi),%eax
f01043f6:	25 ff 03 00 00       	and    $0x3ff,%eax
f01043fb:	eb 05                	jmp    f0104402 <sched_yield+0x2a>
	}else{
	    idx=-1;
f01043fd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	}
	//在最后一次运行该CPU的env之后，以循环方式在“ envs”中搜索ENV_RUNNABLE环境。 切换到找到的第一个这样的环境。
	for (size_t i=0; i<NENV; i++) {
	    idx = (idx+1 == NENV) ? 0:idx+1;
	    if (envs[idx].env_status == ENV_RUNNABLE) {
f0104402:	8b 35 48 f2 22 f0    	mov    0xf022f248,%esi
f0104408:	b9 00 04 00 00       	mov    $0x400,%ecx
	}else{
	    idx=-1;
	}
	//在最后一次运行该CPU的env之后，以循环方式在“ envs”中搜索ENV_RUNNABLE环境。 切换到找到的第一个这样的环境。
	for (size_t i=0; i<NENV; i++) {
	    idx = (idx+1 == NENV) ? 0:idx+1;
f010440d:	bb 00 00 00 00       	mov    $0x0,%ebx
f0104412:	8d 50 01             	lea    0x1(%eax),%edx
f0104415:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f010441a:	89 d0                	mov    %edx,%eax
f010441c:	0f 44 c3             	cmove  %ebx,%eax
	    if (envs[idx].env_status == ENV_RUNNABLE) {
f010441f:	6b d0 7c             	imul   $0x7c,%eax,%edx
f0104422:	01 f2                	add    %esi,%edx
f0104424:	83 7a 54 02          	cmpl   $0x2,0x54(%edx)
f0104428:	75 09                	jne    f0104433 <sched_yield+0x5b>
		env_run(&envs[idx]);
f010442a:	83 ec 0c             	sub    $0xc,%esp
f010442d:	52                   	push   %edx
f010442e:	e8 a9 f0 ff ff       	call   f01034dc <env_run>
	    idx=ENVX(idle->env_id);
	}else{
	    idx=-1;
	}
	//在最后一次运行该CPU的env之后，以循环方式在“ envs”中搜索ENV_RUNNABLE环境。 切换到找到的第一个这样的环境。
	for (size_t i=0; i<NENV; i++) {
f0104433:	83 e9 01             	sub    $0x1,%ecx
f0104436:	75 da                	jne    f0104412 <sched_yield+0x3a>
		env_run(&envs[idx]);
		return;
	    }
	}
	//如果没有可运行的环境，但是以前在此CPU上运行的环境仍为ENV_RUNNING，则可以选择该环境。
	if (idle && idle->env_status == ENV_RUNNING) {
f0104438:	85 ff                	test   %edi,%edi
f010443a:	74 0f                	je     f010444b <sched_yield+0x73>
f010443c:	83 7f 54 03          	cmpl   $0x3,0x54(%edi)
f0104440:	75 09                	jne    f010444b <sched_yield+0x73>
	    env_run(idle);
f0104442:	83 ec 0c             	sub    $0xc,%esp
f0104445:	57                   	push   %edi
f0104446:	e8 91 f0 ff ff       	call   f01034dc <env_run>
	    return;
	}
	// sched_halt never returns
	sched_halt();
f010444b:	e8 b4 fe ff ff       	call   f0104304 <sched_halt>
}
f0104450:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104453:	5b                   	pop    %ebx
f0104454:	5e                   	pop    %esi
f0104455:	5f                   	pop    %edi
f0104456:	5d                   	pop    %ebp
f0104457:	c3                   	ret    

f0104458 <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f0104458:	55                   	push   %ebp
f0104459:	89 e5                	mov    %esp,%ebp
f010445b:	57                   	push   %edi
f010445c:	56                   	push   %esi
f010445d:	53                   	push   %ebx
f010445e:	83 ec 1c             	sub    $0x1c,%esp
f0104461:	8b 45 08             	mov    0x8(%ebp),%eax
	// Call the function corresponding to the 'syscallno' parameter.
	// Return any appropriate return value.
	// LAB 3: Your code here.

	int ret = 0;
	switch(syscallno){
f0104464:	83 f8 0c             	cmp    $0xc,%eax
f0104467:	0f 87 ec 05 00 00    	ja     f0104a59 <syscall+0x601>
f010446d:	ff 24 85 a0 79 10 f0 	jmp    *-0xfef8660(,%eax,4)
{
	// Check that the user has permission to read memory [s, s+len).
	// Destroy the environment if not.

	// LAB 3: Your code here.
	user_mem_assert(curenv, s, len, PTE_U);
f0104474:	e8 e1 17 00 00       	call   f0105c5a <cpunum>
f0104479:	6a 04                	push   $0x4
f010447b:	ff 75 10             	pushl  0x10(%ebp)
f010447e:	ff 75 0c             	pushl  0xc(%ebp)
f0104481:	6b c0 74             	imul   $0x74,%eax,%eax
f0104484:	ff b0 28 00 23 f0    	pushl  -0xfdcffd8(%eax)
f010448a:	e8 05 e9 ff ff       	call   f0102d94 <user_mem_assert>
	// Print the string supplied by the user.
	cprintf("%.*s", len, s);
f010448f:	83 c4 0c             	add    $0xc,%esp
f0104492:	ff 75 0c             	pushl  0xc(%ebp)
f0104495:	ff 75 10             	pushl  0x10(%ebp)
f0104498:	68 66 79 10 f0       	push   $0xf0107966
f010449d:	e8 ba f2 ff ff       	call   f010375c <cprintf>
f01044a2:	83 c4 10             	add    $0x10,%esp
{
	// Call the function corresponding to the 'syscallno' parameter.
	// Return any appropriate return value.
	// LAB 3: Your code here.

	int ret = 0;
f01044a5:	bb 00 00 00 00       	mov    $0x0,%ebx
f01044aa:	e9 b6 05 00 00       	jmp    f0104a65 <syscall+0x60d>
// Read a character from the system console without blocking.
// Returns the character, or 0 if there is no input waiting.
static int
sys_cgetc(void)
{
	return cons_getc();
f01044af:	e8 51 c1 ff ff       	call   f0100605 <cons_getc>
f01044b4:	89 c3                	mov    %eax,%ebx
	int ret = 0;
	switch(syscallno){
		case SYS_cputs: 		sys_cputs( (const char *)a1, (size_t) a2);
						break;
		case SYS_cgetc: 		ret = sys_cgetc();		
						break;
f01044b6:	e9 aa 05 00 00       	jmp    f0104a65 <syscall+0x60d>

// Returns the current environment's envid.
static envid_t
sys_getenvid(void)
{
	return curenv->env_id;
f01044bb:	e8 9a 17 00 00       	call   f0105c5a <cpunum>
f01044c0:	6b c0 74             	imul   $0x74,%eax,%eax
f01044c3:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f01044c9:	8b 58 48             	mov    0x48(%eax),%ebx
		case SYS_cputs: 		sys_cputs( (const char *)a1, (size_t) a2);
						break;
		case SYS_cgetc: 		ret = sys_cgetc();		
						break;
		case SYS_getenvid:	 ret =sys_getenvid();	
						break;
f01044cc:	e9 94 05 00 00       	jmp    f0104a65 <syscall+0x60d>
sys_env_destroy(envid_t envid)
{
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f01044d1:	83 ec 04             	sub    $0x4,%esp
f01044d4:	6a 01                	push   $0x1
f01044d6:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01044d9:	50                   	push   %eax
f01044da:	ff 75 0c             	pushl  0xc(%ebp)
f01044dd:	e8 93 e9 ff ff       	call   f0102e75 <envid2env>
f01044e2:	83 c4 10             	add    $0x10,%esp
		return r;
f01044e5:	89 c3                	mov    %eax,%ebx
sys_env_destroy(envid_t envid)
{
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f01044e7:	85 c0                	test   %eax,%eax
f01044e9:	0f 88 76 05 00 00    	js     f0104a65 <syscall+0x60d>
		return r;
	if (e == curenv)
f01044ef:	e8 66 17 00 00       	call   f0105c5a <cpunum>
f01044f4:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01044f7:	6b c0 74             	imul   $0x74,%eax,%eax
f01044fa:	39 90 28 00 23 f0    	cmp    %edx,-0xfdcffd8(%eax)
f0104500:	75 23                	jne    f0104525 <syscall+0xcd>
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
f0104502:	e8 53 17 00 00       	call   f0105c5a <cpunum>
f0104507:	83 ec 08             	sub    $0x8,%esp
f010450a:	6b c0 74             	imul   $0x74,%eax,%eax
f010450d:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f0104513:	ff 70 48             	pushl  0x48(%eax)
f0104516:	68 6b 79 10 f0       	push   $0xf010796b
f010451b:	e8 3c f2 ff ff       	call   f010375c <cprintf>
f0104520:	83 c4 10             	add    $0x10,%esp
f0104523:	eb 25                	jmp    f010454a <syscall+0xf2>
	else
		cprintf("[%08x] destroying %08x\n", curenv->env_id, e->env_id);
f0104525:	8b 5a 48             	mov    0x48(%edx),%ebx
f0104528:	e8 2d 17 00 00       	call   f0105c5a <cpunum>
f010452d:	83 ec 04             	sub    $0x4,%esp
f0104530:	53                   	push   %ebx
f0104531:	6b c0 74             	imul   $0x74,%eax,%eax
f0104534:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f010453a:	ff 70 48             	pushl  0x48(%eax)
f010453d:	68 86 79 10 f0       	push   $0xf0107986
f0104542:	e8 15 f2 ff ff       	call   f010375c <cprintf>
f0104547:	83 c4 10             	add    $0x10,%esp
	env_destroy(e);
f010454a:	83 ec 0c             	sub    $0xc,%esp
f010454d:	ff 75 e4             	pushl  -0x1c(%ebp)
f0104550:	e8 e8 ee ff ff       	call   f010343d <env_destroy>
f0104555:	83 c4 10             	add    $0x10,%esp
	return 0;
f0104558:	bb 00 00 00 00       	mov    $0x0,%ebx
f010455d:	e9 03 05 00 00       	jmp    f0104a65 <syscall+0x60d>

// Deschedule current environment and pick a different one to run.
static void
sys_yield(void)
{
	sched_yield();
f0104562:	e8 71 fe ff ff       	call   f01043d8 <sched_yield>
	// status is set to ENV_NOT_RUNNABLE, and the register set is copied
	// from the current environment -- but tweaked so sys_exofork
	// will appear to return 0.

	// LAB 4: Your code here.
	struct Env* childEnv=0;
f0104567:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	struct Env* parentEnv = curenv;
f010456e:	e8 e7 16 00 00       	call   f0105c5a <cpunum>
f0104573:	6b c0 74             	imul   $0x74,%eax,%eax
f0104576:	8b b0 28 00 23 f0    	mov    -0xfdcffd8(%eax),%esi
	int r = env_alloc(&childEnv, parentEnv->env_id);
f010457c:	83 ec 08             	sub    $0x8,%esp
f010457f:	ff 76 48             	pushl  0x48(%esi)
f0104582:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104585:	50                   	push   %eax
f0104586:	e8 f4 e9 ff ff       	call   f0102f7f <env_alloc>
	if(r < 0)
f010458b:	83 c4 10             	add    $0x10,%esp
f010458e:	85 c0                	test   %eax,%eax
f0104590:	78 23                	js     f01045b5 <syscall+0x15d>
		return r;
	//init the childEnv
	childEnv->env_tf = parentEnv->env_tf;
f0104592:	b9 11 00 00 00       	mov    $0x11,%ecx
f0104597:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010459a:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
	childEnv->env_status = ENV_NOT_RUNNABLE;
f010459c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010459f:	c7 40 54 04 00 00 00 	movl   $0x4,0x54(%eax)
	
	childEnv->env_tf.tf_regs.reg_eax = 0;
f01045a6:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)
	return childEnv->env_id;
f01045ad:	8b 58 48             	mov    0x48(%eax),%ebx
f01045b0:	e9 b0 04 00 00       	jmp    f0104a65 <syscall+0x60d>
	// LAB 4: Your code here.
	struct Env* childEnv=0;
	struct Env* parentEnv = curenv;
	int r = env_alloc(&childEnv, parentEnv->env_id);
	if(r < 0)
		return r;
f01045b5:	89 c3                	mov    %eax,%ebx
						break;
		case SYS_yield:      	sys_yield();	
						break;

		case SYS_exofork: 	ret = sys_exofork();
						break;
f01045b7:	e9 a9 04 00 00       	jmp    f0104a65 <syscall+0x60d>
	// You should set envid2env's third argument to 1, which will
	// check whether the current environment has permission to set
	// envid's status.

	// LAB 4: Your code here.
	struct Env *e =0;
f01045bc:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	int r =0;
	if((r = envid2env(envid, &e, 1)) < 0)
f01045c3:	83 ec 04             	sub    $0x4,%esp
f01045c6:	6a 01                	push   $0x1
f01045c8:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01045cb:	50                   	push   %eax
f01045cc:	ff 75 0c             	pushl  0xc(%ebp)
f01045cf:	e8 a1 e8 ff ff       	call   f0102e75 <envid2env>
f01045d4:	83 c4 10             	add    $0x10,%esp
f01045d7:	85 c0                	test   %eax,%eax
f01045d9:	78 20                	js     f01045fb <syscall+0x1a3>
		return r;

	if(status != ENV_RUNNABLE && status != ENV_NOT_RUNNABLE)
f01045db:	8b 45 10             	mov    0x10(%ebp),%eax
f01045de:	83 e8 02             	sub    $0x2,%eax
f01045e1:	a9 fd ff ff ff       	test   $0xfffffffd,%eax
f01045e6:	75 1a                	jne    f0104602 <syscall+0x1aa>
		return -E_INVAL;
	e->env_status = status;
f01045e8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01045eb:	8b 4d 10             	mov    0x10(%ebp),%ecx
f01045ee:	89 48 54             	mov    %ecx,0x54(%eax)
	return 0;
f01045f1:	bb 00 00 00 00       	mov    $0x0,%ebx
f01045f6:	e9 6a 04 00 00       	jmp    f0104a65 <syscall+0x60d>

	// LAB 4: Your code here.
	struct Env *e =0;
	int r =0;
	if((r = envid2env(envid, &e, 1)) < 0)
		return r;
f01045fb:	89 c3                	mov    %eax,%ebx
f01045fd:	e9 63 04 00 00       	jmp    f0104a65 <syscall+0x60d>

	if(status != ENV_RUNNABLE && status != ENV_NOT_RUNNABLE)
		return -E_INVAL;
f0104602:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
						break;

		case SYS_exofork: 	ret = sys_exofork();
						break;
		case SYS_env_set_status: ret = sys_env_set_status(a1, a2);
						break;
f0104607:	e9 59 04 00 00       	jmp    f0104a65 <syscall+0x60d>
	//   If page_insert() fails, remember to free the page you
	//   allocated!

	// LAB 4: Your code here.
	
	struct Env *e =0;
f010460c:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	int r =0;
	if((r = envid2env(envid, &e, 1)) < 0)
f0104613:	83 ec 04             	sub    $0x4,%esp
f0104616:	6a 01                	push   $0x1
f0104618:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010461b:	50                   	push   %eax
f010461c:	ff 75 0c             	pushl  0xc(%ebp)
f010461f:	e8 51 e8 ff ff       	call   f0102e75 <envid2env>
f0104624:	83 c4 10             	add    $0x10,%esp
f0104627:	85 c0                	test   %eax,%eax
f0104629:	78 6d                	js     f0104698 <syscall+0x240>
		return r;
	if( (int)va >= UTOP || ( (int)va % PGSIZE) != 0)
f010462b:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f0104632:	77 6b                	ja     f010469f <syscall+0x247>
f0104634:	f7 45 10 ff 0f 00 00 	testl  $0xfff,0x10(%ebp)
f010463b:	75 6c                	jne    f01046a9 <syscall+0x251>
		return  -E_INVAL;
	if(  (perm & (~PTE_SYSCALL) ) !=0 )
f010463d:	8b 5d 14             	mov    0x14(%ebp),%ebx
f0104640:	81 e3 f8 f1 ff ff    	and    $0xfffff1f8,%ebx
f0104646:	75 6b                	jne    f01046b3 <syscall+0x25b>
		return  -E_INVAL;
	if( (perm & PTE_U )== 0 || (perm& PTE_P) ==0)
f0104648:	8b 45 14             	mov    0x14(%ebp),%eax
f010464b:	83 e0 05             	and    $0x5,%eax
f010464e:	83 f8 05             	cmp    $0x5,%eax
f0104651:	75 6a                	jne    f01046bd <syscall+0x265>
		return  -E_INVAL;
	struct PageInfo * page = page_alloc(1);
f0104653:	83 ec 0c             	sub    $0xc,%esp
f0104656:	6a 01                	push   $0x1
f0104658:	e8 2a c8 ff ff       	call   f0100e87 <page_alloc>
f010465d:	89 c6                	mov    %eax,%esi
	if(page == 0)
f010465f:	83 c4 10             	add    $0x10,%esp
f0104662:	85 c0                	test   %eax,%eax
f0104664:	74 61                	je     f01046c7 <syscall+0x26f>
		return -E_NO_MEM ;
	r = page_insert(e->env_pgdir, page, va,perm);
f0104666:	ff 75 14             	pushl  0x14(%ebp)
f0104669:	ff 75 10             	pushl  0x10(%ebp)
f010466c:	50                   	push   %eax
f010466d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104670:	ff 70 60             	pushl  0x60(%eax)
f0104673:	e8 c4 ca ff ff       	call   f010113c <page_insert>
f0104678:	89 c7                	mov    %eax,%edi
	if(r <0){
f010467a:	83 c4 10             	add    $0x10,%esp
f010467d:	85 c0                	test   %eax,%eax
f010467f:	0f 89 e0 03 00 00    	jns    f0104a65 <syscall+0x60d>
		page_free(page);
f0104685:	83 ec 0c             	sub    $0xc,%esp
f0104688:	56                   	push   %esi
f0104689:	e8 69 c8 ff ff       	call   f0100ef7 <page_free>
f010468e:	83 c4 10             	add    $0x10,%esp
		return r;
f0104691:	89 fb                	mov    %edi,%ebx
f0104693:	e9 cd 03 00 00       	jmp    f0104a65 <syscall+0x60d>
	// LAB 4: Your code here.
	
	struct Env *e =0;
	int r =0;
	if((r = envid2env(envid, &e, 1)) < 0)
		return r;
f0104698:	89 c3                	mov    %eax,%ebx
f010469a:	e9 c6 03 00 00       	jmp    f0104a65 <syscall+0x60d>
	if( (int)va >= UTOP || ( (int)va % PGSIZE) != 0)
		return  -E_INVAL;
f010469f:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f01046a4:	e9 bc 03 00 00       	jmp    f0104a65 <syscall+0x60d>
f01046a9:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f01046ae:	e9 b2 03 00 00       	jmp    f0104a65 <syscall+0x60d>
	if(  (perm & (~PTE_SYSCALL) ) !=0 )
		return  -E_INVAL;
f01046b3:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f01046b8:	e9 a8 03 00 00       	jmp    f0104a65 <syscall+0x60d>
	if( (perm & PTE_U )== 0 || (perm& PTE_P) ==0)
		return  -E_INVAL;
f01046bd:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f01046c2:	e9 9e 03 00 00       	jmp    f0104a65 <syscall+0x60d>
	struct PageInfo * page = page_alloc(1);
	if(page == 0)
		return -E_NO_MEM ;
f01046c7:	bb fc ff ff ff       	mov    $0xfffffffc,%ebx
		case SYS_exofork: 	ret = sys_exofork();
						break;
		case SYS_env_set_status: ret = sys_env_set_status(a1, a2);
						break;
		case SYS_page_alloc: 	ret = sys_page_alloc(a1, (void*) a2, a3);
						break;
f01046cc:	e9 94 03 00 00       	jmp    f0104a65 <syscall+0x60d>
	//   parameters for correctness.
	//   Use the third argument to page_lookup() to
	//   check the current permissions on the page.

	// LAB 4: Your code here.
	struct Env *srcE=0, *destE = 0;
f01046d1:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
f01046d8:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
	int r =0;
	if((r = envid2env(srcenvid, &srcE, 1)) < 0)
f01046df:	83 ec 04             	sub    $0x4,%esp
f01046e2:	6a 01                	push   $0x1
f01046e4:	8d 45 dc             	lea    -0x24(%ebp),%eax
f01046e7:	50                   	push   %eax
f01046e8:	ff 75 0c             	pushl  0xc(%ebp)
f01046eb:	e8 85 e7 ff ff       	call   f0102e75 <envid2env>
f01046f0:	83 c4 10             	add    $0x10,%esp
		return r;
f01046f3:	89 c3                	mov    %eax,%ebx
	//   check the current permissions on the page.

	// LAB 4: Your code here.
	struct Env *srcE=0, *destE = 0;
	int r =0;
	if((r = envid2env(srcenvid, &srcE, 1)) < 0)
f01046f5:	85 c0                	test   %eax,%eax
f01046f7:	0f 88 68 03 00 00    	js     f0104a65 <syscall+0x60d>
		return r;
	if((r = envid2env(dstenvid, &destE, 1)) < 0)
f01046fd:	83 ec 04             	sub    $0x4,%esp
f0104700:	6a 01                	push   $0x1
f0104702:	8d 45 e0             	lea    -0x20(%ebp),%eax
f0104705:	50                   	push   %eax
f0104706:	ff 75 14             	pushl  0x14(%ebp)
f0104709:	e8 67 e7 ff ff       	call   f0102e75 <envid2env>
f010470e:	83 c4 10             	add    $0x10,%esp
f0104711:	85 c0                	test   %eax,%eax
f0104713:	0f 88 9d 00 00 00    	js     f01047b6 <syscall+0x35e>
		return r;
	if( (int)srcva >= UTOP || ( (int)srcva % PGSIZE) != 0)
f0104719:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f0104720:	0f 87 97 00 00 00    	ja     f01047bd <syscall+0x365>
		return  -E_INVAL;
	if( (int)dstva >= UTOP || ( (int)dstva % PGSIZE) != 0)
f0104726:	f7 45 10 ff 0f 00 00 	testl  $0xfff,0x10(%ebp)
f010472d:	0f 85 94 00 00 00    	jne    f01047c7 <syscall+0x36f>
f0104733:	81 7d 18 ff ff bf ee 	cmpl   $0xeebfffff,0x18(%ebp)
f010473a:	0f 87 87 00 00 00    	ja     f01047c7 <syscall+0x36f>
f0104740:	f7 45 18 ff 0f 00 00 	testl  $0xfff,0x18(%ebp)
f0104747:	0f 85 84 00 00 00    	jne    f01047d1 <syscall+0x379>
		return  -E_INVAL;
	pte_t * srcPTE=0;
f010474d:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	struct PageInfo *page = page_lookup(srcE->env_pgdir, srcva, &srcPTE);
f0104754:	83 ec 04             	sub    $0x4,%esp
f0104757:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010475a:	50                   	push   %eax
f010475b:	ff 75 10             	pushl  0x10(%ebp)
f010475e:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0104761:	ff 70 60             	pushl  0x60(%eax)
f0104764:	e8 e3 c8 ff ff       	call   f010104c <page_lookup>
	if(page == 0)
f0104769:	83 c4 10             	add    $0x10,%esp
f010476c:	85 c0                	test   %eax,%eax
f010476e:	74 6b                	je     f01047db <syscall+0x383>
		return -E_INVAL;
	if(  (perm & (~PTE_SYSCALL) ) !=0 )
f0104770:	f7 45 1c f8 f1 ff ff 	testl  $0xfffff1f8,0x1c(%ebp)
f0104777:	75 6c                	jne    f01047e5 <syscall+0x38d>
		return  -E_INVAL;
	if( (perm & PTE_U )== 0 || (perm& PTE_P) ==0)
f0104779:	8b 55 1c             	mov    0x1c(%ebp),%edx
f010477c:	83 e2 05             	and    $0x5,%edx
f010477f:	83 fa 05             	cmp    $0x5,%edx
f0104782:	75 6b                	jne    f01047ef <syscall+0x397>
		return  -E_INVAL;
	if ( (perm & PTE_W) && ( (*srcPTE & PTE_W )== 0) )
f0104784:	f6 45 1c 02          	testb  $0x2,0x1c(%ebp)
f0104788:	74 08                	je     f0104792 <syscall+0x33a>
f010478a:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f010478d:	f6 02 02             	testb  $0x2,(%edx)
f0104790:	74 67                	je     f01047f9 <syscall+0x3a1>
		return -E_INVAL;

	r = page_insert(destE->env_pgdir, page, dstva,perm);
f0104792:	ff 75 1c             	pushl  0x1c(%ebp)
f0104795:	ff 75 18             	pushl  0x18(%ebp)
f0104798:	50                   	push   %eax
f0104799:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010479c:	ff 70 60             	pushl  0x60(%eax)
f010479f:	e8 98 c9 ff ff       	call   f010113c <page_insert>
f01047a4:	83 c4 10             	add    $0x10,%esp
f01047a7:	85 c0                	test   %eax,%eax
f01047a9:	bb 00 00 00 00       	mov    $0x0,%ebx
f01047ae:	0f 4e d8             	cmovle %eax,%ebx
f01047b1:	e9 af 02 00 00       	jmp    f0104a65 <syscall+0x60d>
	struct Env *srcE=0, *destE = 0;
	int r =0;
	if((r = envid2env(srcenvid, &srcE, 1)) < 0)
		return r;
	if((r = envid2env(dstenvid, &destE, 1)) < 0)
		return r;
f01047b6:	89 c3                	mov    %eax,%ebx
f01047b8:	e9 a8 02 00 00       	jmp    f0104a65 <syscall+0x60d>
	if( (int)srcva >= UTOP || ( (int)srcva % PGSIZE) != 0)
		return  -E_INVAL;
f01047bd:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f01047c2:	e9 9e 02 00 00       	jmp    f0104a65 <syscall+0x60d>
	if( (int)dstva >= UTOP || ( (int)dstva % PGSIZE) != 0)
		return  -E_INVAL;
f01047c7:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f01047cc:	e9 94 02 00 00       	jmp    f0104a65 <syscall+0x60d>
f01047d1:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f01047d6:	e9 8a 02 00 00       	jmp    f0104a65 <syscall+0x60d>
	pte_t * srcPTE=0;
	struct PageInfo *page = page_lookup(srcE->env_pgdir, srcva, &srcPTE);
	if(page == 0)
		return -E_INVAL;
f01047db:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f01047e0:	e9 80 02 00 00       	jmp    f0104a65 <syscall+0x60d>
	if(  (perm & (~PTE_SYSCALL) ) !=0 )
		return  -E_INVAL;
f01047e5:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f01047ea:	e9 76 02 00 00       	jmp    f0104a65 <syscall+0x60d>
	if( (perm & PTE_U )== 0 || (perm& PTE_P) ==0)
		return  -E_INVAL;
f01047ef:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f01047f4:	e9 6c 02 00 00       	jmp    f0104a65 <syscall+0x60d>
	if ( (perm & PTE_W) && ( (*srcPTE & PTE_W )== 0) )
		return -E_INVAL;
f01047f9:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
		case SYS_env_set_status: ret = sys_env_set_status(a1, a2);
						break;
		case SYS_page_alloc: 	ret = sys_page_alloc(a1, (void*) a2, a3);
						break;
		case SYS_page_map:	ret = sys_page_map(a1,(void*)a2, a3, (void*)a4, a5);
						break;
f01047fe:	e9 62 02 00 00       	jmp    f0104a65 <syscall+0x60d>
sys_page_unmap(envid_t envid, void *va)
{
	// Hint: This function is a wrapper around page_remove().

	// LAB 4: Your code here.
	struct Env *e =0;
f0104803:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	int r =0;
	if((r = envid2env(envid, &e, 1)) < 0)
f010480a:	83 ec 04             	sub    $0x4,%esp
f010480d:	6a 01                	push   $0x1
f010480f:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104812:	50                   	push   %eax
f0104813:	ff 75 0c             	pushl  0xc(%ebp)
f0104816:	e8 5a e6 ff ff       	call   f0102e75 <envid2env>
f010481b:	83 c4 10             	add    $0x10,%esp
f010481e:	85 c0                	test   %eax,%eax
f0104820:	78 30                	js     f0104852 <syscall+0x3fa>
		return r;
	if( (int)va >= UTOP || ( (int)va % PGSIZE) != 0)
f0104822:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f0104829:	77 2e                	ja     f0104859 <syscall+0x401>
f010482b:	f7 45 10 ff 0f 00 00 	testl  $0xfff,0x10(%ebp)
f0104832:	75 2f                	jne    f0104863 <syscall+0x40b>
		return  -E_INVAL;
	page_remove(e->env_pgdir, va);
f0104834:	83 ec 08             	sub    $0x8,%esp
f0104837:	ff 75 10             	pushl  0x10(%ebp)
f010483a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010483d:	ff 70 60             	pushl  0x60(%eax)
f0104840:	e8 9e c8 ff ff       	call   f01010e3 <page_remove>
f0104845:	83 c4 10             	add    $0x10,%esp
	return 0;
f0104848:	bb 00 00 00 00       	mov    $0x0,%ebx
f010484d:	e9 13 02 00 00       	jmp    f0104a65 <syscall+0x60d>

	// LAB 4: Your code here.
	struct Env *e =0;
	int r =0;
	if((r = envid2env(envid, &e, 1)) < 0)
		return r;
f0104852:	89 c3                	mov    %eax,%ebx
f0104854:	e9 0c 02 00 00       	jmp    f0104a65 <syscall+0x60d>
	if( (int)va >= UTOP || ( (int)va % PGSIZE) != 0)
		return  -E_INVAL;
f0104859:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f010485e:	e9 02 02 00 00       	jmp    f0104a65 <syscall+0x60d>
f0104863:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
		case SYS_page_alloc: 	ret = sys_page_alloc(a1, (void*) a2, a3);
						break;
		case SYS_page_map:	ret = sys_page_map(a1,(void*)a2, a3, (void*)a4, a5);
						break;
		case SYS_page_unmap:	ret = sys_page_unmap(a1, (void*) a2);
						break;
f0104868:	e9 f8 01 00 00       	jmp    f0104a65 <syscall+0x60d>
static int
sys_env_set_pgfault_upcall(envid_t envid, void *func)
{

	// LAB 4: Your code here.
	struct Env *e =0;
f010486d:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	int r =0;
	if((r = envid2env(envid, &e, 1)) < 0)
f0104874:	83 ec 04             	sub    $0x4,%esp
f0104877:	6a 01                	push   $0x1
f0104879:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010487c:	50                   	push   %eax
f010487d:	ff 75 0c             	pushl  0xc(%ebp)
f0104880:	e8 f0 e5 ff ff       	call   f0102e75 <envid2env>
f0104885:	83 c4 10             	add    $0x10,%esp
f0104888:	85 c0                	test   %eax,%eax
f010488a:	78 13                	js     f010489f <syscall+0x447>
		return r;
	e->env_pgfault_upcall = func;
f010488c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010488f:	8b 7d 10             	mov    0x10(%ebp),%edi
f0104892:	89 78 64             	mov    %edi,0x64(%eax)
	return 0;
f0104895:	bb 00 00 00 00       	mov    $0x0,%ebx
f010489a:	e9 c6 01 00 00       	jmp    f0104a65 <syscall+0x60d>

	// LAB 4: Your code here.
	struct Env *e =0;
	int r =0;
	if((r = envid2env(envid, &e, 1)) < 0)
		return r;
f010489f:	89 c3                	mov    %eax,%ebx
						break;
		case SYS_page_unmap:	ret = sys_page_unmap(a1, (void*) a2);
						break;
		case SYS_env_set_pgfault_upcall:
					ret = sys_env_set_pgfault_upcall(a1, (void*)a2);
						break;
f01048a1:	e9 bf 01 00 00       	jmp    f0104a65 <syscall+0x60d>
	
	// LAB 4: Your code here.

	//if(envid == 0x1004)
	//	cprintf("when the envid =0x1004, the value is %d\n", value);
	struct Env *env=0;
f01048a6:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
	int r =0;
	pte_t * pte =0;
f01048ad:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	if((r = envid2env(envid, &env, 0)) < 0)
f01048b4:	83 ec 04             	sub    $0x4,%esp
f01048b7:	6a 00                	push   $0x0
f01048b9:	8d 45 e0             	lea    -0x20(%ebp),%eax
f01048bc:	50                   	push   %eax
f01048bd:	ff 75 0c             	pushl  0xc(%ebp)
f01048c0:	e8 b0 e5 ff ff       	call   f0102e75 <envid2env>
f01048c5:	83 c4 10             	add    $0x10,%esp
f01048c8:	85 c0                	test   %eax,%eax
f01048ca:	0f 88 e0 00 00 00    	js     f01049b0 <syscall+0x558>
		return -E_BAD_ENV;
	
	
	if(env->env_ipc_recving == 0)
f01048d0:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01048d3:	80 78 68 00          	cmpb   $0x0,0x68(%eax)
f01048d7:	0f 84 dd 00 00 00    	je     f01049ba <syscall+0x562>
		return -E_IPC_NOT_RECV;
	

	if((int)srcva < UTOP){
f01048dd:	81 7d 14 ff ff bf ee 	cmpl   $0xeebfffff,0x14(%ebp)
f01048e4:	0f 87 84 00 00 00    	ja     f010496e <syscall+0x516>

		if ( (int)srcva < UTOP &&  ((int)srcva % PGSIZE != 0) )
f01048ea:	f7 45 14 ff 0f 00 00 	testl  $0xfff,0x14(%ebp)
f01048f1:	0f 85 cd 00 00 00    	jne    f01049c4 <syscall+0x56c>
			return -E_INVAL;
			
		if(  (perm & (~PTE_SYSCALL) ) !=0 )
f01048f7:	f7 45 18 f8 f1 ff ff 	testl  $0xfffff1f8,0x18(%ebp)
f01048fe:	0f 85 ca 00 00 00    	jne    f01049ce <syscall+0x576>
			return  -E_INVAL;
			
		if(  (perm & PTE_P) ==0 )
f0104904:	f6 45 18 01          	testb  $0x1,0x18(%ebp)
f0104908:	0f 84 ca 00 00 00    	je     f01049d8 <syscall+0x580>
			return  -E_INVAL;
			
		struct PageInfo *page  = page_lookup(curenv->env_pgdir, srcva, &pte);
f010490e:	e8 47 13 00 00       	call   f0105c5a <cpunum>
f0104913:	83 ec 04             	sub    $0x4,%esp
f0104916:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0104919:	52                   	push   %edx
f010491a:	ff 75 14             	pushl  0x14(%ebp)
f010491d:	6b c0 74             	imul   $0x74,%eax,%eax
f0104920:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f0104926:	ff 70 60             	pushl  0x60(%eax)
f0104929:	e8 1e c7 ff ff       	call   f010104c <page_lookup>
		if( (perm & PTE_W) && ( (*pte & PTE_W) == 0) )
f010492e:	83 c4 10             	add    $0x10,%esp
f0104931:	f6 45 18 02          	testb  $0x2,0x18(%ebp)
f0104935:	74 0c                	je     f0104943 <syscall+0x4eb>
f0104937:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f010493a:	f6 02 02             	testb  $0x2,(%edx)
f010493d:	0f 84 9f 00 00 00    	je     f01049e2 <syscall+0x58a>
			return  -E_INVAL;
			
		if((int)env->env_ipc_dstva >= UTOP)
f0104943:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0104946:	8b 4a 6c             	mov    0x6c(%edx),%ecx
			return 0;
f0104949:	bb 00 00 00 00       	mov    $0x0,%ebx
			
		struct PageInfo *page  = page_lookup(curenv->env_pgdir, srcva, &pte);
		if( (perm & PTE_W) && ( (*pte & PTE_W) == 0) )
			return  -E_INVAL;
			
		if((int)env->env_ipc_dstva >= UTOP)
f010494e:	81 f9 ff ff bf ee    	cmp    $0xeebfffff,%ecx
f0104954:	0f 87 0b 01 00 00    	ja     f0104a65 <syscall+0x60d>
			return 0;
		r = page_insert(env->env_pgdir, page, env->env_ipc_dstva ,perm);
f010495a:	ff 75 18             	pushl  0x18(%ebp)
f010495d:	51                   	push   %ecx
f010495e:	50                   	push   %eax
f010495f:	ff 72 60             	pushl  0x60(%edx)
f0104962:	e8 d5 c7 ff ff       	call   f010113c <page_insert>
		if(r < 0)
f0104967:	83 c4 10             	add    $0x10,%esp
f010496a:	85 c0                	test   %eax,%eax
f010496c:	78 7b                	js     f01049e9 <syscall+0x591>
			return -E_NO_MEM;
			
		
	}

	env->env_ipc_value = value;
f010496e:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0104971:	8b 45 10             	mov    0x10(%ebp),%eax
f0104974:	89 43 70             	mov    %eax,0x70(%ebx)
	env->env_ipc_from = curenv->env_id;
f0104977:	e8 de 12 00 00       	call   f0105c5a <cpunum>
f010497c:	6b c0 74             	imul   $0x74,%eax,%eax
f010497f:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f0104985:	8b 40 48             	mov    0x48(%eax),%eax
f0104988:	89 43 74             	mov    %eax,0x74(%ebx)
	env->env_ipc_perm = perm;
f010498b:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010498e:	8b 7d 18             	mov    0x18(%ebp),%edi
f0104991:	89 78 78             	mov    %edi,0x78(%eax)
	env->env_ipc_recving = 0;
f0104994:	c6 40 68 00          	movb   $0x0,0x68(%eax)
	env->env_status = ENV_RUNNABLE;
f0104998:	c7 40 54 02 00 00 00 	movl   $0x2,0x54(%eax)
	env->env_tf.tf_regs.reg_eax = 0;
f010499f:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)

	return 0;
f01049a6:	bb 00 00 00 00       	mov    $0x0,%ebx
f01049ab:	e9 b5 00 00 00       	jmp    f0104a65 <syscall+0x60d>
	//	cprintf("when the envid =0x1004, the value is %d\n", value);
	struct Env *env=0;
	int r =0;
	pte_t * pte =0;
	if((r = envid2env(envid, &env, 0)) < 0)
		return -E_BAD_ENV;
f01049b0:	bb fe ff ff ff       	mov    $0xfffffffe,%ebx
f01049b5:	e9 ab 00 00 00       	jmp    f0104a65 <syscall+0x60d>
	
	
	if(env->env_ipc_recving == 0)
		return -E_IPC_NOT_RECV;
f01049ba:	bb f8 ff ff ff       	mov    $0xfffffff8,%ebx
f01049bf:	e9 a1 00 00 00       	jmp    f0104a65 <syscall+0x60d>
	

	if((int)srcva < UTOP){

		if ( (int)srcva < UTOP &&  ((int)srcva % PGSIZE != 0) )
			return -E_INVAL;
f01049c4:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f01049c9:	e9 97 00 00 00       	jmp    f0104a65 <syscall+0x60d>
			
		if(  (perm & (~PTE_SYSCALL) ) !=0 )
			return  -E_INVAL;
f01049ce:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f01049d3:	e9 8d 00 00 00       	jmp    f0104a65 <syscall+0x60d>
			
		if(  (perm & PTE_P) ==0 )
			return  -E_INVAL;
f01049d8:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f01049dd:	e9 83 00 00 00       	jmp    f0104a65 <syscall+0x60d>
			
		struct PageInfo *page  = page_lookup(curenv->env_pgdir, srcva, &pte);
		if( (perm & PTE_W) && ( (*pte & PTE_W) == 0) )
			return  -E_INVAL;
f01049e2:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f01049e7:	eb 7c                	jmp    f0104a65 <syscall+0x60d>
			
		if((int)env->env_ipc_dstva >= UTOP)
			return 0;
		r = page_insert(env->env_pgdir, page, env->env_ipc_dstva ,perm);
		if(r < 0)
			return -E_NO_MEM;
f01049e9:	bb fc ff ff ff       	mov    $0xfffffffc,%ebx
		case SYS_env_set_pgfault_upcall:
					ret = sys_env_set_pgfault_upcall(a1, (void*)a2);
						break;
		case SYS_ipc_try_send:
					ret = sys_ipc_try_send(a1, a2, (void*)a3, a4);
						break;
f01049ee:	eb 75                	jmp    f0104a65 <syscall+0x60d>
sys_ipc_recv(void *dstva)
{
	// LAB 4: Your code here.
	//panic("sys_ipc_recv not implemented");

	if((int)dstva >= UTOP)
f01049f0:	81 7d 0c ff ff bf ee 	cmpl   $0xeebfffff,0xc(%ebp)
f01049f7:	76 17                	jbe    f0104a10 <syscall+0x5b8>
		curenv->env_ipc_dstva = (void*)UTOP;
f01049f9:	e8 5c 12 00 00       	call   f0105c5a <cpunum>
f01049fe:	6b c0 74             	imul   $0x74,%eax,%eax
f0104a01:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f0104a07:	c7 40 6c 00 00 c0 ee 	movl   $0xeec00000,0x6c(%eax)
f0104a0e:	eb 1d                	jmp    f0104a2d <syscall+0x5d5>
	else{
		if((int)dstva % PGSIZE != 0)
f0104a10:	f7 45 0c ff 0f 00 00 	testl  $0xfff,0xc(%ebp)
f0104a17:	75 47                	jne    f0104a60 <syscall+0x608>
			return -E_INVAL;
		else curenv->env_ipc_dstva = dstva;
f0104a19:	e8 3c 12 00 00       	call   f0105c5a <cpunum>
f0104a1e:	6b c0 74             	imul   $0x74,%eax,%eax
f0104a21:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f0104a27:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0104a2a:	89 48 6c             	mov    %ecx,0x6c(%eax)
	}
	
	curenv->env_status = ENV_NOT_RUNNABLE;
f0104a2d:	e8 28 12 00 00       	call   f0105c5a <cpunum>
f0104a32:	6b c0 74             	imul   $0x74,%eax,%eax
f0104a35:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f0104a3b:	c7 40 54 04 00 00 00 	movl   $0x4,0x54(%eax)
	curenv->env_ipc_recving = 1;
f0104a42:	e8 13 12 00 00       	call   f0105c5a <cpunum>
f0104a47:	6b c0 74             	imul   $0x74,%eax,%eax
f0104a4a:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f0104a50:	c6 40 68 01          	movb   $0x1,0x68(%eax)

// Deschedule current environment and pick a different one to run.
static void
sys_yield(void)
{
	sched_yield();
f0104a54:	e8 7f f9 ff ff       	call   f01043d8 <sched_yield>
		case  SYS_ipc_recv:	
					ret = sys_ipc_recv ( (void *)a1);
						break;

		default:
			return -E_NO_SYS;
f0104a59:	bb f9 ff ff ff       	mov    $0xfffffff9,%ebx
f0104a5e:	eb 05                	jmp    f0104a65 <syscall+0x60d>
						break;
		case SYS_ipc_try_send:
					ret = sys_ipc_try_send(a1, a2, (void*)a3, a4);
						break;
		case  SYS_ipc_recv:	
					ret = sys_ipc_recv ( (void *)a1);
f0104a60:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx

		default:
			return -E_NO_SYS;
	}
	return ret;
}
f0104a65:	89 d8                	mov    %ebx,%eax
f0104a67:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104a6a:	5b                   	pop    %ebx
f0104a6b:	5e                   	pop    %esi
f0104a6c:	5f                   	pop    %edi
f0104a6d:	5d                   	pop    %ebp
f0104a6e:	c3                   	ret    

f0104a6f <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0104a6f:	55                   	push   %ebp
f0104a70:	89 e5                	mov    %esp,%ebp
f0104a72:	57                   	push   %edi
f0104a73:	56                   	push   %esi
f0104a74:	53                   	push   %ebx
f0104a75:	83 ec 14             	sub    $0x14,%esp
f0104a78:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104a7b:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0104a7e:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0104a81:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0104a84:	8b 1a                	mov    (%edx),%ebx
f0104a86:	8b 01                	mov    (%ecx),%eax
f0104a88:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0104a8b:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0104a92:	eb 7f                	jmp    f0104b13 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f0104a94:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0104a97:	01 d8                	add    %ebx,%eax
f0104a99:	89 c6                	mov    %eax,%esi
f0104a9b:	c1 ee 1f             	shr    $0x1f,%esi
f0104a9e:	01 c6                	add    %eax,%esi
f0104aa0:	d1 fe                	sar    %esi
f0104aa2:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0104aa5:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0104aa8:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0104aab:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0104aad:	eb 03                	jmp    f0104ab2 <stab_binsearch+0x43>
			m--;
f0104aaf:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0104ab2:	39 c3                	cmp    %eax,%ebx
f0104ab4:	7f 0d                	jg     f0104ac3 <stab_binsearch+0x54>
f0104ab6:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0104aba:	83 ea 0c             	sub    $0xc,%edx
f0104abd:	39 f9                	cmp    %edi,%ecx
f0104abf:	75 ee                	jne    f0104aaf <stab_binsearch+0x40>
f0104ac1:	eb 05                	jmp    f0104ac8 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0104ac3:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f0104ac6:	eb 4b                	jmp    f0104b13 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0104ac8:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104acb:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0104ace:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0104ad2:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0104ad5:	76 11                	jbe    f0104ae8 <stab_binsearch+0x79>
			*region_left = m;
f0104ad7:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0104ada:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0104adc:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0104adf:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0104ae6:	eb 2b                	jmp    f0104b13 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0104ae8:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0104aeb:	73 14                	jae    f0104b01 <stab_binsearch+0x92>
			*region_right = m - 1;
f0104aed:	83 e8 01             	sub    $0x1,%eax
f0104af0:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0104af3:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0104af6:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0104af8:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0104aff:	eb 12                	jmp    f0104b13 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0104b01:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0104b04:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0104b06:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0104b0a:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0104b0c:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0104b13:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0104b16:	0f 8e 78 ff ff ff    	jle    f0104a94 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0104b1c:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0104b20:	75 0f                	jne    f0104b31 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f0104b22:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104b25:	8b 00                	mov    (%eax),%eax
f0104b27:	83 e8 01             	sub    $0x1,%eax
f0104b2a:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0104b2d:	89 06                	mov    %eax,(%esi)
f0104b2f:	eb 2c                	jmp    f0104b5d <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104b31:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104b34:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0104b36:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0104b39:	8b 0e                	mov    (%esi),%ecx
f0104b3b:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104b3e:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0104b41:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104b44:	eb 03                	jmp    f0104b49 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0104b46:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104b49:	39 c8                	cmp    %ecx,%eax
f0104b4b:	7e 0b                	jle    f0104b58 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f0104b4d:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0104b51:	83 ea 0c             	sub    $0xc,%edx
f0104b54:	39 df                	cmp    %ebx,%edi
f0104b56:	75 ee                	jne    f0104b46 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f0104b58:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0104b5b:	89 06                	mov    %eax,(%esi)
	}
}
f0104b5d:	83 c4 14             	add    $0x14,%esp
f0104b60:	5b                   	pop    %ebx
f0104b61:	5e                   	pop    %esi
f0104b62:	5f                   	pop    %edi
f0104b63:	5d                   	pop    %ebp
f0104b64:	c3                   	ret    

f0104b65 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0104b65:	55                   	push   %ebp
f0104b66:	89 e5                	mov    %esp,%ebp
f0104b68:	57                   	push   %edi
f0104b69:	56                   	push   %esi
f0104b6a:	53                   	push   %ebx
f0104b6b:	83 ec 3c             	sub    $0x3c,%esp
f0104b6e:	8b 75 08             	mov    0x8(%ebp),%esi
f0104b71:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0104b74:	c7 03 d4 79 10 f0    	movl   $0xf01079d4,(%ebx)
	info->eip_line = 0;
f0104b7a:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0104b81:	c7 43 08 d4 79 10 f0 	movl   $0xf01079d4,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0104b88:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0104b8f:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0104b92:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)
	// return 0;
	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0104b99:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0104b9f:	0f 87 96 00 00 00    	ja     f0104c3b <debuginfo_eip+0xd6>
		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		// user_mem_check
		//
		if (user_mem_check(curenv, usd, sizeof(struct UserStabData), PTE_U))
f0104ba5:	e8 b0 10 00 00       	call   f0105c5a <cpunum>
f0104baa:	6a 04                	push   $0x4
f0104bac:	6a 10                	push   $0x10
f0104bae:	68 00 00 20 00       	push   $0x200000
f0104bb3:	6b c0 74             	imul   $0x74,%eax,%eax
f0104bb6:	ff b0 28 00 23 f0    	pushl  -0xfdcffd8(%eax)
f0104bbc:	e8 37 e1 ff ff       	call   f0102cf8 <user_mem_check>
f0104bc1:	83 c4 10             	add    $0x10,%esp
f0104bc4:	85 c0                	test   %eax,%eax
f0104bc6:	0f 85 28 02 00 00    	jne    f0104df4 <debuginfo_eip+0x28f>
			return -1;

		stabs = usd->stabs;
f0104bcc:	a1 00 00 20 00       	mov    0x200000,%eax
f0104bd1:	89 45 c0             	mov    %eax,-0x40(%ebp)
		stab_end = usd->stab_end;
f0104bd4:	8b 3d 04 00 20 00    	mov    0x200004,%edi
		stabstr = usd->stabstr;
f0104bda:	a1 08 00 20 00       	mov    0x200008,%eax
f0104bdf:	89 45 b8             	mov    %eax,-0x48(%ebp)
		stabstr_end = usd->stabstr_end;
f0104be2:	8b 15 0c 00 20 00    	mov    0x20000c,%edx
f0104be8:	89 55 bc             	mov    %edx,-0x44(%ebp)

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, stabs, sizeof(struct Stab), PTE_U))
f0104beb:	e8 6a 10 00 00       	call   f0105c5a <cpunum>
f0104bf0:	6a 04                	push   $0x4
f0104bf2:	6a 0c                	push   $0xc
f0104bf4:	ff 75 c0             	pushl  -0x40(%ebp)
f0104bf7:	6b c0 74             	imul   $0x74,%eax,%eax
f0104bfa:	ff b0 28 00 23 f0    	pushl  -0xfdcffd8(%eax)
f0104c00:	e8 f3 e0 ff ff       	call   f0102cf8 <user_mem_check>
f0104c05:	83 c4 10             	add    $0x10,%esp
f0104c08:	85 c0                	test   %eax,%eax
f0104c0a:	0f 85 eb 01 00 00    	jne    f0104dfb <debuginfo_eip+0x296>
			return -1;

		if (user_mem_check(curenv, stabstr, stabstr_end-stabstr, PTE_U))
f0104c10:	e8 45 10 00 00       	call   f0105c5a <cpunum>
f0104c15:	6a 04                	push   $0x4
f0104c17:	8b 55 bc             	mov    -0x44(%ebp),%edx
f0104c1a:	8b 4d b8             	mov    -0x48(%ebp),%ecx
f0104c1d:	29 ca                	sub    %ecx,%edx
f0104c1f:	52                   	push   %edx
f0104c20:	51                   	push   %ecx
f0104c21:	6b c0 74             	imul   $0x74,%eax,%eax
f0104c24:	ff b0 28 00 23 f0    	pushl  -0xfdcffd8(%eax)
f0104c2a:	e8 c9 e0 ff ff       	call   f0102cf8 <user_mem_check>
f0104c2f:	83 c4 10             	add    $0x10,%esp
f0104c32:	85 c0                	test   %eax,%eax
f0104c34:	74 1f                	je     f0104c55 <debuginfo_eip+0xf0>
f0104c36:	e9 c7 01 00 00       	jmp    f0104e02 <debuginfo_eip+0x29d>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f0104c3b:	c7 45 bc 8b 57 11 f0 	movl   $0xf011578b,-0x44(%ebp)
	// return 0;
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f0104c42:	c7 45 b8 25 21 11 f0 	movl   $0xf0112125,-0x48(%ebp)
	info->eip_fn_narg = 0;
	// return 0;
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f0104c49:	bf 24 21 11 f0       	mov    $0xf0112124,%edi
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;
	// return 0;
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f0104c4e:	c7 45 c0 b8 7e 10 f0 	movl   $0xf0107eb8,-0x40(%ebp)
		if (user_mem_check(curenv, stabstr, stabstr_end-stabstr, PTE_U))
			return -1;
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0104c55:	8b 45 bc             	mov    -0x44(%ebp),%eax
f0104c58:	39 45 b8             	cmp    %eax,-0x48(%ebp)
f0104c5b:	0f 83 a8 01 00 00    	jae    f0104e09 <debuginfo_eip+0x2a4>
f0104c61:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f0104c65:	0f 85 a5 01 00 00    	jne    f0104e10 <debuginfo_eip+0x2ab>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0104c6b:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0104c72:	2b 7d c0             	sub    -0x40(%ebp),%edi
f0104c75:	c1 ff 02             	sar    $0x2,%edi
f0104c78:	69 c7 ab aa aa aa    	imul   $0xaaaaaaab,%edi,%eax
f0104c7e:	83 e8 01             	sub    $0x1,%eax
f0104c81:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0104c84:	83 ec 08             	sub    $0x8,%esp
f0104c87:	56                   	push   %esi
f0104c88:	6a 64                	push   $0x64
f0104c8a:	8d 55 e0             	lea    -0x20(%ebp),%edx
f0104c8d:	89 d1                	mov    %edx,%ecx
f0104c8f:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0104c92:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0104c95:	89 f8                	mov    %edi,%eax
f0104c97:	e8 d3 fd ff ff       	call   f0104a6f <stab_binsearch>
	if (lfile == 0)
f0104c9c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104c9f:	83 c4 10             	add    $0x10,%esp
f0104ca2:	85 c0                	test   %eax,%eax
f0104ca4:	0f 84 6d 01 00 00    	je     f0104e17 <debuginfo_eip+0x2b2>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0104caa:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0104cad:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104cb0:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0104cb3:	83 ec 08             	sub    $0x8,%esp
f0104cb6:	56                   	push   %esi
f0104cb7:	6a 24                	push   $0x24
f0104cb9:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0104cbc:	89 d1                	mov    %edx,%ecx
f0104cbe:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0104cc1:	89 f8                	mov    %edi,%eax
f0104cc3:	e8 a7 fd ff ff       	call   f0104a6f <stab_binsearch>

	if (lfun <= rfun) {
f0104cc8:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0104ccb:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0104cce:	89 55 c4             	mov    %edx,-0x3c(%ebp)
f0104cd1:	83 c4 10             	add    $0x10,%esp
f0104cd4:	39 d0                	cmp    %edx,%eax
f0104cd6:	7f 2b                	jg     f0104d03 <debuginfo_eip+0x19e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0104cd8:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104cdb:	8d 0c 97             	lea    (%edi,%edx,4),%ecx
f0104cde:	8b 11                	mov    (%ecx),%edx
f0104ce0:	8b 7d bc             	mov    -0x44(%ebp),%edi
f0104ce3:	2b 7d b8             	sub    -0x48(%ebp),%edi
f0104ce6:	39 fa                	cmp    %edi,%edx
f0104ce8:	73 06                	jae    f0104cf0 <debuginfo_eip+0x18b>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0104cea:	03 55 b8             	add    -0x48(%ebp),%edx
f0104ced:	89 53 08             	mov    %edx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0104cf0:	8b 51 08             	mov    0x8(%ecx),%edx
f0104cf3:	89 53 10             	mov    %edx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0104cf6:	29 d6                	sub    %edx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0104cf8:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0104cfb:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0104cfe:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0104d01:	eb 0f                	jmp    f0104d12 <debuginfo_eip+0x1ad>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0104d03:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0104d06:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104d09:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0104d0c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104d0f:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0104d12:	83 ec 08             	sub    $0x8,%esp
f0104d15:	6a 3a                	push   $0x3a
f0104d17:	ff 73 08             	pushl  0x8(%ebx)
f0104d1a:	e8 fe 08 00 00       	call   f010561d <strfind>
f0104d1f:	2b 43 08             	sub    0x8(%ebx),%eax
f0104d22:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0104d25:	83 c4 08             	add    $0x8,%esp
f0104d28:	56                   	push   %esi
f0104d29:	6a 44                	push   $0x44
f0104d2b:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0104d2e:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0104d31:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0104d34:	89 f8                	mov    %edi,%eax
f0104d36:	e8 34 fd ff ff       	call   f0104a6f <stab_binsearch>
	info->eip_line = stabs[lline].n_desc;
f0104d3b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0104d3e:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104d41:	8d 14 97             	lea    (%edi,%edx,4),%edx
f0104d44:	0f b7 4a 06          	movzwl 0x6(%edx),%ecx
f0104d48:	89 4b 04             	mov    %ecx,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0104d4b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104d4e:	83 c4 10             	add    $0x10,%esp
f0104d51:	c6 45 c4 00          	movb   $0x0,-0x3c(%ebp)
f0104d55:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0104d58:	eb 0a                	jmp    f0104d64 <debuginfo_eip+0x1ff>
f0104d5a:	83 e8 01             	sub    $0x1,%eax
f0104d5d:	83 ea 0c             	sub    $0xc,%edx
f0104d60:	c6 45 c4 01          	movb   $0x1,-0x3c(%ebp)
f0104d64:	39 c7                	cmp    %eax,%edi
f0104d66:	7e 05                	jle    f0104d6d <debuginfo_eip+0x208>
f0104d68:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104d6b:	eb 47                	jmp    f0104db4 <debuginfo_eip+0x24f>
	       && stabs[lline].n_type != N_SOL
f0104d6d:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0104d71:	80 f9 84             	cmp    $0x84,%cl
f0104d74:	75 0e                	jne    f0104d84 <debuginfo_eip+0x21f>
f0104d76:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104d79:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f0104d7d:	74 1c                	je     f0104d9b <debuginfo_eip+0x236>
f0104d7f:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0104d82:	eb 17                	jmp    f0104d9b <debuginfo_eip+0x236>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0104d84:	80 f9 64             	cmp    $0x64,%cl
f0104d87:	75 d1                	jne    f0104d5a <debuginfo_eip+0x1f5>
f0104d89:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0104d8d:	74 cb                	je     f0104d5a <debuginfo_eip+0x1f5>
f0104d8f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104d92:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f0104d96:	74 03                	je     f0104d9b <debuginfo_eip+0x236>
f0104d98:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0104d9b:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0104d9e:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0104da1:	8b 14 87             	mov    (%edi,%eax,4),%edx
f0104da4:	8b 45 bc             	mov    -0x44(%ebp),%eax
f0104da7:	8b 75 b8             	mov    -0x48(%ebp),%esi
f0104daa:	29 f0                	sub    %esi,%eax
f0104dac:	39 c2                	cmp    %eax,%edx
f0104dae:	73 04                	jae    f0104db4 <debuginfo_eip+0x24f>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0104db0:	01 f2                	add    %esi,%edx
f0104db2:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0104db4:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0104db7:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0104dba:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0104dbf:	39 f2                	cmp    %esi,%edx
f0104dc1:	7d 60                	jge    f0104e23 <debuginfo_eip+0x2be>
		for (lline = lfun + 1;
f0104dc3:	83 c2 01             	add    $0x1,%edx
f0104dc6:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0104dc9:	89 d0                	mov    %edx,%eax
f0104dcb:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0104dce:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0104dd1:	8d 14 97             	lea    (%edi,%edx,4),%edx
f0104dd4:	eb 04                	jmp    f0104dda <debuginfo_eip+0x275>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0104dd6:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0104dda:	39 c6                	cmp    %eax,%esi
f0104ddc:	7e 40                	jle    f0104e1e <debuginfo_eip+0x2b9>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0104dde:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0104de2:	83 c0 01             	add    $0x1,%eax
f0104de5:	83 c2 0c             	add    $0xc,%edx
f0104de8:	80 f9 a0             	cmp    $0xa0,%cl
f0104deb:	74 e9                	je     f0104dd6 <debuginfo_eip+0x271>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0104ded:	b8 00 00 00 00       	mov    $0x0,%eax
f0104df2:	eb 2f                	jmp    f0104e23 <debuginfo_eip+0x2be>
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		// user_mem_check
		//
		if (user_mem_check(curenv, usd, sizeof(struct UserStabData), PTE_U))
			return -1;
f0104df4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104df9:	eb 28                	jmp    f0104e23 <debuginfo_eip+0x2be>
		stabstr_end = usd->stabstr_end;

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, stabs, sizeof(struct Stab), PTE_U))
			return -1;
f0104dfb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104e00:	eb 21                	jmp    f0104e23 <debuginfo_eip+0x2be>

		if (user_mem_check(curenv, stabstr, stabstr_end-stabstr, PTE_U))
			return -1;
f0104e02:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104e07:	eb 1a                	jmp    f0104e23 <debuginfo_eip+0x2be>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0104e09:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104e0e:	eb 13                	jmp    f0104e23 <debuginfo_eip+0x2be>
f0104e10:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104e15:	eb 0c                	jmp    f0104e23 <debuginfo_eip+0x2be>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0104e17:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104e1c:	eb 05                	jmp    f0104e23 <debuginfo_eip+0x2be>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0104e1e:	b8 00 00 00 00       	mov    $0x0,%eax
f0104e23:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104e26:	5b                   	pop    %ebx
f0104e27:	5e                   	pop    %esi
f0104e28:	5f                   	pop    %edi
f0104e29:	5d                   	pop    %ebp
f0104e2a:	c3                   	ret    

f0104e2b <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0104e2b:	55                   	push   %ebp
f0104e2c:	89 e5                	mov    %esp,%ebp
f0104e2e:	57                   	push   %edi
f0104e2f:	56                   	push   %esi
f0104e30:	53                   	push   %ebx
f0104e31:	83 ec 1c             	sub    $0x1c,%esp
f0104e34:	89 c7                	mov    %eax,%edi
f0104e36:	89 d6                	mov    %edx,%esi
f0104e38:	8b 45 08             	mov    0x8(%ebp),%eax
f0104e3b:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104e3e:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104e41:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0104e44:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0104e47:	bb 00 00 00 00       	mov    $0x0,%ebx
f0104e4c:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0104e4f:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0104e52:	39 d3                	cmp    %edx,%ebx
f0104e54:	72 05                	jb     f0104e5b <printnum+0x30>
f0104e56:	39 45 10             	cmp    %eax,0x10(%ebp)
f0104e59:	77 45                	ja     f0104ea0 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0104e5b:	83 ec 0c             	sub    $0xc,%esp
f0104e5e:	ff 75 18             	pushl  0x18(%ebp)
f0104e61:	8b 45 14             	mov    0x14(%ebp),%eax
f0104e64:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0104e67:	53                   	push   %ebx
f0104e68:	ff 75 10             	pushl  0x10(%ebp)
f0104e6b:	83 ec 08             	sub    $0x8,%esp
f0104e6e:	ff 75 e4             	pushl  -0x1c(%ebp)
f0104e71:	ff 75 e0             	pushl  -0x20(%ebp)
f0104e74:	ff 75 dc             	pushl  -0x24(%ebp)
f0104e77:	ff 75 d8             	pushl  -0x28(%ebp)
f0104e7a:	e8 e1 11 00 00       	call   f0106060 <__udivdi3>
f0104e7f:	83 c4 18             	add    $0x18,%esp
f0104e82:	52                   	push   %edx
f0104e83:	50                   	push   %eax
f0104e84:	89 f2                	mov    %esi,%edx
f0104e86:	89 f8                	mov    %edi,%eax
f0104e88:	e8 9e ff ff ff       	call   f0104e2b <printnum>
f0104e8d:	83 c4 20             	add    $0x20,%esp
f0104e90:	eb 18                	jmp    f0104eaa <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0104e92:	83 ec 08             	sub    $0x8,%esp
f0104e95:	56                   	push   %esi
f0104e96:	ff 75 18             	pushl  0x18(%ebp)
f0104e99:	ff d7                	call   *%edi
f0104e9b:	83 c4 10             	add    $0x10,%esp
f0104e9e:	eb 03                	jmp    f0104ea3 <printnum+0x78>
f0104ea0:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0104ea3:	83 eb 01             	sub    $0x1,%ebx
f0104ea6:	85 db                	test   %ebx,%ebx
f0104ea8:	7f e8                	jg     f0104e92 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0104eaa:	83 ec 08             	sub    $0x8,%esp
f0104ead:	56                   	push   %esi
f0104eae:	83 ec 04             	sub    $0x4,%esp
f0104eb1:	ff 75 e4             	pushl  -0x1c(%ebp)
f0104eb4:	ff 75 e0             	pushl  -0x20(%ebp)
f0104eb7:	ff 75 dc             	pushl  -0x24(%ebp)
f0104eba:	ff 75 d8             	pushl  -0x28(%ebp)
f0104ebd:	e8 ce 12 00 00       	call   f0106190 <__umoddi3>
f0104ec2:	83 c4 14             	add    $0x14,%esp
f0104ec5:	0f be 80 de 79 10 f0 	movsbl -0xfef8622(%eax),%eax
f0104ecc:	50                   	push   %eax
f0104ecd:	ff d7                	call   *%edi
}
f0104ecf:	83 c4 10             	add    $0x10,%esp
f0104ed2:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104ed5:	5b                   	pop    %ebx
f0104ed6:	5e                   	pop    %esi
f0104ed7:	5f                   	pop    %edi
f0104ed8:	5d                   	pop    %ebp
f0104ed9:	c3                   	ret    

f0104eda <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0104eda:	55                   	push   %ebp
f0104edb:	89 e5                	mov    %esp,%ebp
f0104edd:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0104ee0:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0104ee4:	8b 10                	mov    (%eax),%edx
f0104ee6:	3b 50 04             	cmp    0x4(%eax),%edx
f0104ee9:	73 0a                	jae    f0104ef5 <sprintputch+0x1b>
		*b->buf++ = ch;
f0104eeb:	8d 4a 01             	lea    0x1(%edx),%ecx
f0104eee:	89 08                	mov    %ecx,(%eax)
f0104ef0:	8b 45 08             	mov    0x8(%ebp),%eax
f0104ef3:	88 02                	mov    %al,(%edx)
}
f0104ef5:	5d                   	pop    %ebp
f0104ef6:	c3                   	ret    

f0104ef7 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0104ef7:	55                   	push   %ebp
f0104ef8:	89 e5                	mov    %esp,%ebp
f0104efa:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0104efd:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0104f00:	50                   	push   %eax
f0104f01:	ff 75 10             	pushl  0x10(%ebp)
f0104f04:	ff 75 0c             	pushl  0xc(%ebp)
f0104f07:	ff 75 08             	pushl  0x8(%ebp)
f0104f0a:	e8 05 00 00 00       	call   f0104f14 <vprintfmt>
	va_end(ap);
}
f0104f0f:	83 c4 10             	add    $0x10,%esp
f0104f12:	c9                   	leave  
f0104f13:	c3                   	ret    

f0104f14 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0104f14:	55                   	push   %ebp
f0104f15:	89 e5                	mov    %esp,%ebp
f0104f17:	57                   	push   %edi
f0104f18:	56                   	push   %esi
f0104f19:	53                   	push   %ebx
f0104f1a:	83 ec 2c             	sub    $0x2c,%esp
f0104f1d:	8b 75 08             	mov    0x8(%ebp),%esi
f0104f20:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104f23:	8b 7d 10             	mov    0x10(%ebp),%edi
f0104f26:	eb 12                	jmp    f0104f3a <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0104f28:	85 c0                	test   %eax,%eax
f0104f2a:	0f 84 42 04 00 00    	je     f0105372 <vprintfmt+0x45e>
				return;
			putch(ch, putdat);
f0104f30:	83 ec 08             	sub    $0x8,%esp
f0104f33:	53                   	push   %ebx
f0104f34:	50                   	push   %eax
f0104f35:	ff d6                	call   *%esi
f0104f37:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0104f3a:	83 c7 01             	add    $0x1,%edi
f0104f3d:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0104f41:	83 f8 25             	cmp    $0x25,%eax
f0104f44:	75 e2                	jne    f0104f28 <vprintfmt+0x14>
f0104f46:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0104f4a:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0104f51:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0104f58:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0104f5f:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104f64:	eb 07                	jmp    f0104f6d <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104f66:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0104f69:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104f6d:	8d 47 01             	lea    0x1(%edi),%eax
f0104f70:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0104f73:	0f b6 07             	movzbl (%edi),%eax
f0104f76:	0f b6 d0             	movzbl %al,%edx
f0104f79:	83 e8 23             	sub    $0x23,%eax
f0104f7c:	3c 55                	cmp    $0x55,%al
f0104f7e:	0f 87 d3 03 00 00    	ja     f0105357 <vprintfmt+0x443>
f0104f84:	0f b6 c0             	movzbl %al,%eax
f0104f87:	ff 24 85 a0 7a 10 f0 	jmp    *-0xfef8560(,%eax,4)
f0104f8e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0104f91:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0104f95:	eb d6                	jmp    f0104f6d <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104f97:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104f9a:	b8 00 00 00 00       	mov    $0x0,%eax
f0104f9f:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0104fa2:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0104fa5:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0104fa9:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0104fac:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0104faf:	83 f9 09             	cmp    $0x9,%ecx
f0104fb2:	77 3f                	ja     f0104ff3 <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0104fb4:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0104fb7:	eb e9                	jmp    f0104fa2 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0104fb9:	8b 45 14             	mov    0x14(%ebp),%eax
f0104fbc:	8b 00                	mov    (%eax),%eax
f0104fbe:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0104fc1:	8b 45 14             	mov    0x14(%ebp),%eax
f0104fc4:	8d 40 04             	lea    0x4(%eax),%eax
f0104fc7:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104fca:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0104fcd:	eb 2a                	jmp    f0104ff9 <vprintfmt+0xe5>
f0104fcf:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104fd2:	85 c0                	test   %eax,%eax
f0104fd4:	ba 00 00 00 00       	mov    $0x0,%edx
f0104fd9:	0f 49 d0             	cmovns %eax,%edx
f0104fdc:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104fdf:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104fe2:	eb 89                	jmp    f0104f6d <vprintfmt+0x59>
f0104fe4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0104fe7:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0104fee:	e9 7a ff ff ff       	jmp    f0104f6d <vprintfmt+0x59>
f0104ff3:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0104ff6:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0104ff9:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0104ffd:	0f 89 6a ff ff ff    	jns    f0104f6d <vprintfmt+0x59>
				width = precision, precision = -1;
f0105003:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0105006:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0105009:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0105010:	e9 58 ff ff ff       	jmp    f0104f6d <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0105015:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0105018:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f010501b:	e9 4d ff ff ff       	jmp    f0104f6d <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0105020:	8b 45 14             	mov    0x14(%ebp),%eax
f0105023:	8d 78 04             	lea    0x4(%eax),%edi
f0105026:	83 ec 08             	sub    $0x8,%esp
f0105029:	53                   	push   %ebx
f010502a:	ff 30                	pushl  (%eax)
f010502c:	ff d6                	call   *%esi
			break;
f010502e:	83 c4 10             	add    $0x10,%esp
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0105031:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0105034:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0105037:	e9 fe fe ff ff       	jmp    f0104f3a <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f010503c:	8b 45 14             	mov    0x14(%ebp),%eax
f010503f:	8d 78 04             	lea    0x4(%eax),%edi
f0105042:	8b 00                	mov    (%eax),%eax
f0105044:	99                   	cltd   
f0105045:	31 d0                	xor    %edx,%eax
f0105047:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0105049:	83 f8 09             	cmp    $0x9,%eax
f010504c:	7f 0b                	jg     f0105059 <vprintfmt+0x145>
f010504e:	8b 14 85 00 7c 10 f0 	mov    -0xfef8400(,%eax,4),%edx
f0105055:	85 d2                	test   %edx,%edx
f0105057:	75 1b                	jne    f0105074 <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
f0105059:	50                   	push   %eax
f010505a:	68 f6 79 10 f0       	push   $0xf01079f6
f010505f:	53                   	push   %ebx
f0105060:	56                   	push   %esi
f0105061:	e8 91 fe ff ff       	call   f0104ef7 <printfmt>
f0105066:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0105069:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010506c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f010506f:	e9 c6 fe ff ff       	jmp    f0104f3a <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0105074:	52                   	push   %edx
f0105075:	68 71 71 10 f0       	push   $0xf0107171
f010507a:	53                   	push   %ebx
f010507b:	56                   	push   %esi
f010507c:	e8 76 fe ff ff       	call   f0104ef7 <printfmt>
f0105081:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0105084:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0105087:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010508a:	e9 ab fe ff ff       	jmp    f0104f3a <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f010508f:	8b 45 14             	mov    0x14(%ebp),%eax
f0105092:	83 c0 04             	add    $0x4,%eax
f0105095:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0105098:	8b 45 14             	mov    0x14(%ebp),%eax
f010509b:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f010509d:	85 ff                	test   %edi,%edi
f010509f:	b8 ef 79 10 f0       	mov    $0xf01079ef,%eax
f01050a4:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f01050a7:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f01050ab:	0f 8e 94 00 00 00    	jle    f0105145 <vprintfmt+0x231>
f01050b1:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f01050b5:	0f 84 98 00 00 00    	je     f0105153 <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
f01050bb:	83 ec 08             	sub    $0x8,%esp
f01050be:	ff 75 d0             	pushl  -0x30(%ebp)
f01050c1:	57                   	push   %edi
f01050c2:	e8 0c 04 00 00       	call   f01054d3 <strnlen>
f01050c7:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f01050ca:	29 c1                	sub    %eax,%ecx
f01050cc:	89 4d c8             	mov    %ecx,-0x38(%ebp)
f01050cf:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f01050d2:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f01050d6:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01050d9:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f01050dc:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01050de:	eb 0f                	jmp    f01050ef <vprintfmt+0x1db>
					putch(padc, putdat);
f01050e0:	83 ec 08             	sub    $0x8,%esp
f01050e3:	53                   	push   %ebx
f01050e4:	ff 75 e0             	pushl  -0x20(%ebp)
f01050e7:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01050e9:	83 ef 01             	sub    $0x1,%edi
f01050ec:	83 c4 10             	add    $0x10,%esp
f01050ef:	85 ff                	test   %edi,%edi
f01050f1:	7f ed                	jg     f01050e0 <vprintfmt+0x1cc>
f01050f3:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01050f6:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f01050f9:	85 c9                	test   %ecx,%ecx
f01050fb:	b8 00 00 00 00       	mov    $0x0,%eax
f0105100:	0f 49 c1             	cmovns %ecx,%eax
f0105103:	29 c1                	sub    %eax,%ecx
f0105105:	89 75 08             	mov    %esi,0x8(%ebp)
f0105108:	8b 75 d0             	mov    -0x30(%ebp),%esi
f010510b:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f010510e:	89 cb                	mov    %ecx,%ebx
f0105110:	eb 4d                	jmp    f010515f <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0105112:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0105116:	74 1b                	je     f0105133 <vprintfmt+0x21f>
f0105118:	0f be c0             	movsbl %al,%eax
f010511b:	83 e8 20             	sub    $0x20,%eax
f010511e:	83 f8 5e             	cmp    $0x5e,%eax
f0105121:	76 10                	jbe    f0105133 <vprintfmt+0x21f>
					putch('?', putdat);
f0105123:	83 ec 08             	sub    $0x8,%esp
f0105126:	ff 75 0c             	pushl  0xc(%ebp)
f0105129:	6a 3f                	push   $0x3f
f010512b:	ff 55 08             	call   *0x8(%ebp)
f010512e:	83 c4 10             	add    $0x10,%esp
f0105131:	eb 0d                	jmp    f0105140 <vprintfmt+0x22c>
				else
					putch(ch, putdat);
f0105133:	83 ec 08             	sub    $0x8,%esp
f0105136:	ff 75 0c             	pushl  0xc(%ebp)
f0105139:	52                   	push   %edx
f010513a:	ff 55 08             	call   *0x8(%ebp)
f010513d:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0105140:	83 eb 01             	sub    $0x1,%ebx
f0105143:	eb 1a                	jmp    f010515f <vprintfmt+0x24b>
f0105145:	89 75 08             	mov    %esi,0x8(%ebp)
f0105148:	8b 75 d0             	mov    -0x30(%ebp),%esi
f010514b:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f010514e:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0105151:	eb 0c                	jmp    f010515f <vprintfmt+0x24b>
f0105153:	89 75 08             	mov    %esi,0x8(%ebp)
f0105156:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0105159:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f010515c:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f010515f:	83 c7 01             	add    $0x1,%edi
f0105162:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0105166:	0f be d0             	movsbl %al,%edx
f0105169:	85 d2                	test   %edx,%edx
f010516b:	74 23                	je     f0105190 <vprintfmt+0x27c>
f010516d:	85 f6                	test   %esi,%esi
f010516f:	78 a1                	js     f0105112 <vprintfmt+0x1fe>
f0105171:	83 ee 01             	sub    $0x1,%esi
f0105174:	79 9c                	jns    f0105112 <vprintfmt+0x1fe>
f0105176:	89 df                	mov    %ebx,%edi
f0105178:	8b 75 08             	mov    0x8(%ebp),%esi
f010517b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010517e:	eb 18                	jmp    f0105198 <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0105180:	83 ec 08             	sub    $0x8,%esp
f0105183:	53                   	push   %ebx
f0105184:	6a 20                	push   $0x20
f0105186:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0105188:	83 ef 01             	sub    $0x1,%edi
f010518b:	83 c4 10             	add    $0x10,%esp
f010518e:	eb 08                	jmp    f0105198 <vprintfmt+0x284>
f0105190:	89 df                	mov    %ebx,%edi
f0105192:	8b 75 08             	mov    0x8(%ebp),%esi
f0105195:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0105198:	85 ff                	test   %edi,%edi
f010519a:	7f e4                	jg     f0105180 <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f010519c:	8b 45 cc             	mov    -0x34(%ebp),%eax
f010519f:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01051a2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01051a5:	e9 90 fd ff ff       	jmp    f0104f3a <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f01051aa:	83 f9 01             	cmp    $0x1,%ecx
f01051ad:	7e 19                	jle    f01051c8 <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
f01051af:	8b 45 14             	mov    0x14(%ebp),%eax
f01051b2:	8b 50 04             	mov    0x4(%eax),%edx
f01051b5:	8b 00                	mov    (%eax),%eax
f01051b7:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01051ba:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01051bd:	8b 45 14             	mov    0x14(%ebp),%eax
f01051c0:	8d 40 08             	lea    0x8(%eax),%eax
f01051c3:	89 45 14             	mov    %eax,0x14(%ebp)
f01051c6:	eb 38                	jmp    f0105200 <vprintfmt+0x2ec>
	else if (lflag)
f01051c8:	85 c9                	test   %ecx,%ecx
f01051ca:	74 1b                	je     f01051e7 <vprintfmt+0x2d3>
		return va_arg(*ap, long);
f01051cc:	8b 45 14             	mov    0x14(%ebp),%eax
f01051cf:	8b 00                	mov    (%eax),%eax
f01051d1:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01051d4:	89 c1                	mov    %eax,%ecx
f01051d6:	c1 f9 1f             	sar    $0x1f,%ecx
f01051d9:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f01051dc:	8b 45 14             	mov    0x14(%ebp),%eax
f01051df:	8d 40 04             	lea    0x4(%eax),%eax
f01051e2:	89 45 14             	mov    %eax,0x14(%ebp)
f01051e5:	eb 19                	jmp    f0105200 <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
f01051e7:	8b 45 14             	mov    0x14(%ebp),%eax
f01051ea:	8b 00                	mov    (%eax),%eax
f01051ec:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01051ef:	89 c1                	mov    %eax,%ecx
f01051f1:	c1 f9 1f             	sar    $0x1f,%ecx
f01051f4:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f01051f7:	8b 45 14             	mov    0x14(%ebp),%eax
f01051fa:	8d 40 04             	lea    0x4(%eax),%eax
f01051fd:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0105200:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0105203:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0105206:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f010520b:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f010520f:	0f 89 0e 01 00 00    	jns    f0105323 <vprintfmt+0x40f>
				putch('-', putdat);
f0105215:	83 ec 08             	sub    $0x8,%esp
f0105218:	53                   	push   %ebx
f0105219:	6a 2d                	push   $0x2d
f010521b:	ff d6                	call   *%esi
				num = -(long long) num;
f010521d:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0105220:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0105223:	f7 da                	neg    %edx
f0105225:	83 d1 00             	adc    $0x0,%ecx
f0105228:	f7 d9                	neg    %ecx
f010522a:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f010522d:	b8 0a 00 00 00       	mov    $0xa,%eax
f0105232:	e9 ec 00 00 00       	jmp    f0105323 <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0105237:	83 f9 01             	cmp    $0x1,%ecx
f010523a:	7e 18                	jle    f0105254 <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
f010523c:	8b 45 14             	mov    0x14(%ebp),%eax
f010523f:	8b 10                	mov    (%eax),%edx
f0105241:	8b 48 04             	mov    0x4(%eax),%ecx
f0105244:	8d 40 08             	lea    0x8(%eax),%eax
f0105247:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f010524a:	b8 0a 00 00 00       	mov    $0xa,%eax
f010524f:	e9 cf 00 00 00       	jmp    f0105323 <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f0105254:	85 c9                	test   %ecx,%ecx
f0105256:	74 1a                	je     f0105272 <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
f0105258:	8b 45 14             	mov    0x14(%ebp),%eax
f010525b:	8b 10                	mov    (%eax),%edx
f010525d:	b9 00 00 00 00       	mov    $0x0,%ecx
f0105262:	8d 40 04             	lea    0x4(%eax),%eax
f0105265:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0105268:	b8 0a 00 00 00       	mov    $0xa,%eax
f010526d:	e9 b1 00 00 00       	jmp    f0105323 <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f0105272:	8b 45 14             	mov    0x14(%ebp),%eax
f0105275:	8b 10                	mov    (%eax),%edx
f0105277:	b9 00 00 00 00       	mov    $0x0,%ecx
f010527c:	8d 40 04             	lea    0x4(%eax),%eax
f010527f:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0105282:	b8 0a 00 00 00       	mov    $0xa,%eax
f0105287:	e9 97 00 00 00       	jmp    f0105323 <vprintfmt+0x40f>
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
f010528c:	83 ec 08             	sub    $0x8,%esp
f010528f:	53                   	push   %ebx
f0105290:	6a 58                	push   $0x58
f0105292:	ff d6                	call   *%esi
			putch('X', putdat);
f0105294:	83 c4 08             	add    $0x8,%esp
f0105297:	53                   	push   %ebx
f0105298:	6a 58                	push   $0x58
f010529a:	ff d6                	call   *%esi
			putch('X', putdat);
f010529c:	83 c4 08             	add    $0x8,%esp
f010529f:	53                   	push   %ebx
f01052a0:	6a 58                	push   $0x58
f01052a2:	ff d6                	call   *%esi
			break;
f01052a4:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01052a7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
f01052aa:	e9 8b fc ff ff       	jmp    f0104f3a <vprintfmt+0x26>

		// pointer
		case 'p':
			putch('0', putdat);
f01052af:	83 ec 08             	sub    $0x8,%esp
f01052b2:	53                   	push   %ebx
f01052b3:	6a 30                	push   $0x30
f01052b5:	ff d6                	call   *%esi
			putch('x', putdat);
f01052b7:	83 c4 08             	add    $0x8,%esp
f01052ba:	53                   	push   %ebx
f01052bb:	6a 78                	push   $0x78
f01052bd:	ff d6                	call   *%esi
			num = (unsigned long long)
f01052bf:	8b 45 14             	mov    0x14(%ebp),%eax
f01052c2:	8b 10                	mov    (%eax),%edx
f01052c4:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f01052c9:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f01052cc:	8d 40 04             	lea    0x4(%eax),%eax
f01052cf:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01052d2:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f01052d7:	eb 4a                	jmp    f0105323 <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f01052d9:	83 f9 01             	cmp    $0x1,%ecx
f01052dc:	7e 15                	jle    f01052f3 <vprintfmt+0x3df>
		return va_arg(*ap, unsigned long long);
f01052de:	8b 45 14             	mov    0x14(%ebp),%eax
f01052e1:	8b 10                	mov    (%eax),%edx
f01052e3:	8b 48 04             	mov    0x4(%eax),%ecx
f01052e6:	8d 40 08             	lea    0x8(%eax),%eax
f01052e9:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f01052ec:	b8 10 00 00 00       	mov    $0x10,%eax
f01052f1:	eb 30                	jmp    f0105323 <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f01052f3:	85 c9                	test   %ecx,%ecx
f01052f5:	74 17                	je     f010530e <vprintfmt+0x3fa>
		return va_arg(*ap, unsigned long);
f01052f7:	8b 45 14             	mov    0x14(%ebp),%eax
f01052fa:	8b 10                	mov    (%eax),%edx
f01052fc:	b9 00 00 00 00       	mov    $0x0,%ecx
f0105301:	8d 40 04             	lea    0x4(%eax),%eax
f0105304:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0105307:	b8 10 00 00 00       	mov    $0x10,%eax
f010530c:	eb 15                	jmp    f0105323 <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f010530e:	8b 45 14             	mov    0x14(%ebp),%eax
f0105311:	8b 10                	mov    (%eax),%edx
f0105313:	b9 00 00 00 00       	mov    $0x0,%ecx
f0105318:	8d 40 04             	lea    0x4(%eax),%eax
f010531b:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f010531e:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f0105323:	83 ec 0c             	sub    $0xc,%esp
f0105326:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f010532a:	57                   	push   %edi
f010532b:	ff 75 e0             	pushl  -0x20(%ebp)
f010532e:	50                   	push   %eax
f010532f:	51                   	push   %ecx
f0105330:	52                   	push   %edx
f0105331:	89 da                	mov    %ebx,%edx
f0105333:	89 f0                	mov    %esi,%eax
f0105335:	e8 f1 fa ff ff       	call   f0104e2b <printnum>
			break;
f010533a:	83 c4 20             	add    $0x20,%esp
f010533d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0105340:	e9 f5 fb ff ff       	jmp    f0104f3a <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0105345:	83 ec 08             	sub    $0x8,%esp
f0105348:	53                   	push   %ebx
f0105349:	52                   	push   %edx
f010534a:	ff d6                	call   *%esi
			break;
f010534c:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010534f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0105352:	e9 e3 fb ff ff       	jmp    f0104f3a <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0105357:	83 ec 08             	sub    $0x8,%esp
f010535a:	53                   	push   %ebx
f010535b:	6a 25                	push   $0x25
f010535d:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f010535f:	83 c4 10             	add    $0x10,%esp
f0105362:	eb 03                	jmp    f0105367 <vprintfmt+0x453>
f0105364:	83 ef 01             	sub    $0x1,%edi
f0105367:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f010536b:	75 f7                	jne    f0105364 <vprintfmt+0x450>
f010536d:	e9 c8 fb ff ff       	jmp    f0104f3a <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0105372:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0105375:	5b                   	pop    %ebx
f0105376:	5e                   	pop    %esi
f0105377:	5f                   	pop    %edi
f0105378:	5d                   	pop    %ebp
f0105379:	c3                   	ret    

f010537a <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f010537a:	55                   	push   %ebp
f010537b:	89 e5                	mov    %esp,%ebp
f010537d:	83 ec 18             	sub    $0x18,%esp
f0105380:	8b 45 08             	mov    0x8(%ebp),%eax
f0105383:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0105386:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0105389:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f010538d:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0105390:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0105397:	85 c0                	test   %eax,%eax
f0105399:	74 26                	je     f01053c1 <vsnprintf+0x47>
f010539b:	85 d2                	test   %edx,%edx
f010539d:	7e 22                	jle    f01053c1 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f010539f:	ff 75 14             	pushl  0x14(%ebp)
f01053a2:	ff 75 10             	pushl  0x10(%ebp)
f01053a5:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01053a8:	50                   	push   %eax
f01053a9:	68 da 4e 10 f0       	push   $0xf0104eda
f01053ae:	e8 61 fb ff ff       	call   f0104f14 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01053b3:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01053b6:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01053b9:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01053bc:	83 c4 10             	add    $0x10,%esp
f01053bf:	eb 05                	jmp    f01053c6 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f01053c1:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f01053c6:	c9                   	leave  
f01053c7:	c3                   	ret    

f01053c8 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01053c8:	55                   	push   %ebp
f01053c9:	89 e5                	mov    %esp,%ebp
f01053cb:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01053ce:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01053d1:	50                   	push   %eax
f01053d2:	ff 75 10             	pushl  0x10(%ebp)
f01053d5:	ff 75 0c             	pushl  0xc(%ebp)
f01053d8:	ff 75 08             	pushl  0x8(%ebp)
f01053db:	e8 9a ff ff ff       	call   f010537a <vsnprintf>
	va_end(ap);

	return rc;
}
f01053e0:	c9                   	leave  
f01053e1:	c3                   	ret    

f01053e2 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01053e2:	55                   	push   %ebp
f01053e3:	89 e5                	mov    %esp,%ebp
f01053e5:	57                   	push   %edi
f01053e6:	56                   	push   %esi
f01053e7:	53                   	push   %ebx
f01053e8:	83 ec 0c             	sub    $0xc,%esp
f01053eb:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01053ee:	85 c0                	test   %eax,%eax
f01053f0:	74 11                	je     f0105403 <readline+0x21>
		cprintf("%s", prompt);
f01053f2:	83 ec 08             	sub    $0x8,%esp
f01053f5:	50                   	push   %eax
f01053f6:	68 71 71 10 f0       	push   $0xf0107171
f01053fb:	e8 5c e3 ff ff       	call   f010375c <cprintf>
f0105400:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0105403:	83 ec 0c             	sub    $0xc,%esp
f0105406:	6a 00                	push   $0x0
f0105408:	e8 88 b3 ff ff       	call   f0100795 <iscons>
f010540d:	89 c7                	mov    %eax,%edi
f010540f:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0105412:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0105417:	e8 68 b3 ff ff       	call   f0100784 <getchar>
f010541c:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010541e:	85 c0                	test   %eax,%eax
f0105420:	79 18                	jns    f010543a <readline+0x58>
			cprintf("read error: %e\n", c);
f0105422:	83 ec 08             	sub    $0x8,%esp
f0105425:	50                   	push   %eax
f0105426:	68 28 7c 10 f0       	push   $0xf0107c28
f010542b:	e8 2c e3 ff ff       	call   f010375c <cprintf>
			return NULL;
f0105430:	83 c4 10             	add    $0x10,%esp
f0105433:	b8 00 00 00 00       	mov    $0x0,%eax
f0105438:	eb 79                	jmp    f01054b3 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f010543a:	83 f8 08             	cmp    $0x8,%eax
f010543d:	0f 94 c2             	sete   %dl
f0105440:	83 f8 7f             	cmp    $0x7f,%eax
f0105443:	0f 94 c0             	sete   %al
f0105446:	08 c2                	or     %al,%dl
f0105448:	74 1a                	je     f0105464 <readline+0x82>
f010544a:	85 f6                	test   %esi,%esi
f010544c:	7e 16                	jle    f0105464 <readline+0x82>
			if (echoing)
f010544e:	85 ff                	test   %edi,%edi
f0105450:	74 0d                	je     f010545f <readline+0x7d>
				cputchar('\b');
f0105452:	83 ec 0c             	sub    $0xc,%esp
f0105455:	6a 08                	push   $0x8
f0105457:	e8 18 b3 ff ff       	call   f0100774 <cputchar>
f010545c:	83 c4 10             	add    $0x10,%esp
			i--;
f010545f:	83 ee 01             	sub    $0x1,%esi
f0105462:	eb b3                	jmp    f0105417 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0105464:	83 fb 1f             	cmp    $0x1f,%ebx
f0105467:	7e 23                	jle    f010548c <readline+0xaa>
f0105469:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010546f:	7f 1b                	jg     f010548c <readline+0xaa>
			if (echoing)
f0105471:	85 ff                	test   %edi,%edi
f0105473:	74 0c                	je     f0105481 <readline+0x9f>
				cputchar(c);
f0105475:	83 ec 0c             	sub    $0xc,%esp
f0105478:	53                   	push   %ebx
f0105479:	e8 f6 b2 ff ff       	call   f0100774 <cputchar>
f010547e:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0105481:	88 9e 80 fa 22 f0    	mov    %bl,-0xfdd0580(%esi)
f0105487:	8d 76 01             	lea    0x1(%esi),%esi
f010548a:	eb 8b                	jmp    f0105417 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f010548c:	83 fb 0a             	cmp    $0xa,%ebx
f010548f:	74 05                	je     f0105496 <readline+0xb4>
f0105491:	83 fb 0d             	cmp    $0xd,%ebx
f0105494:	75 81                	jne    f0105417 <readline+0x35>
			if (echoing)
f0105496:	85 ff                	test   %edi,%edi
f0105498:	74 0d                	je     f01054a7 <readline+0xc5>
				cputchar('\n');
f010549a:	83 ec 0c             	sub    $0xc,%esp
f010549d:	6a 0a                	push   $0xa
f010549f:	e8 d0 b2 ff ff       	call   f0100774 <cputchar>
f01054a4:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f01054a7:	c6 86 80 fa 22 f0 00 	movb   $0x0,-0xfdd0580(%esi)
			return buf;
f01054ae:	b8 80 fa 22 f0       	mov    $0xf022fa80,%eax
		}
	}
}
f01054b3:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01054b6:	5b                   	pop    %ebx
f01054b7:	5e                   	pop    %esi
f01054b8:	5f                   	pop    %edi
f01054b9:	5d                   	pop    %ebp
f01054ba:	c3                   	ret    

f01054bb <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01054bb:	55                   	push   %ebp
f01054bc:	89 e5                	mov    %esp,%ebp
f01054be:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01054c1:	b8 00 00 00 00       	mov    $0x0,%eax
f01054c6:	eb 03                	jmp    f01054cb <strlen+0x10>
		n++;
f01054c8:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01054cb:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01054cf:	75 f7                	jne    f01054c8 <strlen+0xd>
		n++;
	return n;
}
f01054d1:	5d                   	pop    %ebp
f01054d2:	c3                   	ret    

f01054d3 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01054d3:	55                   	push   %ebp
f01054d4:	89 e5                	mov    %esp,%ebp
f01054d6:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01054d9:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01054dc:	ba 00 00 00 00       	mov    $0x0,%edx
f01054e1:	eb 03                	jmp    f01054e6 <strnlen+0x13>
		n++;
f01054e3:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01054e6:	39 c2                	cmp    %eax,%edx
f01054e8:	74 08                	je     f01054f2 <strnlen+0x1f>
f01054ea:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f01054ee:	75 f3                	jne    f01054e3 <strnlen+0x10>
f01054f0:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f01054f2:	5d                   	pop    %ebp
f01054f3:	c3                   	ret    

f01054f4 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01054f4:	55                   	push   %ebp
f01054f5:	89 e5                	mov    %esp,%ebp
f01054f7:	53                   	push   %ebx
f01054f8:	8b 45 08             	mov    0x8(%ebp),%eax
f01054fb:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01054fe:	89 c2                	mov    %eax,%edx
f0105500:	83 c2 01             	add    $0x1,%edx
f0105503:	83 c1 01             	add    $0x1,%ecx
f0105506:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f010550a:	88 5a ff             	mov    %bl,-0x1(%edx)
f010550d:	84 db                	test   %bl,%bl
f010550f:	75 ef                	jne    f0105500 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0105511:	5b                   	pop    %ebx
f0105512:	5d                   	pop    %ebp
f0105513:	c3                   	ret    

f0105514 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0105514:	55                   	push   %ebp
f0105515:	89 e5                	mov    %esp,%ebp
f0105517:	53                   	push   %ebx
f0105518:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f010551b:	53                   	push   %ebx
f010551c:	e8 9a ff ff ff       	call   f01054bb <strlen>
f0105521:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0105524:	ff 75 0c             	pushl  0xc(%ebp)
f0105527:	01 d8                	add    %ebx,%eax
f0105529:	50                   	push   %eax
f010552a:	e8 c5 ff ff ff       	call   f01054f4 <strcpy>
	return dst;
}
f010552f:	89 d8                	mov    %ebx,%eax
f0105531:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0105534:	c9                   	leave  
f0105535:	c3                   	ret    

f0105536 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0105536:	55                   	push   %ebp
f0105537:	89 e5                	mov    %esp,%ebp
f0105539:	56                   	push   %esi
f010553a:	53                   	push   %ebx
f010553b:	8b 75 08             	mov    0x8(%ebp),%esi
f010553e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0105541:	89 f3                	mov    %esi,%ebx
f0105543:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0105546:	89 f2                	mov    %esi,%edx
f0105548:	eb 0f                	jmp    f0105559 <strncpy+0x23>
		*dst++ = *src;
f010554a:	83 c2 01             	add    $0x1,%edx
f010554d:	0f b6 01             	movzbl (%ecx),%eax
f0105550:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0105553:	80 39 01             	cmpb   $0x1,(%ecx)
f0105556:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0105559:	39 da                	cmp    %ebx,%edx
f010555b:	75 ed                	jne    f010554a <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f010555d:	89 f0                	mov    %esi,%eax
f010555f:	5b                   	pop    %ebx
f0105560:	5e                   	pop    %esi
f0105561:	5d                   	pop    %ebp
f0105562:	c3                   	ret    

f0105563 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0105563:	55                   	push   %ebp
f0105564:	89 e5                	mov    %esp,%ebp
f0105566:	56                   	push   %esi
f0105567:	53                   	push   %ebx
f0105568:	8b 75 08             	mov    0x8(%ebp),%esi
f010556b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010556e:	8b 55 10             	mov    0x10(%ebp),%edx
f0105571:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0105573:	85 d2                	test   %edx,%edx
f0105575:	74 21                	je     f0105598 <strlcpy+0x35>
f0105577:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f010557b:	89 f2                	mov    %esi,%edx
f010557d:	eb 09                	jmp    f0105588 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f010557f:	83 c2 01             	add    $0x1,%edx
f0105582:	83 c1 01             	add    $0x1,%ecx
f0105585:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0105588:	39 c2                	cmp    %eax,%edx
f010558a:	74 09                	je     f0105595 <strlcpy+0x32>
f010558c:	0f b6 19             	movzbl (%ecx),%ebx
f010558f:	84 db                	test   %bl,%bl
f0105591:	75 ec                	jne    f010557f <strlcpy+0x1c>
f0105593:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f0105595:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0105598:	29 f0                	sub    %esi,%eax
}
f010559a:	5b                   	pop    %ebx
f010559b:	5e                   	pop    %esi
f010559c:	5d                   	pop    %ebp
f010559d:	c3                   	ret    

f010559e <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010559e:	55                   	push   %ebp
f010559f:	89 e5                	mov    %esp,%ebp
f01055a1:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01055a4:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01055a7:	eb 06                	jmp    f01055af <strcmp+0x11>
		p++, q++;
f01055a9:	83 c1 01             	add    $0x1,%ecx
f01055ac:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01055af:	0f b6 01             	movzbl (%ecx),%eax
f01055b2:	84 c0                	test   %al,%al
f01055b4:	74 04                	je     f01055ba <strcmp+0x1c>
f01055b6:	3a 02                	cmp    (%edx),%al
f01055b8:	74 ef                	je     f01055a9 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01055ba:	0f b6 c0             	movzbl %al,%eax
f01055bd:	0f b6 12             	movzbl (%edx),%edx
f01055c0:	29 d0                	sub    %edx,%eax
}
f01055c2:	5d                   	pop    %ebp
f01055c3:	c3                   	ret    

f01055c4 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01055c4:	55                   	push   %ebp
f01055c5:	89 e5                	mov    %esp,%ebp
f01055c7:	53                   	push   %ebx
f01055c8:	8b 45 08             	mov    0x8(%ebp),%eax
f01055cb:	8b 55 0c             	mov    0xc(%ebp),%edx
f01055ce:	89 c3                	mov    %eax,%ebx
f01055d0:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01055d3:	eb 06                	jmp    f01055db <strncmp+0x17>
		n--, p++, q++;
f01055d5:	83 c0 01             	add    $0x1,%eax
f01055d8:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01055db:	39 d8                	cmp    %ebx,%eax
f01055dd:	74 15                	je     f01055f4 <strncmp+0x30>
f01055df:	0f b6 08             	movzbl (%eax),%ecx
f01055e2:	84 c9                	test   %cl,%cl
f01055e4:	74 04                	je     f01055ea <strncmp+0x26>
f01055e6:	3a 0a                	cmp    (%edx),%cl
f01055e8:	74 eb                	je     f01055d5 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01055ea:	0f b6 00             	movzbl (%eax),%eax
f01055ed:	0f b6 12             	movzbl (%edx),%edx
f01055f0:	29 d0                	sub    %edx,%eax
f01055f2:	eb 05                	jmp    f01055f9 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f01055f4:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01055f9:	5b                   	pop    %ebx
f01055fa:	5d                   	pop    %ebp
f01055fb:	c3                   	ret    

f01055fc <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01055fc:	55                   	push   %ebp
f01055fd:	89 e5                	mov    %esp,%ebp
f01055ff:	8b 45 08             	mov    0x8(%ebp),%eax
f0105602:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0105606:	eb 07                	jmp    f010560f <strchr+0x13>
		if (*s == c)
f0105608:	38 ca                	cmp    %cl,%dl
f010560a:	74 0f                	je     f010561b <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f010560c:	83 c0 01             	add    $0x1,%eax
f010560f:	0f b6 10             	movzbl (%eax),%edx
f0105612:	84 d2                	test   %dl,%dl
f0105614:	75 f2                	jne    f0105608 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0105616:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010561b:	5d                   	pop    %ebp
f010561c:	c3                   	ret    

f010561d <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010561d:	55                   	push   %ebp
f010561e:	89 e5                	mov    %esp,%ebp
f0105620:	8b 45 08             	mov    0x8(%ebp),%eax
f0105623:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0105627:	eb 03                	jmp    f010562c <strfind+0xf>
f0105629:	83 c0 01             	add    $0x1,%eax
f010562c:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f010562f:	38 ca                	cmp    %cl,%dl
f0105631:	74 04                	je     f0105637 <strfind+0x1a>
f0105633:	84 d2                	test   %dl,%dl
f0105635:	75 f2                	jne    f0105629 <strfind+0xc>
			break;
	return (char *) s;
}
f0105637:	5d                   	pop    %ebp
f0105638:	c3                   	ret    

f0105639 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0105639:	55                   	push   %ebp
f010563a:	89 e5                	mov    %esp,%ebp
f010563c:	57                   	push   %edi
f010563d:	56                   	push   %esi
f010563e:	53                   	push   %ebx
f010563f:	8b 7d 08             	mov    0x8(%ebp),%edi
f0105642:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0105645:	85 c9                	test   %ecx,%ecx
f0105647:	74 36                	je     f010567f <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0105649:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010564f:	75 28                	jne    f0105679 <memset+0x40>
f0105651:	f6 c1 03             	test   $0x3,%cl
f0105654:	75 23                	jne    f0105679 <memset+0x40>
		c &= 0xFF;
f0105656:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f010565a:	89 d3                	mov    %edx,%ebx
f010565c:	c1 e3 08             	shl    $0x8,%ebx
f010565f:	89 d6                	mov    %edx,%esi
f0105661:	c1 e6 18             	shl    $0x18,%esi
f0105664:	89 d0                	mov    %edx,%eax
f0105666:	c1 e0 10             	shl    $0x10,%eax
f0105669:	09 f0                	or     %esi,%eax
f010566b:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f010566d:	89 d8                	mov    %ebx,%eax
f010566f:	09 d0                	or     %edx,%eax
f0105671:	c1 e9 02             	shr    $0x2,%ecx
f0105674:	fc                   	cld    
f0105675:	f3 ab                	rep stos %eax,%es:(%edi)
f0105677:	eb 06                	jmp    f010567f <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0105679:	8b 45 0c             	mov    0xc(%ebp),%eax
f010567c:	fc                   	cld    
f010567d:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f010567f:	89 f8                	mov    %edi,%eax
f0105681:	5b                   	pop    %ebx
f0105682:	5e                   	pop    %esi
f0105683:	5f                   	pop    %edi
f0105684:	5d                   	pop    %ebp
f0105685:	c3                   	ret    

f0105686 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0105686:	55                   	push   %ebp
f0105687:	89 e5                	mov    %esp,%ebp
f0105689:	57                   	push   %edi
f010568a:	56                   	push   %esi
f010568b:	8b 45 08             	mov    0x8(%ebp),%eax
f010568e:	8b 75 0c             	mov    0xc(%ebp),%esi
f0105691:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0105694:	39 c6                	cmp    %eax,%esi
f0105696:	73 35                	jae    f01056cd <memmove+0x47>
f0105698:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f010569b:	39 d0                	cmp    %edx,%eax
f010569d:	73 2e                	jae    f01056cd <memmove+0x47>
		s += n;
		d += n;
f010569f:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01056a2:	89 d6                	mov    %edx,%esi
f01056a4:	09 fe                	or     %edi,%esi
f01056a6:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01056ac:	75 13                	jne    f01056c1 <memmove+0x3b>
f01056ae:	f6 c1 03             	test   $0x3,%cl
f01056b1:	75 0e                	jne    f01056c1 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f01056b3:	83 ef 04             	sub    $0x4,%edi
f01056b6:	8d 72 fc             	lea    -0x4(%edx),%esi
f01056b9:	c1 e9 02             	shr    $0x2,%ecx
f01056bc:	fd                   	std    
f01056bd:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01056bf:	eb 09                	jmp    f01056ca <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01056c1:	83 ef 01             	sub    $0x1,%edi
f01056c4:	8d 72 ff             	lea    -0x1(%edx),%esi
f01056c7:	fd                   	std    
f01056c8:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01056ca:	fc                   	cld    
f01056cb:	eb 1d                	jmp    f01056ea <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01056cd:	89 f2                	mov    %esi,%edx
f01056cf:	09 c2                	or     %eax,%edx
f01056d1:	f6 c2 03             	test   $0x3,%dl
f01056d4:	75 0f                	jne    f01056e5 <memmove+0x5f>
f01056d6:	f6 c1 03             	test   $0x3,%cl
f01056d9:	75 0a                	jne    f01056e5 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f01056db:	c1 e9 02             	shr    $0x2,%ecx
f01056de:	89 c7                	mov    %eax,%edi
f01056e0:	fc                   	cld    
f01056e1:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01056e3:	eb 05                	jmp    f01056ea <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01056e5:	89 c7                	mov    %eax,%edi
f01056e7:	fc                   	cld    
f01056e8:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01056ea:	5e                   	pop    %esi
f01056eb:	5f                   	pop    %edi
f01056ec:	5d                   	pop    %ebp
f01056ed:	c3                   	ret    

f01056ee <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01056ee:	55                   	push   %ebp
f01056ef:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f01056f1:	ff 75 10             	pushl  0x10(%ebp)
f01056f4:	ff 75 0c             	pushl  0xc(%ebp)
f01056f7:	ff 75 08             	pushl  0x8(%ebp)
f01056fa:	e8 87 ff ff ff       	call   f0105686 <memmove>
}
f01056ff:	c9                   	leave  
f0105700:	c3                   	ret    

f0105701 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0105701:	55                   	push   %ebp
f0105702:	89 e5                	mov    %esp,%ebp
f0105704:	56                   	push   %esi
f0105705:	53                   	push   %ebx
f0105706:	8b 45 08             	mov    0x8(%ebp),%eax
f0105709:	8b 55 0c             	mov    0xc(%ebp),%edx
f010570c:	89 c6                	mov    %eax,%esi
f010570e:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0105711:	eb 1a                	jmp    f010572d <memcmp+0x2c>
		if (*s1 != *s2)
f0105713:	0f b6 08             	movzbl (%eax),%ecx
f0105716:	0f b6 1a             	movzbl (%edx),%ebx
f0105719:	38 d9                	cmp    %bl,%cl
f010571b:	74 0a                	je     f0105727 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f010571d:	0f b6 c1             	movzbl %cl,%eax
f0105720:	0f b6 db             	movzbl %bl,%ebx
f0105723:	29 d8                	sub    %ebx,%eax
f0105725:	eb 0f                	jmp    f0105736 <memcmp+0x35>
		s1++, s2++;
f0105727:	83 c0 01             	add    $0x1,%eax
f010572a:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010572d:	39 f0                	cmp    %esi,%eax
f010572f:	75 e2                	jne    f0105713 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0105731:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105736:	5b                   	pop    %ebx
f0105737:	5e                   	pop    %esi
f0105738:	5d                   	pop    %ebp
f0105739:	c3                   	ret    

f010573a <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f010573a:	55                   	push   %ebp
f010573b:	89 e5                	mov    %esp,%ebp
f010573d:	53                   	push   %ebx
f010573e:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0105741:	89 c1                	mov    %eax,%ecx
f0105743:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f0105746:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010574a:	eb 0a                	jmp    f0105756 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f010574c:	0f b6 10             	movzbl (%eax),%edx
f010574f:	39 da                	cmp    %ebx,%edx
f0105751:	74 07                	je     f010575a <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0105753:	83 c0 01             	add    $0x1,%eax
f0105756:	39 c8                	cmp    %ecx,%eax
f0105758:	72 f2                	jb     f010574c <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f010575a:	5b                   	pop    %ebx
f010575b:	5d                   	pop    %ebp
f010575c:	c3                   	ret    

f010575d <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f010575d:	55                   	push   %ebp
f010575e:	89 e5                	mov    %esp,%ebp
f0105760:	57                   	push   %edi
f0105761:	56                   	push   %esi
f0105762:	53                   	push   %ebx
f0105763:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0105766:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0105769:	eb 03                	jmp    f010576e <strtol+0x11>
		s++;
f010576b:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010576e:	0f b6 01             	movzbl (%ecx),%eax
f0105771:	3c 20                	cmp    $0x20,%al
f0105773:	74 f6                	je     f010576b <strtol+0xe>
f0105775:	3c 09                	cmp    $0x9,%al
f0105777:	74 f2                	je     f010576b <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0105779:	3c 2b                	cmp    $0x2b,%al
f010577b:	75 0a                	jne    f0105787 <strtol+0x2a>
		s++;
f010577d:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0105780:	bf 00 00 00 00       	mov    $0x0,%edi
f0105785:	eb 11                	jmp    f0105798 <strtol+0x3b>
f0105787:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f010578c:	3c 2d                	cmp    $0x2d,%al
f010578e:	75 08                	jne    f0105798 <strtol+0x3b>
		s++, neg = 1;
f0105790:	83 c1 01             	add    $0x1,%ecx
f0105793:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0105798:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f010579e:	75 15                	jne    f01057b5 <strtol+0x58>
f01057a0:	80 39 30             	cmpb   $0x30,(%ecx)
f01057a3:	75 10                	jne    f01057b5 <strtol+0x58>
f01057a5:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f01057a9:	75 7c                	jne    f0105827 <strtol+0xca>
		s += 2, base = 16;
f01057ab:	83 c1 02             	add    $0x2,%ecx
f01057ae:	bb 10 00 00 00       	mov    $0x10,%ebx
f01057b3:	eb 16                	jmp    f01057cb <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f01057b5:	85 db                	test   %ebx,%ebx
f01057b7:	75 12                	jne    f01057cb <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01057b9:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01057be:	80 39 30             	cmpb   $0x30,(%ecx)
f01057c1:	75 08                	jne    f01057cb <strtol+0x6e>
		s++, base = 8;
f01057c3:	83 c1 01             	add    $0x1,%ecx
f01057c6:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f01057cb:	b8 00 00 00 00       	mov    $0x0,%eax
f01057d0:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01057d3:	0f b6 11             	movzbl (%ecx),%edx
f01057d6:	8d 72 d0             	lea    -0x30(%edx),%esi
f01057d9:	89 f3                	mov    %esi,%ebx
f01057db:	80 fb 09             	cmp    $0x9,%bl
f01057de:	77 08                	ja     f01057e8 <strtol+0x8b>
			dig = *s - '0';
f01057e0:	0f be d2             	movsbl %dl,%edx
f01057e3:	83 ea 30             	sub    $0x30,%edx
f01057e6:	eb 22                	jmp    f010580a <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f01057e8:	8d 72 9f             	lea    -0x61(%edx),%esi
f01057eb:	89 f3                	mov    %esi,%ebx
f01057ed:	80 fb 19             	cmp    $0x19,%bl
f01057f0:	77 08                	ja     f01057fa <strtol+0x9d>
			dig = *s - 'a' + 10;
f01057f2:	0f be d2             	movsbl %dl,%edx
f01057f5:	83 ea 57             	sub    $0x57,%edx
f01057f8:	eb 10                	jmp    f010580a <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f01057fa:	8d 72 bf             	lea    -0x41(%edx),%esi
f01057fd:	89 f3                	mov    %esi,%ebx
f01057ff:	80 fb 19             	cmp    $0x19,%bl
f0105802:	77 16                	ja     f010581a <strtol+0xbd>
			dig = *s - 'A' + 10;
f0105804:	0f be d2             	movsbl %dl,%edx
f0105807:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f010580a:	3b 55 10             	cmp    0x10(%ebp),%edx
f010580d:	7d 0b                	jge    f010581a <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f010580f:	83 c1 01             	add    $0x1,%ecx
f0105812:	0f af 45 10          	imul   0x10(%ebp),%eax
f0105816:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0105818:	eb b9                	jmp    f01057d3 <strtol+0x76>

	if (endptr)
f010581a:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f010581e:	74 0d                	je     f010582d <strtol+0xd0>
		*endptr = (char *) s;
f0105820:	8b 75 0c             	mov    0xc(%ebp),%esi
f0105823:	89 0e                	mov    %ecx,(%esi)
f0105825:	eb 06                	jmp    f010582d <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0105827:	85 db                	test   %ebx,%ebx
f0105829:	74 98                	je     f01057c3 <strtol+0x66>
f010582b:	eb 9e                	jmp    f01057cb <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f010582d:	89 c2                	mov    %eax,%edx
f010582f:	f7 da                	neg    %edx
f0105831:	85 ff                	test   %edi,%edi
f0105833:	0f 45 c2             	cmovne %edx,%eax
}
f0105836:	5b                   	pop    %ebx
f0105837:	5e                   	pop    %esi
f0105838:	5f                   	pop    %edi
f0105839:	5d                   	pop    %ebp
f010583a:	c3                   	ret    
f010583b:	90                   	nop

f010583c <mpentry_start>:
.set PROT_MODE_DSEG, 0x10	# kernel data segment selector

.code16           
.globl mpentry_start
mpentry_start:
	cli            
f010583c:	fa                   	cli    

	xorw    %ax, %ax
f010583d:	31 c0                	xor    %eax,%eax
	movw    %ax, %ds
f010583f:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f0105841:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f0105843:	8e d0                	mov    %eax,%ss

	lgdt    MPBOOTPHYS(gdtdesc)
f0105845:	0f 01 16             	lgdtl  (%esi)
f0105848:	74 70                	je     f01058ba <mpsearch1+0x3>
	movl    %cr0, %eax
f010584a:	0f 20 c0             	mov    %cr0,%eax
	orl     $CR0_PE, %eax
f010584d:	66 83 c8 01          	or     $0x1,%ax
	movl    %eax, %cr0
f0105851:	0f 22 c0             	mov    %eax,%cr0

	ljmpl   $(PROT_MODE_CSEG), $(MPBOOTPHYS(start32))
f0105854:	66 ea 20 70 00 00    	ljmpw  $0x0,$0x7020
f010585a:	08 00                	or     %al,(%eax)

f010585c <start32>:

.code32
start32:
	movw    $(PROT_MODE_DSEG), %ax
f010585c:	66 b8 10 00          	mov    $0x10,%ax
	movw    %ax, %ds
f0105860:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f0105862:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f0105864:	8e d0                	mov    %eax,%ss
	movw    $0, %ax
f0105866:	66 b8 00 00          	mov    $0x0,%ax
	movw    %ax, %fs
f010586a:	8e e0                	mov    %eax,%fs
	movw    %ax, %gs
f010586c:	8e e8                	mov    %eax,%gs

	# Set up initial page table. We cannot use kern_pgdir yet because
	# we are still running at a low EIP.
	movl    $(RELOC(entry_pgdir)), %eax
f010586e:	b8 00 e0 11 00       	mov    $0x11e000,%eax
	movl    %eax, %cr3
f0105873:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl    %cr0, %eax
f0105876:	0f 20 c0             	mov    %cr0,%eax
	orl     $(CR0_PE|CR0_PG|CR0_WP), %eax
f0105879:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl    %eax, %cr0
f010587e:	0f 22 c0             	mov    %eax,%cr0

	# Switch to the per-cpu stack allocated in boot_aps()
	movl    mpentry_kstack, %esp
f0105881:	8b 25 84 fe 22 f0    	mov    0xf022fe84,%esp
	movl    $0x0, %ebp       # nuke frame pointer
f0105887:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Call mp_main().  (Exercise for the reader: why the indirect call?)
	movl    $mp_main, %eax
f010588c:	b8 d1 01 10 f0       	mov    $0xf01001d1,%eax
	call    *%eax
f0105891:	ff d0                	call   *%eax

f0105893 <spin>:

	# If mp_main returns (it shouldn't), loop.
spin:
	jmp     spin
f0105893:	eb fe                	jmp    f0105893 <spin>
f0105895:	8d 76 00             	lea    0x0(%esi),%esi

f0105898 <gdt>:
	...
f01058a0:	ff                   	(bad)  
f01058a1:	ff 00                	incl   (%eax)
f01058a3:	00 00                	add    %al,(%eax)
f01058a5:	9a cf 00 ff ff 00 00 	lcall  $0x0,$0xffff00cf
f01058ac:	00                   	.byte 0x0
f01058ad:	92                   	xchg   %eax,%edx
f01058ae:	cf                   	iret   
	...

f01058b0 <gdtdesc>:
f01058b0:	17                   	pop    %ss
f01058b1:	00 5c 70 00          	add    %bl,0x0(%eax,%esi,2)
	...

f01058b6 <mpentry_end>:
	.word   0x17				# sizeof(gdt) - 1
	.long   MPBOOTPHYS(gdt)			# address gdt

.globl mpentry_end
mpentry_end:
	nop
f01058b6:	90                   	nop

f01058b7 <mpsearch1>:
}

// Look for an MP structure in the len bytes at physical address addr.
static struct mp *
mpsearch1(physaddr_t a, int len)
{
f01058b7:	55                   	push   %ebp
f01058b8:	89 e5                	mov    %esp,%ebp
f01058ba:	57                   	push   %edi
f01058bb:	56                   	push   %esi
f01058bc:	53                   	push   %ebx
f01058bd:	83 ec 0c             	sub    $0xc,%esp
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01058c0:	8b 0d 88 fe 22 f0    	mov    0xf022fe88,%ecx
f01058c6:	89 c3                	mov    %eax,%ebx
f01058c8:	c1 eb 0c             	shr    $0xc,%ebx
f01058cb:	39 cb                	cmp    %ecx,%ebx
f01058cd:	72 12                	jb     f01058e1 <mpsearch1+0x2a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01058cf:	50                   	push   %eax
f01058d0:	68 24 63 10 f0       	push   $0xf0106324
f01058d5:	6a 57                	push   $0x57
f01058d7:	68 c5 7d 10 f0       	push   $0xf0107dc5
f01058dc:	e8 5f a7 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f01058e1:	8d 98 00 00 00 f0    	lea    -0x10000000(%eax),%ebx
	struct mp *mp = KADDR(a), *end = KADDR(a + len);
f01058e7:	01 d0                	add    %edx,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01058e9:	89 c2                	mov    %eax,%edx
f01058eb:	c1 ea 0c             	shr    $0xc,%edx
f01058ee:	39 ca                	cmp    %ecx,%edx
f01058f0:	72 12                	jb     f0105904 <mpsearch1+0x4d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01058f2:	50                   	push   %eax
f01058f3:	68 24 63 10 f0       	push   $0xf0106324
f01058f8:	6a 57                	push   $0x57
f01058fa:	68 c5 7d 10 f0       	push   $0xf0107dc5
f01058ff:	e8 3c a7 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0105904:	8d b0 00 00 00 f0    	lea    -0x10000000(%eax),%esi

	for (; mp < end; mp++)
f010590a:	eb 2f                	jmp    f010593b <mpsearch1+0x84>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f010590c:	83 ec 04             	sub    $0x4,%esp
f010590f:	6a 04                	push   $0x4
f0105911:	68 d5 7d 10 f0       	push   $0xf0107dd5
f0105916:	53                   	push   %ebx
f0105917:	e8 e5 fd ff ff       	call   f0105701 <memcmp>
f010591c:	83 c4 10             	add    $0x10,%esp
f010591f:	85 c0                	test   %eax,%eax
f0105921:	75 15                	jne    f0105938 <mpsearch1+0x81>
f0105923:	89 da                	mov    %ebx,%edx
f0105925:	8d 7b 10             	lea    0x10(%ebx),%edi
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
		sum += ((uint8_t *)addr)[i];
f0105928:	0f b6 0a             	movzbl (%edx),%ecx
f010592b:	01 c8                	add    %ecx,%eax
f010592d:	83 c2 01             	add    $0x1,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f0105930:	39 d7                	cmp    %edx,%edi
f0105932:	75 f4                	jne    f0105928 <mpsearch1+0x71>
mpsearch1(physaddr_t a, int len)
{
	struct mp *mp = KADDR(a), *end = KADDR(a + len);

	for (; mp < end; mp++)
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f0105934:	84 c0                	test   %al,%al
f0105936:	74 0e                	je     f0105946 <mpsearch1+0x8f>
static struct mp *
mpsearch1(physaddr_t a, int len)
{
	struct mp *mp = KADDR(a), *end = KADDR(a + len);

	for (; mp < end; mp++)
f0105938:	83 c3 10             	add    $0x10,%ebx
f010593b:	39 f3                	cmp    %esi,%ebx
f010593d:	72 cd                	jb     f010590c <mpsearch1+0x55>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
		    sum(mp, sizeof(*mp)) == 0)
			return mp;
	return NULL;
f010593f:	b8 00 00 00 00       	mov    $0x0,%eax
f0105944:	eb 02                	jmp    f0105948 <mpsearch1+0x91>
f0105946:	89 d8                	mov    %ebx,%eax
}
f0105948:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010594b:	5b                   	pop    %ebx
f010594c:	5e                   	pop    %esi
f010594d:	5f                   	pop    %edi
f010594e:	5d                   	pop    %ebp
f010594f:	c3                   	ret    

f0105950 <mp_init>:
	return conf;
}

void
mp_init(void)
{
f0105950:	55                   	push   %ebp
f0105951:	89 e5                	mov    %esp,%ebp
f0105953:	57                   	push   %edi
f0105954:	56                   	push   %esi
f0105955:	53                   	push   %ebx
f0105956:	83 ec 1c             	sub    $0x1c,%esp
	struct mpconf *conf;
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
f0105959:	c7 05 c0 03 23 f0 20 	movl   $0xf0230020,0xf02303c0
f0105960:	00 23 f0 
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0105963:	83 3d 88 fe 22 f0 00 	cmpl   $0x0,0xf022fe88
f010596a:	75 16                	jne    f0105982 <mp_init+0x32>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010596c:	68 00 04 00 00       	push   $0x400
f0105971:	68 24 63 10 f0       	push   $0xf0106324
f0105976:	6a 6f                	push   $0x6f
f0105978:	68 c5 7d 10 f0       	push   $0xf0107dc5
f010597d:	e8 be a6 ff ff       	call   f0100040 <_panic>
	// The BIOS data area lives in 16-bit segment 0x40.
	bda = (uint8_t *) KADDR(0x40 << 4);

	// [MP 4] The 16-bit segment of the EBDA is in the two bytes
	// starting at byte 0x0E of the BDA.  0 if not present.
	if ((p = *(uint16_t *) (bda + 0x0E))) {
f0105982:	0f b7 05 0e 04 00 f0 	movzwl 0xf000040e,%eax
f0105989:	85 c0                	test   %eax,%eax
f010598b:	74 16                	je     f01059a3 <mp_init+0x53>
		p <<= 4;	// Translate from segment to PA
		if ((mp = mpsearch1(p, 1024)))
f010598d:	c1 e0 04             	shl    $0x4,%eax
f0105990:	ba 00 04 00 00       	mov    $0x400,%edx
f0105995:	e8 1d ff ff ff       	call   f01058b7 <mpsearch1>
f010599a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010599d:	85 c0                	test   %eax,%eax
f010599f:	75 3c                	jne    f01059dd <mp_init+0x8d>
f01059a1:	eb 20                	jmp    f01059c3 <mp_init+0x73>
			return mp;
	} else {
		// The size of base memory, in KB is in the two bytes
		// starting at 0x13 of the BDA.
		p = *(uint16_t *) (bda + 0x13) * 1024;
		if ((mp = mpsearch1(p - 1024, 1024)))
f01059a3:	0f b7 05 13 04 00 f0 	movzwl 0xf0000413,%eax
f01059aa:	c1 e0 0a             	shl    $0xa,%eax
f01059ad:	2d 00 04 00 00       	sub    $0x400,%eax
f01059b2:	ba 00 04 00 00       	mov    $0x400,%edx
f01059b7:	e8 fb fe ff ff       	call   f01058b7 <mpsearch1>
f01059bc:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01059bf:	85 c0                	test   %eax,%eax
f01059c1:	75 1a                	jne    f01059dd <mp_init+0x8d>
			return mp;
	}
	return mpsearch1(0xF0000, 0x10000);
f01059c3:	ba 00 00 01 00       	mov    $0x10000,%edx
f01059c8:	b8 00 00 0f 00       	mov    $0xf0000,%eax
f01059cd:	e8 e5 fe ff ff       	call   f01058b7 <mpsearch1>
f01059d2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
mpconfig(struct mp **pmp)
{
	struct mpconf *conf;
	struct mp *mp;

	if ((mp = mpsearch()) == 0)
f01059d5:	85 c0                	test   %eax,%eax
f01059d7:	0f 84 5d 02 00 00    	je     f0105c3a <mp_init+0x2ea>
		return NULL;
	if (mp->physaddr == 0 || mp->type != 0) {
f01059dd:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01059e0:	8b 70 04             	mov    0x4(%eax),%esi
f01059e3:	85 f6                	test   %esi,%esi
f01059e5:	74 06                	je     f01059ed <mp_init+0x9d>
f01059e7:	80 78 0b 00          	cmpb   $0x0,0xb(%eax)
f01059eb:	74 15                	je     f0105a02 <mp_init+0xb2>
		cprintf("SMP: Default configurations not implemented\n");
f01059ed:	83 ec 0c             	sub    $0xc,%esp
f01059f0:	68 38 7c 10 f0       	push   $0xf0107c38
f01059f5:	e8 62 dd ff ff       	call   f010375c <cprintf>
f01059fa:	83 c4 10             	add    $0x10,%esp
f01059fd:	e9 38 02 00 00       	jmp    f0105c3a <mp_init+0x2ea>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0105a02:	89 f0                	mov    %esi,%eax
f0105a04:	c1 e8 0c             	shr    $0xc,%eax
f0105a07:	3b 05 88 fe 22 f0    	cmp    0xf022fe88,%eax
f0105a0d:	72 15                	jb     f0105a24 <mp_init+0xd4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0105a0f:	56                   	push   %esi
f0105a10:	68 24 63 10 f0       	push   $0xf0106324
f0105a15:	68 90 00 00 00       	push   $0x90
f0105a1a:	68 c5 7d 10 f0       	push   $0xf0107dc5
f0105a1f:	e8 1c a6 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0105a24:	8d 9e 00 00 00 f0    	lea    -0x10000000(%esi),%ebx
		return NULL;
	}
	conf = (struct mpconf *) KADDR(mp->physaddr);
	if (memcmp(conf, "PCMP", 4) != 0) {
f0105a2a:	83 ec 04             	sub    $0x4,%esp
f0105a2d:	6a 04                	push   $0x4
f0105a2f:	68 da 7d 10 f0       	push   $0xf0107dda
f0105a34:	53                   	push   %ebx
f0105a35:	e8 c7 fc ff ff       	call   f0105701 <memcmp>
f0105a3a:	83 c4 10             	add    $0x10,%esp
f0105a3d:	85 c0                	test   %eax,%eax
f0105a3f:	74 15                	je     f0105a56 <mp_init+0x106>
		cprintf("SMP: Incorrect MP configuration table signature\n");
f0105a41:	83 ec 0c             	sub    $0xc,%esp
f0105a44:	68 68 7c 10 f0       	push   $0xf0107c68
f0105a49:	e8 0e dd ff ff       	call   f010375c <cprintf>
f0105a4e:	83 c4 10             	add    $0x10,%esp
f0105a51:	e9 e4 01 00 00       	jmp    f0105c3a <mp_init+0x2ea>
		return NULL;
	}
	if (sum(conf, conf->length) != 0) {
f0105a56:	0f b7 43 04          	movzwl 0x4(%ebx),%eax
f0105a5a:	66 89 45 e2          	mov    %ax,-0x1e(%ebp)
f0105a5e:	0f b7 f8             	movzwl %ax,%edi
static uint8_t
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
f0105a61:	ba 00 00 00 00       	mov    $0x0,%edx
	for (i = 0; i < len; i++)
f0105a66:	b8 00 00 00 00       	mov    $0x0,%eax
f0105a6b:	eb 0d                	jmp    f0105a7a <mp_init+0x12a>
		sum += ((uint8_t *)addr)[i];
f0105a6d:	0f b6 8c 30 00 00 00 	movzbl -0x10000000(%eax,%esi,1),%ecx
f0105a74:	f0 
f0105a75:	01 ca                	add    %ecx,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f0105a77:	83 c0 01             	add    $0x1,%eax
f0105a7a:	39 c7                	cmp    %eax,%edi
f0105a7c:	75 ef                	jne    f0105a6d <mp_init+0x11d>
	conf = (struct mpconf *) KADDR(mp->physaddr);
	if (memcmp(conf, "PCMP", 4) != 0) {
		cprintf("SMP: Incorrect MP configuration table signature\n");
		return NULL;
	}
	if (sum(conf, conf->length) != 0) {
f0105a7e:	84 d2                	test   %dl,%dl
f0105a80:	74 15                	je     f0105a97 <mp_init+0x147>
		cprintf("SMP: Bad MP configuration checksum\n");
f0105a82:	83 ec 0c             	sub    $0xc,%esp
f0105a85:	68 9c 7c 10 f0       	push   $0xf0107c9c
f0105a8a:	e8 cd dc ff ff       	call   f010375c <cprintf>
f0105a8f:	83 c4 10             	add    $0x10,%esp
f0105a92:	e9 a3 01 00 00       	jmp    f0105c3a <mp_init+0x2ea>
		return NULL;
	}
	if (conf->version != 1 && conf->version != 4) {
f0105a97:	0f b6 43 06          	movzbl 0x6(%ebx),%eax
f0105a9b:	3c 01                	cmp    $0x1,%al
f0105a9d:	74 1d                	je     f0105abc <mp_init+0x16c>
f0105a9f:	3c 04                	cmp    $0x4,%al
f0105aa1:	74 19                	je     f0105abc <mp_init+0x16c>
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
f0105aa3:	83 ec 08             	sub    $0x8,%esp
f0105aa6:	0f b6 c0             	movzbl %al,%eax
f0105aa9:	50                   	push   %eax
f0105aaa:	68 c0 7c 10 f0       	push   $0xf0107cc0
f0105aaf:	e8 a8 dc ff ff       	call   f010375c <cprintf>
f0105ab4:	83 c4 10             	add    $0x10,%esp
f0105ab7:	e9 7e 01 00 00       	jmp    f0105c3a <mp_init+0x2ea>
		return NULL;
	}
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f0105abc:	0f b7 7b 28          	movzwl 0x28(%ebx),%edi
f0105ac0:	0f b7 4d e2          	movzwl -0x1e(%ebp),%ecx
static uint8_t
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
f0105ac4:	ba 00 00 00 00       	mov    $0x0,%edx
	for (i = 0; i < len; i++)
f0105ac9:	b8 00 00 00 00       	mov    $0x0,%eax
		sum += ((uint8_t *)addr)[i];
f0105ace:	01 ce                	add    %ecx,%esi
f0105ad0:	eb 0d                	jmp    f0105adf <mp_init+0x18f>
f0105ad2:	0f b6 8c 06 00 00 00 	movzbl -0x10000000(%esi,%eax,1),%ecx
f0105ad9:	f0 
f0105ada:	01 ca                	add    %ecx,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f0105adc:	83 c0 01             	add    $0x1,%eax
f0105adf:	39 c7                	cmp    %eax,%edi
f0105ae1:	75 ef                	jne    f0105ad2 <mp_init+0x182>
	}
	if (conf->version != 1 && conf->version != 4) {
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
		return NULL;
	}
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f0105ae3:	89 d0                	mov    %edx,%eax
f0105ae5:	02 43 2a             	add    0x2a(%ebx),%al
f0105ae8:	74 15                	je     f0105aff <mp_init+0x1af>
		cprintf("SMP: Bad MP configuration extended checksum\n");
f0105aea:	83 ec 0c             	sub    $0xc,%esp
f0105aed:	68 e0 7c 10 f0       	push   $0xf0107ce0
f0105af2:	e8 65 dc ff ff       	call   f010375c <cprintf>
f0105af7:	83 c4 10             	add    $0x10,%esp
f0105afa:	e9 3b 01 00 00       	jmp    f0105c3a <mp_init+0x2ea>
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
	if ((conf = mpconfig(&mp)) == 0)
f0105aff:	85 db                	test   %ebx,%ebx
f0105b01:	0f 84 33 01 00 00    	je     f0105c3a <mp_init+0x2ea>
		return;
	ismp = 1;
f0105b07:	c7 05 00 00 23 f0 01 	movl   $0x1,0xf0230000
f0105b0e:	00 00 00 
	lapicaddr = conf->lapicaddr;
f0105b11:	8b 43 24             	mov    0x24(%ebx),%eax
f0105b14:	a3 00 10 27 f0       	mov    %eax,0xf0271000

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f0105b19:	8d 7b 2c             	lea    0x2c(%ebx),%edi
f0105b1c:	be 00 00 00 00       	mov    $0x0,%esi
f0105b21:	e9 85 00 00 00       	jmp    f0105bab <mp_init+0x25b>
		switch (*p) {
f0105b26:	0f b6 07             	movzbl (%edi),%eax
f0105b29:	84 c0                	test   %al,%al
f0105b2b:	74 06                	je     f0105b33 <mp_init+0x1e3>
f0105b2d:	3c 04                	cmp    $0x4,%al
f0105b2f:	77 55                	ja     f0105b86 <mp_init+0x236>
f0105b31:	eb 4e                	jmp    f0105b81 <mp_init+0x231>
		case MPPROC:
			proc = (struct mpproc *)p;
			if (proc->flags & MPPROC_BOOT)
f0105b33:	f6 47 03 02          	testb  $0x2,0x3(%edi)
f0105b37:	74 11                	je     f0105b4a <mp_init+0x1fa>
				bootcpu = &cpus[ncpu];
f0105b39:	6b 05 c4 03 23 f0 74 	imul   $0x74,0xf02303c4,%eax
f0105b40:	05 20 00 23 f0       	add    $0xf0230020,%eax
f0105b45:	a3 c0 03 23 f0       	mov    %eax,0xf02303c0
			if (ncpu < NCPU) {
f0105b4a:	a1 c4 03 23 f0       	mov    0xf02303c4,%eax
f0105b4f:	83 f8 07             	cmp    $0x7,%eax
f0105b52:	7f 13                	jg     f0105b67 <mp_init+0x217>
				cpus[ncpu].cpu_id = ncpu;
f0105b54:	6b d0 74             	imul   $0x74,%eax,%edx
f0105b57:	88 82 20 00 23 f0    	mov    %al,-0xfdcffe0(%edx)
				ncpu++;
f0105b5d:	83 c0 01             	add    $0x1,%eax
f0105b60:	a3 c4 03 23 f0       	mov    %eax,0xf02303c4
f0105b65:	eb 15                	jmp    f0105b7c <mp_init+0x22c>
			} else {
				cprintf("SMP: too many CPUs, CPU %d disabled\n",
f0105b67:	83 ec 08             	sub    $0x8,%esp
f0105b6a:	0f b6 47 01          	movzbl 0x1(%edi),%eax
f0105b6e:	50                   	push   %eax
f0105b6f:	68 10 7d 10 f0       	push   $0xf0107d10
f0105b74:	e8 e3 db ff ff       	call   f010375c <cprintf>
f0105b79:	83 c4 10             	add    $0x10,%esp
					proc->apicid);
			}
			p += sizeof(struct mpproc);
f0105b7c:	83 c7 14             	add    $0x14,%edi
			continue;
f0105b7f:	eb 27                	jmp    f0105ba8 <mp_init+0x258>
		case MPBUS:
		case MPIOAPIC:
		case MPIOINTR:
		case MPLINTR:
			p += 8;
f0105b81:	83 c7 08             	add    $0x8,%edi
			continue;
f0105b84:	eb 22                	jmp    f0105ba8 <mp_init+0x258>
		default:
			cprintf("mpinit: unknown config type %x\n", *p);
f0105b86:	83 ec 08             	sub    $0x8,%esp
f0105b89:	0f b6 c0             	movzbl %al,%eax
f0105b8c:	50                   	push   %eax
f0105b8d:	68 38 7d 10 f0       	push   $0xf0107d38
f0105b92:	e8 c5 db ff ff       	call   f010375c <cprintf>
			ismp = 0;
f0105b97:	c7 05 00 00 23 f0 00 	movl   $0x0,0xf0230000
f0105b9e:	00 00 00 
			i = conf->entry;
f0105ba1:	0f b7 73 22          	movzwl 0x22(%ebx),%esi
f0105ba5:	83 c4 10             	add    $0x10,%esp
	if ((conf = mpconfig(&mp)) == 0)
		return;
	ismp = 1;
	lapicaddr = conf->lapicaddr;

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f0105ba8:	83 c6 01             	add    $0x1,%esi
f0105bab:	0f b7 43 22          	movzwl 0x22(%ebx),%eax
f0105baf:	39 c6                	cmp    %eax,%esi
f0105bb1:	0f 82 6f ff ff ff    	jb     f0105b26 <mp_init+0x1d6>
			ismp = 0;
			i = conf->entry;
		}
	}

	bootcpu->cpu_status = CPU_STARTED;
f0105bb7:	a1 c0 03 23 f0       	mov    0xf02303c0,%eax
f0105bbc:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
	if (!ismp) {
f0105bc3:	83 3d 00 00 23 f0 00 	cmpl   $0x0,0xf0230000
f0105bca:	75 26                	jne    f0105bf2 <mp_init+0x2a2>
		// Didn't like what we found; fall back to no MP.
		ncpu = 1;
f0105bcc:	c7 05 c4 03 23 f0 01 	movl   $0x1,0xf02303c4
f0105bd3:	00 00 00 
		lapicaddr = 0;
f0105bd6:	c7 05 00 10 27 f0 00 	movl   $0x0,0xf0271000
f0105bdd:	00 00 00 
		cprintf("SMP: configuration not found, SMP disabled\n");
f0105be0:	83 ec 0c             	sub    $0xc,%esp
f0105be3:	68 58 7d 10 f0       	push   $0xf0107d58
f0105be8:	e8 6f db ff ff       	call   f010375c <cprintf>
		return;
f0105bed:	83 c4 10             	add    $0x10,%esp
f0105bf0:	eb 48                	jmp    f0105c3a <mp_init+0x2ea>
	}
	cprintf("SMP: CPU %d found %d CPU(s)\n", bootcpu->cpu_id,  ncpu);
f0105bf2:	83 ec 04             	sub    $0x4,%esp
f0105bf5:	ff 35 c4 03 23 f0    	pushl  0xf02303c4
f0105bfb:	0f b6 00             	movzbl (%eax),%eax
f0105bfe:	50                   	push   %eax
f0105bff:	68 df 7d 10 f0       	push   $0xf0107ddf
f0105c04:	e8 53 db ff ff       	call   f010375c <cprintf>

	if (mp->imcrp) {
f0105c09:	83 c4 10             	add    $0x10,%esp
f0105c0c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0105c0f:	80 78 0c 00          	cmpb   $0x0,0xc(%eax)
f0105c13:	74 25                	je     f0105c3a <mp_init+0x2ea>
		// [MP 3.2.6.1] If the hardware implements PIC mode,
		// switch to getting interrupts from the LAPIC.
		cprintf("SMP: Setting IMCR to switch from PIC mode to symmetric I/O mode\n");
f0105c15:	83 ec 0c             	sub    $0xc,%esp
f0105c18:	68 84 7d 10 f0       	push   $0xf0107d84
f0105c1d:	e8 3a db ff ff       	call   f010375c <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0105c22:	ba 22 00 00 00       	mov    $0x22,%edx
f0105c27:	b8 70 00 00 00       	mov    $0x70,%eax
f0105c2c:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0105c2d:	ba 23 00 00 00       	mov    $0x23,%edx
f0105c32:	ec                   	in     (%dx),%al
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0105c33:	83 c8 01             	or     $0x1,%eax
f0105c36:	ee                   	out    %al,(%dx)
f0105c37:	83 c4 10             	add    $0x10,%esp
		outb(0x22, 0x70);   // Select IMCR
		outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
	}
}
f0105c3a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0105c3d:	5b                   	pop    %ebx
f0105c3e:	5e                   	pop    %esi
f0105c3f:	5f                   	pop    %edi
f0105c40:	5d                   	pop    %ebp
f0105c41:	c3                   	ret    

f0105c42 <lapicw>:
physaddr_t lapicaddr;        // Initialized in mpconfig.c
volatile uint32_t *lapic;

static void
lapicw(int index, int value)
{
f0105c42:	55                   	push   %ebp
f0105c43:	89 e5                	mov    %esp,%ebp
	lapic[index] = value;
f0105c45:	8b 0d 04 10 27 f0    	mov    0xf0271004,%ecx
f0105c4b:	8d 04 81             	lea    (%ecx,%eax,4),%eax
f0105c4e:	89 10                	mov    %edx,(%eax)
	lapic[ID];  // wait for write to finish, by reading
f0105c50:	a1 04 10 27 f0       	mov    0xf0271004,%eax
f0105c55:	8b 40 20             	mov    0x20(%eax),%eax
}
f0105c58:	5d                   	pop    %ebp
f0105c59:	c3                   	ret    

f0105c5a <cpunum>:
	lapicw(TPR, 0);
}

int
cpunum(void)
{
f0105c5a:	55                   	push   %ebp
f0105c5b:	89 e5                	mov    %esp,%ebp
	if (lapic)
f0105c5d:	a1 04 10 27 f0       	mov    0xf0271004,%eax
f0105c62:	85 c0                	test   %eax,%eax
f0105c64:	74 08                	je     f0105c6e <cpunum+0x14>
		return lapic[ID] >> 24;
f0105c66:	8b 40 20             	mov    0x20(%eax),%eax
f0105c69:	c1 e8 18             	shr    $0x18,%eax
f0105c6c:	eb 05                	jmp    f0105c73 <cpunum+0x19>
	return 0;
f0105c6e:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105c73:	5d                   	pop    %ebp
f0105c74:	c3                   	ret    

f0105c75 <lapic_init>:
}

void
lapic_init(void)
{
	if (!lapicaddr)
f0105c75:	a1 00 10 27 f0       	mov    0xf0271000,%eax
f0105c7a:	85 c0                	test   %eax,%eax
f0105c7c:	0f 84 21 01 00 00    	je     f0105da3 <lapic_init+0x12e>
	lapic[ID];  // wait for write to finish, by reading
}

void
lapic_init(void)
{
f0105c82:	55                   	push   %ebp
f0105c83:	89 e5                	mov    %esp,%ebp
f0105c85:	83 ec 10             	sub    $0x10,%esp
	if (!lapicaddr)
		return;

	// lapicaddr is the physical address of the LAPIC's 4K MMIO
	// region.  Map it in to virtual memory so we can access it.
	lapic = mmio_map_region(lapicaddr, 4096);
f0105c88:	68 00 10 00 00       	push   $0x1000
f0105c8d:	50                   	push   %eax
f0105c8e:	e8 33 b5 ff ff       	call   f01011c6 <mmio_map_region>
f0105c93:	a3 04 10 27 f0       	mov    %eax,0xf0271004

	// Enable local APIC; set spurious interrupt vector.
	lapicw(SVR, ENABLE | (IRQ_OFFSET + IRQ_SPURIOUS));
f0105c98:	ba 27 01 00 00       	mov    $0x127,%edx
f0105c9d:	b8 3c 00 00 00       	mov    $0x3c,%eax
f0105ca2:	e8 9b ff ff ff       	call   f0105c42 <lapicw>

	// The timer repeatedly counts down at bus frequency
	// from lapic[TICR] and then issues an interrupt.  
	// If we cared more about precise timekeeping,
	// TICR would be calibrated using an external time source.
	lapicw(TDCR, X1);
f0105ca7:	ba 0b 00 00 00       	mov    $0xb,%edx
f0105cac:	b8 f8 00 00 00       	mov    $0xf8,%eax
f0105cb1:	e8 8c ff ff ff       	call   f0105c42 <lapicw>
	lapicw(TIMER, PERIODIC | (IRQ_OFFSET + IRQ_TIMER));
f0105cb6:	ba 20 00 02 00       	mov    $0x20020,%edx
f0105cbb:	b8 c8 00 00 00       	mov    $0xc8,%eax
f0105cc0:	e8 7d ff ff ff       	call   f0105c42 <lapicw>
	lapicw(TICR, 10000000); 
f0105cc5:	ba 80 96 98 00       	mov    $0x989680,%edx
f0105cca:	b8 e0 00 00 00       	mov    $0xe0,%eax
f0105ccf:	e8 6e ff ff ff       	call   f0105c42 <lapicw>
	//
	// According to Intel MP Specification, the BIOS should initialize
	// BSP's local APIC in Virtual Wire Mode, in which 8259A's
	// INTR is virtually connected to BSP's LINTIN0. In this mode,
	// we do not need to program the IOAPIC.
	if (thiscpu != bootcpu)
f0105cd4:	e8 81 ff ff ff       	call   f0105c5a <cpunum>
f0105cd9:	6b c0 74             	imul   $0x74,%eax,%eax
f0105cdc:	05 20 00 23 f0       	add    $0xf0230020,%eax
f0105ce1:	83 c4 10             	add    $0x10,%esp
f0105ce4:	39 05 c0 03 23 f0    	cmp    %eax,0xf02303c0
f0105cea:	74 0f                	je     f0105cfb <lapic_init+0x86>
		lapicw(LINT0, MASKED);
f0105cec:	ba 00 00 01 00       	mov    $0x10000,%edx
f0105cf1:	b8 d4 00 00 00       	mov    $0xd4,%eax
f0105cf6:	e8 47 ff ff ff       	call   f0105c42 <lapicw>

	// Disable NMI (LINT1) on all CPUs
	lapicw(LINT1, MASKED);
f0105cfb:	ba 00 00 01 00       	mov    $0x10000,%edx
f0105d00:	b8 d8 00 00 00       	mov    $0xd8,%eax
f0105d05:	e8 38 ff ff ff       	call   f0105c42 <lapicw>

	// Disable performance counter overflow interrupts
	// on machines that provide that interrupt entry.
	if (((lapic[VER]>>16) & 0xFF) >= 4)
f0105d0a:	a1 04 10 27 f0       	mov    0xf0271004,%eax
f0105d0f:	8b 40 30             	mov    0x30(%eax),%eax
f0105d12:	c1 e8 10             	shr    $0x10,%eax
f0105d15:	3c 03                	cmp    $0x3,%al
f0105d17:	76 0f                	jbe    f0105d28 <lapic_init+0xb3>
		lapicw(PCINT, MASKED);
f0105d19:	ba 00 00 01 00       	mov    $0x10000,%edx
f0105d1e:	b8 d0 00 00 00       	mov    $0xd0,%eax
f0105d23:	e8 1a ff ff ff       	call   f0105c42 <lapicw>

	// Map error interrupt to IRQ_ERROR.
	lapicw(ERROR, IRQ_OFFSET + IRQ_ERROR);
f0105d28:	ba 33 00 00 00       	mov    $0x33,%edx
f0105d2d:	b8 dc 00 00 00       	mov    $0xdc,%eax
f0105d32:	e8 0b ff ff ff       	call   f0105c42 <lapicw>

	// Clear error status register (requires back-to-back writes).
	lapicw(ESR, 0);
f0105d37:	ba 00 00 00 00       	mov    $0x0,%edx
f0105d3c:	b8 a0 00 00 00       	mov    $0xa0,%eax
f0105d41:	e8 fc fe ff ff       	call   f0105c42 <lapicw>
	lapicw(ESR, 0);
f0105d46:	ba 00 00 00 00       	mov    $0x0,%edx
f0105d4b:	b8 a0 00 00 00       	mov    $0xa0,%eax
f0105d50:	e8 ed fe ff ff       	call   f0105c42 <lapicw>

	// Ack any outstanding interrupts.
	lapicw(EOI, 0);
f0105d55:	ba 00 00 00 00       	mov    $0x0,%edx
f0105d5a:	b8 2c 00 00 00       	mov    $0x2c,%eax
f0105d5f:	e8 de fe ff ff       	call   f0105c42 <lapicw>

	// Send an Init Level De-Assert to synchronize arbitration ID's.
	lapicw(ICRHI, 0);
f0105d64:	ba 00 00 00 00       	mov    $0x0,%edx
f0105d69:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105d6e:	e8 cf fe ff ff       	call   f0105c42 <lapicw>
	lapicw(ICRLO, BCAST | INIT | LEVEL);
f0105d73:	ba 00 85 08 00       	mov    $0x88500,%edx
f0105d78:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105d7d:	e8 c0 fe ff ff       	call   f0105c42 <lapicw>
	while(lapic[ICRLO] & DELIVS)
f0105d82:	8b 15 04 10 27 f0    	mov    0xf0271004,%edx
f0105d88:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f0105d8e:	f6 c4 10             	test   $0x10,%ah
f0105d91:	75 f5                	jne    f0105d88 <lapic_init+0x113>
		;

	// Enable interrupts on the APIC (but not on the processor).
	lapicw(TPR, 0);
f0105d93:	ba 00 00 00 00       	mov    $0x0,%edx
f0105d98:	b8 20 00 00 00       	mov    $0x20,%eax
f0105d9d:	e8 a0 fe ff ff       	call   f0105c42 <lapicw>
}
f0105da2:	c9                   	leave  
f0105da3:	f3 c3                	repz ret 

f0105da5 <lapic_eoi>:

// Acknowledge interrupt.
void
lapic_eoi(void)
{
	if (lapic)
f0105da5:	83 3d 04 10 27 f0 00 	cmpl   $0x0,0xf0271004
f0105dac:	74 13                	je     f0105dc1 <lapic_eoi+0x1c>
}

// Acknowledge interrupt.
void
lapic_eoi(void)
{
f0105dae:	55                   	push   %ebp
f0105daf:	89 e5                	mov    %esp,%ebp
	if (lapic)
		lapicw(EOI, 0);
f0105db1:	ba 00 00 00 00       	mov    $0x0,%edx
f0105db6:	b8 2c 00 00 00       	mov    $0x2c,%eax
f0105dbb:	e8 82 fe ff ff       	call   f0105c42 <lapicw>
}
f0105dc0:	5d                   	pop    %ebp
f0105dc1:	f3 c3                	repz ret 

f0105dc3 <lapic_startap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapic_startap(uint8_t apicid, uint32_t addr)
{
f0105dc3:	55                   	push   %ebp
f0105dc4:	89 e5                	mov    %esp,%ebp
f0105dc6:	56                   	push   %esi
f0105dc7:	53                   	push   %ebx
f0105dc8:	8b 75 08             	mov    0x8(%ebp),%esi
f0105dcb:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0105dce:	ba 70 00 00 00       	mov    $0x70,%edx
f0105dd3:	b8 0f 00 00 00       	mov    $0xf,%eax
f0105dd8:	ee                   	out    %al,(%dx)
f0105dd9:	ba 71 00 00 00       	mov    $0x71,%edx
f0105dde:	b8 0a 00 00 00       	mov    $0xa,%eax
f0105de3:	ee                   	out    %al,(%dx)
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0105de4:	83 3d 88 fe 22 f0 00 	cmpl   $0x0,0xf022fe88
f0105deb:	75 19                	jne    f0105e06 <lapic_startap+0x43>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0105ded:	68 67 04 00 00       	push   $0x467
f0105df2:	68 24 63 10 f0       	push   $0xf0106324
f0105df7:	68 98 00 00 00       	push   $0x98
f0105dfc:	68 fc 7d 10 f0       	push   $0xf0107dfc
f0105e01:	e8 3a a2 ff ff       	call   f0100040 <_panic>
	// and the warm reset vector (DWORD based at 40:67) to point at
	// the AP startup code prior to the [universal startup algorithm]."
	outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
	outb(IO_RTC+1, 0x0A);
	wrv = (uint16_t *)KADDR((0x40 << 4 | 0x67));  // Warm reset vector
	wrv[0] = 0;
f0105e06:	66 c7 05 67 04 00 f0 	movw   $0x0,0xf0000467
f0105e0d:	00 00 
	wrv[1] = addr >> 4;
f0105e0f:	89 d8                	mov    %ebx,%eax
f0105e11:	c1 e8 04             	shr    $0x4,%eax
f0105e14:	66 a3 69 04 00 f0    	mov    %ax,0xf0000469

	// "Universal startup algorithm."
	// Send INIT (level-triggered) interrupt to reset other CPU.
	lapicw(ICRHI, apicid << 24);
f0105e1a:	c1 e6 18             	shl    $0x18,%esi
f0105e1d:	89 f2                	mov    %esi,%edx
f0105e1f:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105e24:	e8 19 fe ff ff       	call   f0105c42 <lapicw>
	lapicw(ICRLO, INIT | LEVEL | ASSERT);
f0105e29:	ba 00 c5 00 00       	mov    $0xc500,%edx
f0105e2e:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105e33:	e8 0a fe ff ff       	call   f0105c42 <lapicw>
	microdelay(200);
	lapicw(ICRLO, INIT | LEVEL);
f0105e38:	ba 00 85 00 00       	mov    $0x8500,%edx
f0105e3d:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105e42:	e8 fb fd ff ff       	call   f0105c42 <lapicw>
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0105e47:	c1 eb 0c             	shr    $0xc,%ebx
f0105e4a:	80 cf 06             	or     $0x6,%bh
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
f0105e4d:	89 f2                	mov    %esi,%edx
f0105e4f:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105e54:	e8 e9 fd ff ff       	call   f0105c42 <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0105e59:	89 da                	mov    %ebx,%edx
f0105e5b:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105e60:	e8 dd fd ff ff       	call   f0105c42 <lapicw>
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
f0105e65:	89 f2                	mov    %esi,%edx
f0105e67:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105e6c:	e8 d1 fd ff ff       	call   f0105c42 <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0105e71:	89 da                	mov    %ebx,%edx
f0105e73:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105e78:	e8 c5 fd ff ff       	call   f0105c42 <lapicw>
		microdelay(200);
	}
}
f0105e7d:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0105e80:	5b                   	pop    %ebx
f0105e81:	5e                   	pop    %esi
f0105e82:	5d                   	pop    %ebp
f0105e83:	c3                   	ret    

f0105e84 <lapic_ipi>:

void
lapic_ipi(int vector)
{
f0105e84:	55                   	push   %ebp
f0105e85:	89 e5                	mov    %esp,%ebp
	lapicw(ICRLO, OTHERS | FIXED | vector);
f0105e87:	8b 55 08             	mov    0x8(%ebp),%edx
f0105e8a:	81 ca 00 00 0c 00    	or     $0xc0000,%edx
f0105e90:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105e95:	e8 a8 fd ff ff       	call   f0105c42 <lapicw>
	while (lapic[ICRLO] & DELIVS)
f0105e9a:	8b 15 04 10 27 f0    	mov    0xf0271004,%edx
f0105ea0:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f0105ea6:	f6 c4 10             	test   $0x10,%ah
f0105ea9:	75 f5                	jne    f0105ea0 <lapic_ipi+0x1c>
		;
}
f0105eab:	5d                   	pop    %ebp
f0105eac:	c3                   	ret    

f0105ead <__spin_initlock>:
}
#endif

void
__spin_initlock(struct spinlock *lk, char *name)
{
f0105ead:	55                   	push   %ebp
f0105eae:	89 e5                	mov    %esp,%ebp
f0105eb0:	8b 45 08             	mov    0x8(%ebp),%eax
	lk->locked = 0;
f0105eb3:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
#ifdef DEBUG_SPINLOCK
	lk->name = name;
f0105eb9:	8b 55 0c             	mov    0xc(%ebp),%edx
f0105ebc:	89 50 04             	mov    %edx,0x4(%eax)
	lk->cpu = 0;
f0105ebf:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
#endif
}
f0105ec6:	5d                   	pop    %ebp
f0105ec7:	c3                   	ret    

f0105ec8 <spin_lock>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
f0105ec8:	55                   	push   %ebp
f0105ec9:	89 e5                	mov    %esp,%ebp
f0105ecb:	56                   	push   %esi
f0105ecc:	53                   	push   %ebx
f0105ecd:	8b 5d 08             	mov    0x8(%ebp),%ebx

// Check whether this CPU is holding the lock.
static int
holding(struct spinlock *lock)
{
	return lock->locked && lock->cpu == thiscpu;
f0105ed0:	83 3b 00             	cmpl   $0x0,(%ebx)
f0105ed3:	74 14                	je     f0105ee9 <spin_lock+0x21>
f0105ed5:	8b 73 08             	mov    0x8(%ebx),%esi
f0105ed8:	e8 7d fd ff ff       	call   f0105c5a <cpunum>
f0105edd:	6b c0 74             	imul   $0x74,%eax,%eax
f0105ee0:	05 20 00 23 f0       	add    $0xf0230020,%eax
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
#ifdef DEBUG_SPINLOCK
	if (holding(lk))
f0105ee5:	39 c6                	cmp    %eax,%esi
f0105ee7:	74 07                	je     f0105ef0 <spin_lock+0x28>
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f0105ee9:	ba 01 00 00 00       	mov    $0x1,%edx
f0105eee:	eb 20                	jmp    f0105f10 <spin_lock+0x48>
		panic("CPU %d cannot acquire %s: already holding", cpunum(), lk->name);
f0105ef0:	8b 5b 04             	mov    0x4(%ebx),%ebx
f0105ef3:	e8 62 fd ff ff       	call   f0105c5a <cpunum>
f0105ef8:	83 ec 0c             	sub    $0xc,%esp
f0105efb:	53                   	push   %ebx
f0105efc:	50                   	push   %eax
f0105efd:	68 0c 7e 10 f0       	push   $0xf0107e0c
f0105f02:	6a 41                	push   $0x41
f0105f04:	68 70 7e 10 f0       	push   $0xf0107e70
f0105f09:	e8 32 a1 ff ff       	call   f0100040 <_panic>

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
		asm volatile ("pause");
f0105f0e:	f3 90                	pause  
f0105f10:	89 d0                	mov    %edx,%eax
f0105f12:	f0 87 03             	lock xchg %eax,(%ebx)
#endif

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
f0105f15:	85 c0                	test   %eax,%eax
f0105f17:	75 f5                	jne    f0105f0e <spin_lock+0x46>
		asm volatile ("pause");

	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
f0105f19:	e8 3c fd ff ff       	call   f0105c5a <cpunum>
f0105f1e:	6b c0 74             	imul   $0x74,%eax,%eax
f0105f21:	05 20 00 23 f0       	add    $0xf0230020,%eax
f0105f26:	89 43 08             	mov    %eax,0x8(%ebx)
	get_caller_pcs(lk->pcs);
f0105f29:	83 c3 0c             	add    $0xc,%ebx

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f0105f2c:	89 ea                	mov    %ebp,%edx
{
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
	for (i = 0; i < 10; i++){
f0105f2e:	b8 00 00 00 00       	mov    $0x0,%eax
f0105f33:	eb 0b                	jmp    f0105f40 <spin_lock+0x78>
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
			break;
		pcs[i] = ebp[1];          // saved %eip
f0105f35:	8b 4a 04             	mov    0x4(%edx),%ecx
f0105f38:	89 0c 83             	mov    %ecx,(%ebx,%eax,4)
		ebp = (uint32_t *)ebp[0]; // saved %ebp
f0105f3b:	8b 12                	mov    (%edx),%edx
{
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
	for (i = 0; i < 10; i++){
f0105f3d:	83 c0 01             	add    $0x1,%eax
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
f0105f40:	81 fa ff ff 7f ef    	cmp    $0xef7fffff,%edx
f0105f46:	76 11                	jbe    f0105f59 <spin_lock+0x91>
f0105f48:	83 f8 09             	cmp    $0x9,%eax
f0105f4b:	7e e8                	jle    f0105f35 <spin_lock+0x6d>
f0105f4d:	eb 0a                	jmp    f0105f59 <spin_lock+0x91>
			break;
		pcs[i] = ebp[1];          // saved %eip
		ebp = (uint32_t *)ebp[0]; // saved %ebp
	}
	for (; i < 10; i++)
		pcs[i] = 0;
f0105f4f:	c7 04 83 00 00 00 00 	movl   $0x0,(%ebx,%eax,4)
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
			break;
		pcs[i] = ebp[1];          // saved %eip
		ebp = (uint32_t *)ebp[0]; // saved %ebp
	}
	for (; i < 10; i++)
f0105f56:	83 c0 01             	add    $0x1,%eax
f0105f59:	83 f8 09             	cmp    $0x9,%eax
f0105f5c:	7e f1                	jle    f0105f4f <spin_lock+0x87>
	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
	get_caller_pcs(lk->pcs);
#endif
}
f0105f5e:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0105f61:	5b                   	pop    %ebx
f0105f62:	5e                   	pop    %esi
f0105f63:	5d                   	pop    %ebp
f0105f64:	c3                   	ret    

f0105f65 <spin_unlock>:

// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
f0105f65:	55                   	push   %ebp
f0105f66:	89 e5                	mov    %esp,%ebp
f0105f68:	57                   	push   %edi
f0105f69:	56                   	push   %esi
f0105f6a:	53                   	push   %ebx
f0105f6b:	83 ec 4c             	sub    $0x4c,%esp
f0105f6e:	8b 75 08             	mov    0x8(%ebp),%esi

// Check whether this CPU is holding the lock.
static int
holding(struct spinlock *lock)
{
	return lock->locked && lock->cpu == thiscpu;
f0105f71:	83 3e 00             	cmpl   $0x0,(%esi)
f0105f74:	74 18                	je     f0105f8e <spin_unlock+0x29>
f0105f76:	8b 5e 08             	mov    0x8(%esi),%ebx
f0105f79:	e8 dc fc ff ff       	call   f0105c5a <cpunum>
f0105f7e:	6b c0 74             	imul   $0x74,%eax,%eax
f0105f81:	05 20 00 23 f0       	add    $0xf0230020,%eax
// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
#ifdef DEBUG_SPINLOCK
	if (!holding(lk)) {
f0105f86:	39 c3                	cmp    %eax,%ebx
f0105f88:	0f 84 a5 00 00 00    	je     f0106033 <spin_unlock+0xce>
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
f0105f8e:	83 ec 04             	sub    $0x4,%esp
f0105f91:	6a 28                	push   $0x28
f0105f93:	8d 46 0c             	lea    0xc(%esi),%eax
f0105f96:	50                   	push   %eax
f0105f97:	8d 5d c0             	lea    -0x40(%ebp),%ebx
f0105f9a:	53                   	push   %ebx
f0105f9b:	e8 e6 f6 ff ff       	call   f0105686 <memmove>
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
f0105fa0:	8b 46 08             	mov    0x8(%esi),%eax
	if (!holding(lk)) {
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
f0105fa3:	0f b6 38             	movzbl (%eax),%edi
f0105fa6:	8b 76 04             	mov    0x4(%esi),%esi
f0105fa9:	e8 ac fc ff ff       	call   f0105c5a <cpunum>
f0105fae:	57                   	push   %edi
f0105faf:	56                   	push   %esi
f0105fb0:	50                   	push   %eax
f0105fb1:	68 38 7e 10 f0       	push   $0xf0107e38
f0105fb6:	e8 a1 d7 ff ff       	call   f010375c <cprintf>
f0105fbb:	83 c4 20             	add    $0x20,%esp
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
f0105fbe:	8d 7d a8             	lea    -0x58(%ebp),%edi
f0105fc1:	eb 54                	jmp    f0106017 <spin_unlock+0xb2>
f0105fc3:	83 ec 08             	sub    $0x8,%esp
f0105fc6:	57                   	push   %edi
f0105fc7:	50                   	push   %eax
f0105fc8:	e8 98 eb ff ff       	call   f0104b65 <debuginfo_eip>
f0105fcd:	83 c4 10             	add    $0x10,%esp
f0105fd0:	85 c0                	test   %eax,%eax
f0105fd2:	78 27                	js     f0105ffb <spin_unlock+0x96>
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
					info.eip_file, info.eip_line,
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
f0105fd4:	8b 06                	mov    (%esi),%eax
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
f0105fd6:	83 ec 04             	sub    $0x4,%esp
f0105fd9:	89 c2                	mov    %eax,%edx
f0105fdb:	2b 55 b8             	sub    -0x48(%ebp),%edx
f0105fde:	52                   	push   %edx
f0105fdf:	ff 75 b0             	pushl  -0x50(%ebp)
f0105fe2:	ff 75 b4             	pushl  -0x4c(%ebp)
f0105fe5:	ff 75 ac             	pushl  -0x54(%ebp)
f0105fe8:	ff 75 a8             	pushl  -0x58(%ebp)
f0105feb:	50                   	push   %eax
f0105fec:	68 80 7e 10 f0       	push   $0xf0107e80
f0105ff1:	e8 66 d7 ff ff       	call   f010375c <cprintf>
f0105ff6:	83 c4 20             	add    $0x20,%esp
f0105ff9:	eb 12                	jmp    f010600d <spin_unlock+0xa8>
					info.eip_file, info.eip_line,
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
			else
				cprintf("  %08x\n", pcs[i]);
f0105ffb:	83 ec 08             	sub    $0x8,%esp
f0105ffe:	ff 36                	pushl  (%esi)
f0106000:	68 97 7e 10 f0       	push   $0xf0107e97
f0106005:	e8 52 d7 ff ff       	call   f010375c <cprintf>
f010600a:	83 c4 10             	add    $0x10,%esp
f010600d:	83 c3 04             	add    $0x4,%ebx
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
f0106010:	8d 45 e8             	lea    -0x18(%ebp),%eax
f0106013:	39 c3                	cmp    %eax,%ebx
f0106015:	74 08                	je     f010601f <spin_unlock+0xba>
f0106017:	89 de                	mov    %ebx,%esi
f0106019:	8b 03                	mov    (%ebx),%eax
f010601b:	85 c0                	test   %eax,%eax
f010601d:	75 a4                	jne    f0105fc3 <spin_unlock+0x5e>
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
			else
				cprintf("  %08x\n", pcs[i]);
		}
		panic("spin_unlock");
f010601f:	83 ec 04             	sub    $0x4,%esp
f0106022:	68 9f 7e 10 f0       	push   $0xf0107e9f
f0106027:	6a 67                	push   $0x67
f0106029:	68 70 7e 10 f0       	push   $0xf0107e70
f010602e:	e8 0d a0 ff ff       	call   f0100040 <_panic>
	}

	lk->pcs[0] = 0;
f0106033:	c7 46 0c 00 00 00 00 	movl   $0x0,0xc(%esi)
	lk->cpu = 0;
f010603a:	c7 46 08 00 00 00 00 	movl   $0x0,0x8(%esi)
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f0106041:	b8 00 00 00 00       	mov    $0x0,%eax
f0106046:	f0 87 06             	lock xchg %eax,(%esi)
	// Paper says that Intel 64 and IA-32 will not move a load
	// after a store. So lock->locked = 0 would work here.
	// The xchg being asm volatile ensures gcc emits it after
	// the above assignments (and after the critical section).
	xchg(&lk->locked, 0);
}
f0106049:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010604c:	5b                   	pop    %ebx
f010604d:	5e                   	pop    %esi
f010604e:	5f                   	pop    %edi
f010604f:	5d                   	pop    %ebp
f0106050:	c3                   	ret    
f0106051:	66 90                	xchg   %ax,%ax
f0106053:	66 90                	xchg   %ax,%ax
f0106055:	66 90                	xchg   %ax,%ax
f0106057:	66 90                	xchg   %ax,%ax
f0106059:	66 90                	xchg   %ax,%ax
f010605b:	66 90                	xchg   %ax,%ax
f010605d:	66 90                	xchg   %ax,%ax
f010605f:	90                   	nop

f0106060 <__udivdi3>:
f0106060:	55                   	push   %ebp
f0106061:	57                   	push   %edi
f0106062:	56                   	push   %esi
f0106063:	53                   	push   %ebx
f0106064:	83 ec 1c             	sub    $0x1c,%esp
f0106067:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f010606b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f010606f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0106073:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0106077:	85 f6                	test   %esi,%esi
f0106079:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010607d:	89 ca                	mov    %ecx,%edx
f010607f:	89 f8                	mov    %edi,%eax
f0106081:	75 3d                	jne    f01060c0 <__udivdi3+0x60>
f0106083:	39 cf                	cmp    %ecx,%edi
f0106085:	0f 87 c5 00 00 00    	ja     f0106150 <__udivdi3+0xf0>
f010608b:	85 ff                	test   %edi,%edi
f010608d:	89 fd                	mov    %edi,%ebp
f010608f:	75 0b                	jne    f010609c <__udivdi3+0x3c>
f0106091:	b8 01 00 00 00       	mov    $0x1,%eax
f0106096:	31 d2                	xor    %edx,%edx
f0106098:	f7 f7                	div    %edi
f010609a:	89 c5                	mov    %eax,%ebp
f010609c:	89 c8                	mov    %ecx,%eax
f010609e:	31 d2                	xor    %edx,%edx
f01060a0:	f7 f5                	div    %ebp
f01060a2:	89 c1                	mov    %eax,%ecx
f01060a4:	89 d8                	mov    %ebx,%eax
f01060a6:	89 cf                	mov    %ecx,%edi
f01060a8:	f7 f5                	div    %ebp
f01060aa:	89 c3                	mov    %eax,%ebx
f01060ac:	89 d8                	mov    %ebx,%eax
f01060ae:	89 fa                	mov    %edi,%edx
f01060b0:	83 c4 1c             	add    $0x1c,%esp
f01060b3:	5b                   	pop    %ebx
f01060b4:	5e                   	pop    %esi
f01060b5:	5f                   	pop    %edi
f01060b6:	5d                   	pop    %ebp
f01060b7:	c3                   	ret    
f01060b8:	90                   	nop
f01060b9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01060c0:	39 ce                	cmp    %ecx,%esi
f01060c2:	77 74                	ja     f0106138 <__udivdi3+0xd8>
f01060c4:	0f bd fe             	bsr    %esi,%edi
f01060c7:	83 f7 1f             	xor    $0x1f,%edi
f01060ca:	0f 84 98 00 00 00    	je     f0106168 <__udivdi3+0x108>
f01060d0:	bb 20 00 00 00       	mov    $0x20,%ebx
f01060d5:	89 f9                	mov    %edi,%ecx
f01060d7:	89 c5                	mov    %eax,%ebp
f01060d9:	29 fb                	sub    %edi,%ebx
f01060db:	d3 e6                	shl    %cl,%esi
f01060dd:	89 d9                	mov    %ebx,%ecx
f01060df:	d3 ed                	shr    %cl,%ebp
f01060e1:	89 f9                	mov    %edi,%ecx
f01060e3:	d3 e0                	shl    %cl,%eax
f01060e5:	09 ee                	or     %ebp,%esi
f01060e7:	89 d9                	mov    %ebx,%ecx
f01060e9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01060ed:	89 d5                	mov    %edx,%ebp
f01060ef:	8b 44 24 08          	mov    0x8(%esp),%eax
f01060f3:	d3 ed                	shr    %cl,%ebp
f01060f5:	89 f9                	mov    %edi,%ecx
f01060f7:	d3 e2                	shl    %cl,%edx
f01060f9:	89 d9                	mov    %ebx,%ecx
f01060fb:	d3 e8                	shr    %cl,%eax
f01060fd:	09 c2                	or     %eax,%edx
f01060ff:	89 d0                	mov    %edx,%eax
f0106101:	89 ea                	mov    %ebp,%edx
f0106103:	f7 f6                	div    %esi
f0106105:	89 d5                	mov    %edx,%ebp
f0106107:	89 c3                	mov    %eax,%ebx
f0106109:	f7 64 24 0c          	mull   0xc(%esp)
f010610d:	39 d5                	cmp    %edx,%ebp
f010610f:	72 10                	jb     f0106121 <__udivdi3+0xc1>
f0106111:	8b 74 24 08          	mov    0x8(%esp),%esi
f0106115:	89 f9                	mov    %edi,%ecx
f0106117:	d3 e6                	shl    %cl,%esi
f0106119:	39 c6                	cmp    %eax,%esi
f010611b:	73 07                	jae    f0106124 <__udivdi3+0xc4>
f010611d:	39 d5                	cmp    %edx,%ebp
f010611f:	75 03                	jne    f0106124 <__udivdi3+0xc4>
f0106121:	83 eb 01             	sub    $0x1,%ebx
f0106124:	31 ff                	xor    %edi,%edi
f0106126:	89 d8                	mov    %ebx,%eax
f0106128:	89 fa                	mov    %edi,%edx
f010612a:	83 c4 1c             	add    $0x1c,%esp
f010612d:	5b                   	pop    %ebx
f010612e:	5e                   	pop    %esi
f010612f:	5f                   	pop    %edi
f0106130:	5d                   	pop    %ebp
f0106131:	c3                   	ret    
f0106132:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0106138:	31 ff                	xor    %edi,%edi
f010613a:	31 db                	xor    %ebx,%ebx
f010613c:	89 d8                	mov    %ebx,%eax
f010613e:	89 fa                	mov    %edi,%edx
f0106140:	83 c4 1c             	add    $0x1c,%esp
f0106143:	5b                   	pop    %ebx
f0106144:	5e                   	pop    %esi
f0106145:	5f                   	pop    %edi
f0106146:	5d                   	pop    %ebp
f0106147:	c3                   	ret    
f0106148:	90                   	nop
f0106149:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0106150:	89 d8                	mov    %ebx,%eax
f0106152:	f7 f7                	div    %edi
f0106154:	31 ff                	xor    %edi,%edi
f0106156:	89 c3                	mov    %eax,%ebx
f0106158:	89 d8                	mov    %ebx,%eax
f010615a:	89 fa                	mov    %edi,%edx
f010615c:	83 c4 1c             	add    $0x1c,%esp
f010615f:	5b                   	pop    %ebx
f0106160:	5e                   	pop    %esi
f0106161:	5f                   	pop    %edi
f0106162:	5d                   	pop    %ebp
f0106163:	c3                   	ret    
f0106164:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0106168:	39 ce                	cmp    %ecx,%esi
f010616a:	72 0c                	jb     f0106178 <__udivdi3+0x118>
f010616c:	31 db                	xor    %ebx,%ebx
f010616e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0106172:	0f 87 34 ff ff ff    	ja     f01060ac <__udivdi3+0x4c>
f0106178:	bb 01 00 00 00       	mov    $0x1,%ebx
f010617d:	e9 2a ff ff ff       	jmp    f01060ac <__udivdi3+0x4c>
f0106182:	66 90                	xchg   %ax,%ax
f0106184:	66 90                	xchg   %ax,%ax
f0106186:	66 90                	xchg   %ax,%ax
f0106188:	66 90                	xchg   %ax,%ax
f010618a:	66 90                	xchg   %ax,%ax
f010618c:	66 90                	xchg   %ax,%ax
f010618e:	66 90                	xchg   %ax,%ax

f0106190 <__umoddi3>:
f0106190:	55                   	push   %ebp
f0106191:	57                   	push   %edi
f0106192:	56                   	push   %esi
f0106193:	53                   	push   %ebx
f0106194:	83 ec 1c             	sub    $0x1c,%esp
f0106197:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010619b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010619f:	8b 74 24 34          	mov    0x34(%esp),%esi
f01061a3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01061a7:	85 d2                	test   %edx,%edx
f01061a9:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01061ad:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01061b1:	89 f3                	mov    %esi,%ebx
f01061b3:	89 3c 24             	mov    %edi,(%esp)
f01061b6:	89 74 24 04          	mov    %esi,0x4(%esp)
f01061ba:	75 1c                	jne    f01061d8 <__umoddi3+0x48>
f01061bc:	39 f7                	cmp    %esi,%edi
f01061be:	76 50                	jbe    f0106210 <__umoddi3+0x80>
f01061c0:	89 c8                	mov    %ecx,%eax
f01061c2:	89 f2                	mov    %esi,%edx
f01061c4:	f7 f7                	div    %edi
f01061c6:	89 d0                	mov    %edx,%eax
f01061c8:	31 d2                	xor    %edx,%edx
f01061ca:	83 c4 1c             	add    $0x1c,%esp
f01061cd:	5b                   	pop    %ebx
f01061ce:	5e                   	pop    %esi
f01061cf:	5f                   	pop    %edi
f01061d0:	5d                   	pop    %ebp
f01061d1:	c3                   	ret    
f01061d2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01061d8:	39 f2                	cmp    %esi,%edx
f01061da:	89 d0                	mov    %edx,%eax
f01061dc:	77 52                	ja     f0106230 <__umoddi3+0xa0>
f01061de:	0f bd ea             	bsr    %edx,%ebp
f01061e1:	83 f5 1f             	xor    $0x1f,%ebp
f01061e4:	75 5a                	jne    f0106240 <__umoddi3+0xb0>
f01061e6:	3b 54 24 04          	cmp    0x4(%esp),%edx
f01061ea:	0f 82 e0 00 00 00    	jb     f01062d0 <__umoddi3+0x140>
f01061f0:	39 0c 24             	cmp    %ecx,(%esp)
f01061f3:	0f 86 d7 00 00 00    	jbe    f01062d0 <__umoddi3+0x140>
f01061f9:	8b 44 24 08          	mov    0x8(%esp),%eax
f01061fd:	8b 54 24 04          	mov    0x4(%esp),%edx
f0106201:	83 c4 1c             	add    $0x1c,%esp
f0106204:	5b                   	pop    %ebx
f0106205:	5e                   	pop    %esi
f0106206:	5f                   	pop    %edi
f0106207:	5d                   	pop    %ebp
f0106208:	c3                   	ret    
f0106209:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0106210:	85 ff                	test   %edi,%edi
f0106212:	89 fd                	mov    %edi,%ebp
f0106214:	75 0b                	jne    f0106221 <__umoddi3+0x91>
f0106216:	b8 01 00 00 00       	mov    $0x1,%eax
f010621b:	31 d2                	xor    %edx,%edx
f010621d:	f7 f7                	div    %edi
f010621f:	89 c5                	mov    %eax,%ebp
f0106221:	89 f0                	mov    %esi,%eax
f0106223:	31 d2                	xor    %edx,%edx
f0106225:	f7 f5                	div    %ebp
f0106227:	89 c8                	mov    %ecx,%eax
f0106229:	f7 f5                	div    %ebp
f010622b:	89 d0                	mov    %edx,%eax
f010622d:	eb 99                	jmp    f01061c8 <__umoddi3+0x38>
f010622f:	90                   	nop
f0106230:	89 c8                	mov    %ecx,%eax
f0106232:	89 f2                	mov    %esi,%edx
f0106234:	83 c4 1c             	add    $0x1c,%esp
f0106237:	5b                   	pop    %ebx
f0106238:	5e                   	pop    %esi
f0106239:	5f                   	pop    %edi
f010623a:	5d                   	pop    %ebp
f010623b:	c3                   	ret    
f010623c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0106240:	8b 34 24             	mov    (%esp),%esi
f0106243:	bf 20 00 00 00       	mov    $0x20,%edi
f0106248:	89 e9                	mov    %ebp,%ecx
f010624a:	29 ef                	sub    %ebp,%edi
f010624c:	d3 e0                	shl    %cl,%eax
f010624e:	89 f9                	mov    %edi,%ecx
f0106250:	89 f2                	mov    %esi,%edx
f0106252:	d3 ea                	shr    %cl,%edx
f0106254:	89 e9                	mov    %ebp,%ecx
f0106256:	09 c2                	or     %eax,%edx
f0106258:	89 d8                	mov    %ebx,%eax
f010625a:	89 14 24             	mov    %edx,(%esp)
f010625d:	89 f2                	mov    %esi,%edx
f010625f:	d3 e2                	shl    %cl,%edx
f0106261:	89 f9                	mov    %edi,%ecx
f0106263:	89 54 24 04          	mov    %edx,0x4(%esp)
f0106267:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010626b:	d3 e8                	shr    %cl,%eax
f010626d:	89 e9                	mov    %ebp,%ecx
f010626f:	89 c6                	mov    %eax,%esi
f0106271:	d3 e3                	shl    %cl,%ebx
f0106273:	89 f9                	mov    %edi,%ecx
f0106275:	89 d0                	mov    %edx,%eax
f0106277:	d3 e8                	shr    %cl,%eax
f0106279:	89 e9                	mov    %ebp,%ecx
f010627b:	09 d8                	or     %ebx,%eax
f010627d:	89 d3                	mov    %edx,%ebx
f010627f:	89 f2                	mov    %esi,%edx
f0106281:	f7 34 24             	divl   (%esp)
f0106284:	89 d6                	mov    %edx,%esi
f0106286:	d3 e3                	shl    %cl,%ebx
f0106288:	f7 64 24 04          	mull   0x4(%esp)
f010628c:	39 d6                	cmp    %edx,%esi
f010628e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0106292:	89 d1                	mov    %edx,%ecx
f0106294:	89 c3                	mov    %eax,%ebx
f0106296:	72 08                	jb     f01062a0 <__umoddi3+0x110>
f0106298:	75 11                	jne    f01062ab <__umoddi3+0x11b>
f010629a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f010629e:	73 0b                	jae    f01062ab <__umoddi3+0x11b>
f01062a0:	2b 44 24 04          	sub    0x4(%esp),%eax
f01062a4:	1b 14 24             	sbb    (%esp),%edx
f01062a7:	89 d1                	mov    %edx,%ecx
f01062a9:	89 c3                	mov    %eax,%ebx
f01062ab:	8b 54 24 08          	mov    0x8(%esp),%edx
f01062af:	29 da                	sub    %ebx,%edx
f01062b1:	19 ce                	sbb    %ecx,%esi
f01062b3:	89 f9                	mov    %edi,%ecx
f01062b5:	89 f0                	mov    %esi,%eax
f01062b7:	d3 e0                	shl    %cl,%eax
f01062b9:	89 e9                	mov    %ebp,%ecx
f01062bb:	d3 ea                	shr    %cl,%edx
f01062bd:	89 e9                	mov    %ebp,%ecx
f01062bf:	d3 ee                	shr    %cl,%esi
f01062c1:	09 d0                	or     %edx,%eax
f01062c3:	89 f2                	mov    %esi,%edx
f01062c5:	83 c4 1c             	add    $0x1c,%esp
f01062c8:	5b                   	pop    %ebx
f01062c9:	5e                   	pop    %esi
f01062ca:	5f                   	pop    %edi
f01062cb:	5d                   	pop    %ebp
f01062cc:	c3                   	ret    
f01062cd:	8d 76 00             	lea    0x0(%esi),%esi
f01062d0:	29 f9                	sub    %edi,%ecx
f01062d2:	19 d6                	sbb    %edx,%esi
f01062d4:	89 74 24 04          	mov    %esi,0x4(%esp)
f01062d8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01062dc:	e9 18 ff ff ff       	jmp    f01061f9 <__umoddi3+0x69>
