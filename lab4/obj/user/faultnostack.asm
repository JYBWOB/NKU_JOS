
obj/user/faultnostack:     file format elf32-i386


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
  80002c:	e8 23 00 00 00       	call   800054 <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <umain>:

void _pgfault_upcall();

void
umain(int argc, char **argv)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
  800036:	83 ec 10             	sub    $0x10,%esp
	sys_env_set_pgfault_upcall(0, (void*) _pgfault_upcall);
  800039:	68 17 03 80 00       	push   $0x800317
  80003e:	6a 00                	push   $0x0
  800040:	e8 2c 02 00 00       	call   800271 <sys_env_set_pgfault_upcall>
	*(int*)0 = 0;
  800045:	c7 05 00 00 00 00 00 	movl   $0x0,0x0
  80004c:	00 00 00 
}
  80004f:	83 c4 10             	add    $0x10,%esp
  800052:	c9                   	leave  
  800053:	c3                   	ret    

00800054 <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  800054:	55                   	push   %ebp
  800055:	89 e5                	mov    %esp,%ebp
  800057:	56                   	push   %esi
  800058:	53                   	push   %ebx
  800059:	8b 5d 08             	mov    0x8(%ebp),%ebx
  80005c:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	//thisenv = 0;
	envid_t envid = sys_getenvid();
  80005f:	e8 c6 00 00 00       	call   80012a <sys_getenvid>
	thisenv = &envs[ENVX(envid)];
  800064:	25 ff 03 00 00       	and    $0x3ff,%eax
  800069:	6b c0 7c             	imul   $0x7c,%eax,%eax
  80006c:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  800071:	a3 04 20 80 00       	mov    %eax,0x802004
	// save the name of the program so that panic() can use it
	if (argc > 0)
  800076:	85 db                	test   %ebx,%ebx
  800078:	7e 07                	jle    800081 <libmain+0x2d>
		binaryname = argv[0];
  80007a:	8b 06                	mov    (%esi),%eax
  80007c:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  800081:	83 ec 08             	sub    $0x8,%esp
  800084:	56                   	push   %esi
  800085:	53                   	push   %ebx
  800086:	e8 a8 ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  80008b:	e8 0a 00 00 00       	call   80009a <exit>
}
  800090:	83 c4 10             	add    $0x10,%esp
  800093:	8d 65 f8             	lea    -0x8(%ebp),%esp
  800096:	5b                   	pop    %ebx
  800097:	5e                   	pop    %esi
  800098:	5d                   	pop    %ebp
  800099:	c3                   	ret    

0080009a <exit>:

#include <inc/lib.h>

void
exit(void)
{
  80009a:	55                   	push   %ebp
  80009b:	89 e5                	mov    %esp,%ebp
  80009d:	83 ec 14             	sub    $0x14,%esp
	sys_env_destroy(0);
  8000a0:	6a 00                	push   $0x0
  8000a2:	e8 42 00 00 00       	call   8000e9 <sys_env_destroy>
}
  8000a7:	83 c4 10             	add    $0x10,%esp
  8000aa:	c9                   	leave  
  8000ab:	c3                   	ret    

008000ac <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  8000ac:	55                   	push   %ebp
  8000ad:	89 e5                	mov    %esp,%ebp
  8000af:	57                   	push   %edi
  8000b0:	56                   	push   %esi
  8000b1:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000b2:	b8 00 00 00 00       	mov    $0x0,%eax
  8000b7:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8000ba:	8b 55 08             	mov    0x8(%ebp),%edx
  8000bd:	89 c3                	mov    %eax,%ebx
  8000bf:	89 c7                	mov    %eax,%edi
  8000c1:	89 c6                	mov    %eax,%esi
  8000c3:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  8000c5:	5b                   	pop    %ebx
  8000c6:	5e                   	pop    %esi
  8000c7:	5f                   	pop    %edi
  8000c8:	5d                   	pop    %ebp
  8000c9:	c3                   	ret    

008000ca <sys_cgetc>:

int
sys_cgetc(void)
{
  8000ca:	55                   	push   %ebp
  8000cb:	89 e5                	mov    %esp,%ebp
  8000cd:	57                   	push   %edi
  8000ce:	56                   	push   %esi
  8000cf:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000d0:	ba 00 00 00 00       	mov    $0x0,%edx
  8000d5:	b8 01 00 00 00       	mov    $0x1,%eax
  8000da:	89 d1                	mov    %edx,%ecx
  8000dc:	89 d3                	mov    %edx,%ebx
  8000de:	89 d7                	mov    %edx,%edi
  8000e0:	89 d6                	mov    %edx,%esi
  8000e2:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  8000e4:	5b                   	pop    %ebx
  8000e5:	5e                   	pop    %esi
  8000e6:	5f                   	pop    %edi
  8000e7:	5d                   	pop    %ebp
  8000e8:	c3                   	ret    

008000e9 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  8000e9:	55                   	push   %ebp
  8000ea:	89 e5                	mov    %esp,%ebp
  8000ec:	57                   	push   %edi
  8000ed:	56                   	push   %esi
  8000ee:	53                   	push   %ebx
  8000ef:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000f2:	b9 00 00 00 00       	mov    $0x0,%ecx
  8000f7:	b8 03 00 00 00       	mov    $0x3,%eax
  8000fc:	8b 55 08             	mov    0x8(%ebp),%edx
  8000ff:	89 cb                	mov    %ecx,%ebx
  800101:	89 cf                	mov    %ecx,%edi
  800103:	89 ce                	mov    %ecx,%esi
  800105:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800107:	85 c0                	test   %eax,%eax
  800109:	7e 17                	jle    800122 <sys_env_destroy+0x39>
		panic("syscall %d returned %d (> 0)", num, ret);
  80010b:	83 ec 0c             	sub    $0xc,%esp
  80010e:	50                   	push   %eax
  80010f:	6a 03                	push   $0x3
  800111:	68 8a 10 80 00       	push   $0x80108a
  800116:	6a 23                	push   $0x23
  800118:	68 a7 10 80 00       	push   $0x8010a7
  80011d:	e8 34 02 00 00       	call   800356 <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800122:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800125:	5b                   	pop    %ebx
  800126:	5e                   	pop    %esi
  800127:	5f                   	pop    %edi
  800128:	5d                   	pop    %ebp
  800129:	c3                   	ret    

0080012a <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  80012a:	55                   	push   %ebp
  80012b:	89 e5                	mov    %esp,%ebp
  80012d:	57                   	push   %edi
  80012e:	56                   	push   %esi
  80012f:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800130:	ba 00 00 00 00       	mov    $0x0,%edx
  800135:	b8 02 00 00 00       	mov    $0x2,%eax
  80013a:	89 d1                	mov    %edx,%ecx
  80013c:	89 d3                	mov    %edx,%ebx
  80013e:	89 d7                	mov    %edx,%edi
  800140:	89 d6                	mov    %edx,%esi
  800142:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800144:	5b                   	pop    %ebx
  800145:	5e                   	pop    %esi
  800146:	5f                   	pop    %edi
  800147:	5d                   	pop    %ebp
  800148:	c3                   	ret    

00800149 <sys_yield>:

void
sys_yield(void)
{
  800149:	55                   	push   %ebp
  80014a:	89 e5                	mov    %esp,%ebp
  80014c:	57                   	push   %edi
  80014d:	56                   	push   %esi
  80014e:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  80014f:	ba 00 00 00 00       	mov    $0x0,%edx
  800154:	b8 0a 00 00 00       	mov    $0xa,%eax
  800159:	89 d1                	mov    %edx,%ecx
  80015b:	89 d3                	mov    %edx,%ebx
  80015d:	89 d7                	mov    %edx,%edi
  80015f:	89 d6                	mov    %edx,%esi
  800161:	cd 30                	int    $0x30

void
sys_yield(void)
{
	syscall(SYS_yield, 0, 0, 0, 0, 0, 0);
}
  800163:	5b                   	pop    %ebx
  800164:	5e                   	pop    %esi
  800165:	5f                   	pop    %edi
  800166:	5d                   	pop    %ebp
  800167:	c3                   	ret    

00800168 <sys_page_alloc>:

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
  800168:	55                   	push   %ebp
  800169:	89 e5                	mov    %esp,%ebp
  80016b:	57                   	push   %edi
  80016c:	56                   	push   %esi
  80016d:	53                   	push   %ebx
  80016e:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800171:	be 00 00 00 00       	mov    $0x0,%esi
  800176:	b8 04 00 00 00       	mov    $0x4,%eax
  80017b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80017e:	8b 55 08             	mov    0x8(%ebp),%edx
  800181:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800184:	89 f7                	mov    %esi,%edi
  800186:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800188:	85 c0                	test   %eax,%eax
  80018a:	7e 17                	jle    8001a3 <sys_page_alloc+0x3b>
		panic("syscall %d returned %d (> 0)", num, ret);
  80018c:	83 ec 0c             	sub    $0xc,%esp
  80018f:	50                   	push   %eax
  800190:	6a 04                	push   $0x4
  800192:	68 8a 10 80 00       	push   $0x80108a
  800197:	6a 23                	push   $0x23
  800199:	68 a7 10 80 00       	push   $0x8010a7
  80019e:	e8 b3 01 00 00       	call   800356 <_panic>

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
	return syscall(SYS_page_alloc, 1, envid, (uint32_t) va, perm, 0, 0);
}
  8001a3:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8001a6:	5b                   	pop    %ebx
  8001a7:	5e                   	pop    %esi
  8001a8:	5f                   	pop    %edi
  8001a9:	5d                   	pop    %ebp
  8001aa:	c3                   	ret    

008001ab <sys_page_map>:

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
  8001ab:	55                   	push   %ebp
  8001ac:	89 e5                	mov    %esp,%ebp
  8001ae:	57                   	push   %edi
  8001af:	56                   	push   %esi
  8001b0:	53                   	push   %ebx
  8001b1:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8001b4:	b8 05 00 00 00       	mov    $0x5,%eax
  8001b9:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8001bc:	8b 55 08             	mov    0x8(%ebp),%edx
  8001bf:	8b 5d 10             	mov    0x10(%ebp),%ebx
  8001c2:	8b 7d 14             	mov    0x14(%ebp),%edi
  8001c5:	8b 75 18             	mov    0x18(%ebp),%esi
  8001c8:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  8001ca:	85 c0                	test   %eax,%eax
  8001cc:	7e 17                	jle    8001e5 <sys_page_map+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  8001ce:	83 ec 0c             	sub    $0xc,%esp
  8001d1:	50                   	push   %eax
  8001d2:	6a 05                	push   $0x5
  8001d4:	68 8a 10 80 00       	push   $0x80108a
  8001d9:	6a 23                	push   $0x23
  8001db:	68 a7 10 80 00       	push   $0x8010a7
  8001e0:	e8 71 01 00 00       	call   800356 <_panic>

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
	return syscall(SYS_page_map, 1, srcenv, (uint32_t) srcva, dstenv, (uint32_t) dstva, perm);
}
  8001e5:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8001e8:	5b                   	pop    %ebx
  8001e9:	5e                   	pop    %esi
  8001ea:	5f                   	pop    %edi
  8001eb:	5d                   	pop    %ebp
  8001ec:	c3                   	ret    

008001ed <sys_page_unmap>:

int
sys_page_unmap(envid_t envid, void *va)
{
  8001ed:	55                   	push   %ebp
  8001ee:	89 e5                	mov    %esp,%ebp
  8001f0:	57                   	push   %edi
  8001f1:	56                   	push   %esi
  8001f2:	53                   	push   %ebx
  8001f3:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8001f6:	bb 00 00 00 00       	mov    $0x0,%ebx
  8001fb:	b8 06 00 00 00       	mov    $0x6,%eax
  800200:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800203:	8b 55 08             	mov    0x8(%ebp),%edx
  800206:	89 df                	mov    %ebx,%edi
  800208:	89 de                	mov    %ebx,%esi
  80020a:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  80020c:	85 c0                	test   %eax,%eax
  80020e:	7e 17                	jle    800227 <sys_page_unmap+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800210:	83 ec 0c             	sub    $0xc,%esp
  800213:	50                   	push   %eax
  800214:	6a 06                	push   $0x6
  800216:	68 8a 10 80 00       	push   $0x80108a
  80021b:	6a 23                	push   $0x23
  80021d:	68 a7 10 80 00       	push   $0x8010a7
  800222:	e8 2f 01 00 00       	call   800356 <_panic>

int
sys_page_unmap(envid_t envid, void *va)
{
	return syscall(SYS_page_unmap, 1, envid, (uint32_t) va, 0, 0, 0);
}
  800227:	8d 65 f4             	lea    -0xc(%ebp),%esp
  80022a:	5b                   	pop    %ebx
  80022b:	5e                   	pop    %esi
  80022c:	5f                   	pop    %edi
  80022d:	5d                   	pop    %ebp
  80022e:	c3                   	ret    

0080022f <sys_env_set_status>:

// sys_exofork is inlined in lib.h

int
sys_env_set_status(envid_t envid, int status)
{
  80022f:	55                   	push   %ebp
  800230:	89 e5                	mov    %esp,%ebp
  800232:	57                   	push   %edi
  800233:	56                   	push   %esi
  800234:	53                   	push   %ebx
  800235:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800238:	bb 00 00 00 00       	mov    $0x0,%ebx
  80023d:	b8 08 00 00 00       	mov    $0x8,%eax
  800242:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800245:	8b 55 08             	mov    0x8(%ebp),%edx
  800248:	89 df                	mov    %ebx,%edi
  80024a:	89 de                	mov    %ebx,%esi
  80024c:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  80024e:	85 c0                	test   %eax,%eax
  800250:	7e 17                	jle    800269 <sys_env_set_status+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800252:	83 ec 0c             	sub    $0xc,%esp
  800255:	50                   	push   %eax
  800256:	6a 08                	push   $0x8
  800258:	68 8a 10 80 00       	push   $0x80108a
  80025d:	6a 23                	push   $0x23
  80025f:	68 a7 10 80 00       	push   $0x8010a7
  800264:	e8 ed 00 00 00       	call   800356 <_panic>

int
sys_env_set_status(envid_t envid, int status)
{
	return syscall(SYS_env_set_status, 1, envid, status, 0, 0, 0);
}
  800269:	8d 65 f4             	lea    -0xc(%ebp),%esp
  80026c:	5b                   	pop    %ebx
  80026d:	5e                   	pop    %esi
  80026e:	5f                   	pop    %edi
  80026f:	5d                   	pop    %ebp
  800270:	c3                   	ret    

00800271 <sys_env_set_pgfault_upcall>:

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
  800271:	55                   	push   %ebp
  800272:	89 e5                	mov    %esp,%ebp
  800274:	57                   	push   %edi
  800275:	56                   	push   %esi
  800276:	53                   	push   %ebx
  800277:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  80027a:	bb 00 00 00 00       	mov    $0x0,%ebx
  80027f:	b8 09 00 00 00       	mov    $0x9,%eax
  800284:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800287:	8b 55 08             	mov    0x8(%ebp),%edx
  80028a:	89 df                	mov    %ebx,%edi
  80028c:	89 de                	mov    %ebx,%esi
  80028e:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800290:	85 c0                	test   %eax,%eax
  800292:	7e 17                	jle    8002ab <sys_env_set_pgfault_upcall+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800294:	83 ec 0c             	sub    $0xc,%esp
  800297:	50                   	push   %eax
  800298:	6a 09                	push   $0x9
  80029a:	68 8a 10 80 00       	push   $0x80108a
  80029f:	6a 23                	push   $0x23
  8002a1:	68 a7 10 80 00       	push   $0x8010a7
  8002a6:	e8 ab 00 00 00       	call   800356 <_panic>

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
	return syscall(SYS_env_set_pgfault_upcall, 1, envid, (uint32_t) upcall, 0, 0, 0);
}
  8002ab:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8002ae:	5b                   	pop    %ebx
  8002af:	5e                   	pop    %esi
  8002b0:	5f                   	pop    %edi
  8002b1:	5d                   	pop    %ebp
  8002b2:	c3                   	ret    

008002b3 <sys_ipc_try_send>:

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
  8002b3:	55                   	push   %ebp
  8002b4:	89 e5                	mov    %esp,%ebp
  8002b6:	57                   	push   %edi
  8002b7:	56                   	push   %esi
  8002b8:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8002b9:	be 00 00 00 00       	mov    $0x0,%esi
  8002be:	b8 0b 00 00 00       	mov    $0xb,%eax
  8002c3:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8002c6:	8b 55 08             	mov    0x8(%ebp),%edx
  8002c9:	8b 5d 10             	mov    0x10(%ebp),%ebx
  8002cc:	8b 7d 14             	mov    0x14(%ebp),%edi
  8002cf:	cd 30                	int    $0x30

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
	return syscall(SYS_ipc_try_send, 0, envid, value, (uint32_t) srcva, perm, 0);
}
  8002d1:	5b                   	pop    %ebx
  8002d2:	5e                   	pop    %esi
  8002d3:	5f                   	pop    %edi
  8002d4:	5d                   	pop    %ebp
  8002d5:	c3                   	ret    

008002d6 <sys_ipc_recv>:

int
sys_ipc_recv(void *dstva)
{
  8002d6:	55                   	push   %ebp
  8002d7:	89 e5                	mov    %esp,%ebp
  8002d9:	57                   	push   %edi
  8002da:	56                   	push   %esi
  8002db:	53                   	push   %ebx
  8002dc:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8002df:	b9 00 00 00 00       	mov    $0x0,%ecx
  8002e4:	b8 0c 00 00 00       	mov    $0xc,%eax
  8002e9:	8b 55 08             	mov    0x8(%ebp),%edx
  8002ec:	89 cb                	mov    %ecx,%ebx
  8002ee:	89 cf                	mov    %ecx,%edi
  8002f0:	89 ce                	mov    %ecx,%esi
  8002f2:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  8002f4:	85 c0                	test   %eax,%eax
  8002f6:	7e 17                	jle    80030f <sys_ipc_recv+0x39>
		panic("syscall %d returned %d (> 0)", num, ret);
  8002f8:	83 ec 0c             	sub    $0xc,%esp
  8002fb:	50                   	push   %eax
  8002fc:	6a 0c                	push   $0xc
  8002fe:	68 8a 10 80 00       	push   $0x80108a
  800303:	6a 23                	push   $0x23
  800305:	68 a7 10 80 00       	push   $0x8010a7
  80030a:	e8 47 00 00 00       	call   800356 <_panic>

int
sys_ipc_recv(void *dstva)
{
	return syscall(SYS_ipc_recv, 1, (uint32_t)dstva, 0, 0, 0, 0);
}
  80030f:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800312:	5b                   	pop    %ebx
  800313:	5e                   	pop    %esi
  800314:	5f                   	pop    %edi
  800315:	5d                   	pop    %ebp
  800316:	c3                   	ret    

00800317 <_pgfault_upcall>:

.text
.globl _pgfault_upcall
_pgfault_upcall:
	// Call the C page fault handler.
	pushl %esp			// function argument: pointer to UTF
  800317:	54                   	push   %esp
	movl _pgfault_handler, %eax
  800318:	a1 08 20 80 00       	mov    0x802008,%eax
	call *%eax
  80031d:	ff d0                	call   *%eax
	addl $4, %esp			// pop function argument
  80031f:	83 c4 04             	add    $0x4,%esp

	// Restore the trap-time registers.  After you do this, you
	// can no longer modify any general-purpose registers.
	// LAB 4: Your code here.
	//	trap-eip -> eax
		movl 0x28(%esp), %eax
  800322:	8b 44 24 28          	mov    0x28(%esp),%eax
	//	trap-ebp-> ebx		
		movl 0x10(%esp), %ebx
  800326:	8b 5c 24 10          	mov    0x10(%esp),%ebx
	//  trap->esp -> ecx 
		movl 0x30(%esp), %ecx
  80032a:	8b 4c 24 30          	mov    0x30(%esp),%ecx

		movl %eax, -0x4(%ecx)
  80032e:	89 41 fc             	mov    %eax,-0x4(%ecx)
		movl %ebx, -0x8(%ecx)
  800331:	89 59 f8             	mov    %ebx,-0x8(%ecx)

		leal -0x8(%ecx), %ebp
  800334:	8d 69 f8             	lea    -0x8(%ecx),%ebp

		movl 0x8(%esp), %edi
  800337:	8b 7c 24 08          	mov    0x8(%esp),%edi
		movl 0xc(%esp),	%esi
  80033b:	8b 74 24 0c          	mov    0xc(%esp),%esi
		movl 0x18(%esp),%ebx
  80033f:	8b 5c 24 18          	mov    0x18(%esp),%ebx
		movl 0x1c(%esp),%edx
  800343:	8b 54 24 1c          	mov    0x1c(%esp),%edx
		movl 0x20(%esp),%ecx
  800347:	8b 4c 24 20          	mov    0x20(%esp),%ecx
		movl 0x24(%esp),%eax
  80034b:	8b 44 24 24          	mov    0x24(%esp),%eax

	// Restore eflags from the stack.  After you do this, you can
	// no longer use arithmetic operations or anything else that
	// modifies eflags.
	// LAB 4: Your code here.
		leal 0x2c(%esp), %esp
  80034f:	8d 64 24 2c          	lea    0x2c(%esp),%esp
		popf
  800353:	9d                   	popf   
	// Switch back to the adjusted trap-time stack.
	// LAB 4: Your code here.
		leave
  800354:	c9                   	leave  
	// Return to re-execute the instruction that faulted.
	// LAB 4: Your code here.
  800355:	c3                   	ret    

00800356 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800356:	55                   	push   %ebp
  800357:	89 e5                	mov    %esp,%ebp
  800359:	56                   	push   %esi
  80035a:	53                   	push   %ebx
	va_list ap;

	va_start(ap, fmt);
  80035b:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  80035e:	8b 35 00 20 80 00    	mov    0x802000,%esi
  800364:	e8 c1 fd ff ff       	call   80012a <sys_getenvid>
  800369:	83 ec 0c             	sub    $0xc,%esp
  80036c:	ff 75 0c             	pushl  0xc(%ebp)
  80036f:	ff 75 08             	pushl  0x8(%ebp)
  800372:	56                   	push   %esi
  800373:	50                   	push   %eax
  800374:	68 b8 10 80 00       	push   $0x8010b8
  800379:	e8 b1 00 00 00       	call   80042f <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  80037e:	83 c4 18             	add    $0x18,%esp
  800381:	53                   	push   %ebx
  800382:	ff 75 10             	pushl  0x10(%ebp)
  800385:	e8 54 00 00 00       	call   8003de <vcprintf>
	cprintf("\n");
  80038a:	c7 04 24 db 10 80 00 	movl   $0x8010db,(%esp)
  800391:	e8 99 00 00 00       	call   80042f <cprintf>
  800396:	83 c4 10             	add    $0x10,%esp

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  800399:	cc                   	int3   
  80039a:	eb fd                	jmp    800399 <_panic+0x43>

0080039c <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  80039c:	55                   	push   %ebp
  80039d:	89 e5                	mov    %esp,%ebp
  80039f:	53                   	push   %ebx
  8003a0:	83 ec 04             	sub    $0x4,%esp
  8003a3:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  8003a6:	8b 13                	mov    (%ebx),%edx
  8003a8:	8d 42 01             	lea    0x1(%edx),%eax
  8003ab:	89 03                	mov    %eax,(%ebx)
  8003ad:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8003b0:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  8003b4:	3d ff 00 00 00       	cmp    $0xff,%eax
  8003b9:	75 1a                	jne    8003d5 <putch+0x39>
		sys_cputs(b->buf, b->idx);
  8003bb:	83 ec 08             	sub    $0x8,%esp
  8003be:	68 ff 00 00 00       	push   $0xff
  8003c3:	8d 43 08             	lea    0x8(%ebx),%eax
  8003c6:	50                   	push   %eax
  8003c7:	e8 e0 fc ff ff       	call   8000ac <sys_cputs>
		b->idx = 0;
  8003cc:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  8003d2:	83 c4 10             	add    $0x10,%esp
	}
	b->cnt++;
  8003d5:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8003d9:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8003dc:	c9                   	leave  
  8003dd:	c3                   	ret    

008003de <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8003de:	55                   	push   %ebp
  8003df:	89 e5                	mov    %esp,%ebp
  8003e1:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  8003e7:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  8003ee:	00 00 00 
	b.cnt = 0;
  8003f1:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  8003f8:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  8003fb:	ff 75 0c             	pushl  0xc(%ebp)
  8003fe:	ff 75 08             	pushl  0x8(%ebp)
  800401:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  800407:	50                   	push   %eax
  800408:	68 9c 03 80 00       	push   $0x80039c
  80040d:	e8 1a 01 00 00       	call   80052c <vprintfmt>
	sys_cputs(b.buf, b.idx);
  800412:	83 c4 08             	add    $0x8,%esp
  800415:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
  80041b:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  800421:	50                   	push   %eax
  800422:	e8 85 fc ff ff       	call   8000ac <sys_cputs>

	return b.cnt;
}
  800427:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  80042d:	c9                   	leave  
  80042e:	c3                   	ret    

0080042f <cprintf>:

int
cprintf(const char *fmt, ...)
{
  80042f:	55                   	push   %ebp
  800430:	89 e5                	mov    %esp,%ebp
  800432:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  800435:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  800438:	50                   	push   %eax
  800439:	ff 75 08             	pushl  0x8(%ebp)
  80043c:	e8 9d ff ff ff       	call   8003de <vcprintf>
	va_end(ap);

	return cnt;
}
  800441:	c9                   	leave  
  800442:	c3                   	ret    

00800443 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  800443:	55                   	push   %ebp
  800444:	89 e5                	mov    %esp,%ebp
  800446:	57                   	push   %edi
  800447:	56                   	push   %esi
  800448:	53                   	push   %ebx
  800449:	83 ec 1c             	sub    $0x1c,%esp
  80044c:	89 c7                	mov    %eax,%edi
  80044e:	89 d6                	mov    %edx,%esi
  800450:	8b 45 08             	mov    0x8(%ebp),%eax
  800453:	8b 55 0c             	mov    0xc(%ebp),%edx
  800456:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800459:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  80045c:	8b 4d 10             	mov    0x10(%ebp),%ecx
  80045f:	bb 00 00 00 00       	mov    $0x0,%ebx
  800464:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  800467:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  80046a:	39 d3                	cmp    %edx,%ebx
  80046c:	72 05                	jb     800473 <printnum+0x30>
  80046e:	39 45 10             	cmp    %eax,0x10(%ebp)
  800471:	77 45                	ja     8004b8 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  800473:	83 ec 0c             	sub    $0xc,%esp
  800476:	ff 75 18             	pushl  0x18(%ebp)
  800479:	8b 45 14             	mov    0x14(%ebp),%eax
  80047c:	8d 58 ff             	lea    -0x1(%eax),%ebx
  80047f:	53                   	push   %ebx
  800480:	ff 75 10             	pushl  0x10(%ebp)
  800483:	83 ec 08             	sub    $0x8,%esp
  800486:	ff 75 e4             	pushl  -0x1c(%ebp)
  800489:	ff 75 e0             	pushl  -0x20(%ebp)
  80048c:	ff 75 dc             	pushl  -0x24(%ebp)
  80048f:	ff 75 d8             	pushl  -0x28(%ebp)
  800492:	e8 59 09 00 00       	call   800df0 <__udivdi3>
  800497:	83 c4 18             	add    $0x18,%esp
  80049a:	52                   	push   %edx
  80049b:	50                   	push   %eax
  80049c:	89 f2                	mov    %esi,%edx
  80049e:	89 f8                	mov    %edi,%eax
  8004a0:	e8 9e ff ff ff       	call   800443 <printnum>
  8004a5:	83 c4 20             	add    $0x20,%esp
  8004a8:	eb 18                	jmp    8004c2 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  8004aa:	83 ec 08             	sub    $0x8,%esp
  8004ad:	56                   	push   %esi
  8004ae:	ff 75 18             	pushl  0x18(%ebp)
  8004b1:	ff d7                	call   *%edi
  8004b3:	83 c4 10             	add    $0x10,%esp
  8004b6:	eb 03                	jmp    8004bb <printnum+0x78>
  8004b8:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  8004bb:	83 eb 01             	sub    $0x1,%ebx
  8004be:	85 db                	test   %ebx,%ebx
  8004c0:	7f e8                	jg     8004aa <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  8004c2:	83 ec 08             	sub    $0x8,%esp
  8004c5:	56                   	push   %esi
  8004c6:	83 ec 04             	sub    $0x4,%esp
  8004c9:	ff 75 e4             	pushl  -0x1c(%ebp)
  8004cc:	ff 75 e0             	pushl  -0x20(%ebp)
  8004cf:	ff 75 dc             	pushl  -0x24(%ebp)
  8004d2:	ff 75 d8             	pushl  -0x28(%ebp)
  8004d5:	e8 46 0a 00 00       	call   800f20 <__umoddi3>
  8004da:	83 c4 14             	add    $0x14,%esp
  8004dd:	0f be 80 dd 10 80 00 	movsbl 0x8010dd(%eax),%eax
  8004e4:	50                   	push   %eax
  8004e5:	ff d7                	call   *%edi
}
  8004e7:	83 c4 10             	add    $0x10,%esp
  8004ea:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8004ed:	5b                   	pop    %ebx
  8004ee:	5e                   	pop    %esi
  8004ef:	5f                   	pop    %edi
  8004f0:	5d                   	pop    %ebp
  8004f1:	c3                   	ret    

008004f2 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  8004f2:	55                   	push   %ebp
  8004f3:	89 e5                	mov    %esp,%ebp
  8004f5:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  8004f8:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  8004fc:	8b 10                	mov    (%eax),%edx
  8004fe:	3b 50 04             	cmp    0x4(%eax),%edx
  800501:	73 0a                	jae    80050d <sprintputch+0x1b>
		*b->buf++ = ch;
  800503:	8d 4a 01             	lea    0x1(%edx),%ecx
  800506:	89 08                	mov    %ecx,(%eax)
  800508:	8b 45 08             	mov    0x8(%ebp),%eax
  80050b:	88 02                	mov    %al,(%edx)
}
  80050d:	5d                   	pop    %ebp
  80050e:	c3                   	ret    

0080050f <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  80050f:	55                   	push   %ebp
  800510:	89 e5                	mov    %esp,%ebp
  800512:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
  800515:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  800518:	50                   	push   %eax
  800519:	ff 75 10             	pushl  0x10(%ebp)
  80051c:	ff 75 0c             	pushl  0xc(%ebp)
  80051f:	ff 75 08             	pushl  0x8(%ebp)
  800522:	e8 05 00 00 00       	call   80052c <vprintfmt>
	va_end(ap);
}
  800527:	83 c4 10             	add    $0x10,%esp
  80052a:	c9                   	leave  
  80052b:	c3                   	ret    

0080052c <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  80052c:	55                   	push   %ebp
  80052d:	89 e5                	mov    %esp,%ebp
  80052f:	57                   	push   %edi
  800530:	56                   	push   %esi
  800531:	53                   	push   %ebx
  800532:	83 ec 2c             	sub    $0x2c,%esp
  800535:	8b 75 08             	mov    0x8(%ebp),%esi
  800538:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  80053b:	8b 7d 10             	mov    0x10(%ebp),%edi
  80053e:	eb 12                	jmp    800552 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  800540:	85 c0                	test   %eax,%eax
  800542:	0f 84 42 04 00 00    	je     80098a <vprintfmt+0x45e>
				return;
			putch(ch, putdat);
  800548:	83 ec 08             	sub    $0x8,%esp
  80054b:	53                   	push   %ebx
  80054c:	50                   	push   %eax
  80054d:	ff d6                	call   *%esi
  80054f:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  800552:	83 c7 01             	add    $0x1,%edi
  800555:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  800559:	83 f8 25             	cmp    $0x25,%eax
  80055c:	75 e2                	jne    800540 <vprintfmt+0x14>
  80055e:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
  800562:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  800569:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  800570:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
  800577:	b9 00 00 00 00       	mov    $0x0,%ecx
  80057c:	eb 07                	jmp    800585 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80057e:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  800581:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800585:	8d 47 01             	lea    0x1(%edi),%eax
  800588:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  80058b:	0f b6 07             	movzbl (%edi),%eax
  80058e:	0f b6 d0             	movzbl %al,%edx
  800591:	83 e8 23             	sub    $0x23,%eax
  800594:	3c 55                	cmp    $0x55,%al
  800596:	0f 87 d3 03 00 00    	ja     80096f <vprintfmt+0x443>
  80059c:	0f b6 c0             	movzbl %al,%eax
  80059f:	ff 24 85 a0 11 80 00 	jmp    *0x8011a0(,%eax,4)
  8005a6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  8005a9:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  8005ad:	eb d6                	jmp    800585 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005af:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8005b2:	b8 00 00 00 00       	mov    $0x0,%eax
  8005b7:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  8005ba:	8d 04 80             	lea    (%eax,%eax,4),%eax
  8005bd:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
  8005c1:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
  8005c4:	8d 4a d0             	lea    -0x30(%edx),%ecx
  8005c7:	83 f9 09             	cmp    $0x9,%ecx
  8005ca:	77 3f                	ja     80060b <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  8005cc:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  8005cf:	eb e9                	jmp    8005ba <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  8005d1:	8b 45 14             	mov    0x14(%ebp),%eax
  8005d4:	8b 00                	mov    (%eax),%eax
  8005d6:	89 45 d0             	mov    %eax,-0x30(%ebp)
  8005d9:	8b 45 14             	mov    0x14(%ebp),%eax
  8005dc:	8d 40 04             	lea    0x4(%eax),%eax
  8005df:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005e2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  8005e5:	eb 2a                	jmp    800611 <vprintfmt+0xe5>
  8005e7:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8005ea:	85 c0                	test   %eax,%eax
  8005ec:	ba 00 00 00 00       	mov    $0x0,%edx
  8005f1:	0f 49 d0             	cmovns %eax,%edx
  8005f4:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005f7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8005fa:	eb 89                	jmp    800585 <vprintfmt+0x59>
  8005fc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  8005ff:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  800606:	e9 7a ff ff ff       	jmp    800585 <vprintfmt+0x59>
  80060b:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  80060e:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
  800611:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800615:	0f 89 6a ff ff ff    	jns    800585 <vprintfmt+0x59>
				width = precision, precision = -1;
  80061b:	8b 45 d0             	mov    -0x30(%ebp),%eax
  80061e:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800621:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  800628:	e9 58 ff ff ff       	jmp    800585 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  80062d:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800630:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  800633:	e9 4d ff ff ff       	jmp    800585 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  800638:	8b 45 14             	mov    0x14(%ebp),%eax
  80063b:	8d 78 04             	lea    0x4(%eax),%edi
  80063e:	83 ec 08             	sub    $0x8,%esp
  800641:	53                   	push   %ebx
  800642:	ff 30                	pushl  (%eax)
  800644:	ff d6                	call   *%esi
			break;
  800646:	83 c4 10             	add    $0x10,%esp
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  800649:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80064c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  80064f:	e9 fe fe ff ff       	jmp    800552 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
  800654:	8b 45 14             	mov    0x14(%ebp),%eax
  800657:	8d 78 04             	lea    0x4(%eax),%edi
  80065a:	8b 00                	mov    (%eax),%eax
  80065c:	99                   	cltd   
  80065d:	31 d0                	xor    %edx,%eax
  80065f:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  800661:	83 f8 09             	cmp    $0x9,%eax
  800664:	7f 0b                	jg     800671 <vprintfmt+0x145>
  800666:	8b 14 85 00 13 80 00 	mov    0x801300(,%eax,4),%edx
  80066d:	85 d2                	test   %edx,%edx
  80066f:	75 1b                	jne    80068c <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
  800671:	50                   	push   %eax
  800672:	68 f5 10 80 00       	push   $0x8010f5
  800677:	53                   	push   %ebx
  800678:	56                   	push   %esi
  800679:	e8 91 fe ff ff       	call   80050f <printfmt>
  80067e:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
  800681:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800684:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  800687:	e9 c6 fe ff ff       	jmp    800552 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
  80068c:	52                   	push   %edx
  80068d:	68 fe 10 80 00       	push   $0x8010fe
  800692:	53                   	push   %ebx
  800693:	56                   	push   %esi
  800694:	e8 76 fe ff ff       	call   80050f <printfmt>
  800699:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
  80069c:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80069f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8006a2:	e9 ab fe ff ff       	jmp    800552 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  8006a7:	8b 45 14             	mov    0x14(%ebp),%eax
  8006aa:	83 c0 04             	add    $0x4,%eax
  8006ad:	89 45 cc             	mov    %eax,-0x34(%ebp)
  8006b0:	8b 45 14             	mov    0x14(%ebp),%eax
  8006b3:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  8006b5:	85 ff                	test   %edi,%edi
  8006b7:	b8 ee 10 80 00       	mov    $0x8010ee,%eax
  8006bc:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  8006bf:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  8006c3:	0f 8e 94 00 00 00    	jle    80075d <vprintfmt+0x231>
  8006c9:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  8006cd:	0f 84 98 00 00 00    	je     80076b <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
  8006d3:	83 ec 08             	sub    $0x8,%esp
  8006d6:	ff 75 d0             	pushl  -0x30(%ebp)
  8006d9:	57                   	push   %edi
  8006da:	e8 33 03 00 00       	call   800a12 <strnlen>
  8006df:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  8006e2:	29 c1                	sub    %eax,%ecx
  8006e4:	89 4d c8             	mov    %ecx,-0x38(%ebp)
  8006e7:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  8006ea:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  8006ee:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8006f1:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  8006f4:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8006f6:	eb 0f                	jmp    800707 <vprintfmt+0x1db>
					putch(padc, putdat);
  8006f8:	83 ec 08             	sub    $0x8,%esp
  8006fb:	53                   	push   %ebx
  8006fc:	ff 75 e0             	pushl  -0x20(%ebp)
  8006ff:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800701:	83 ef 01             	sub    $0x1,%edi
  800704:	83 c4 10             	add    $0x10,%esp
  800707:	85 ff                	test   %edi,%edi
  800709:	7f ed                	jg     8006f8 <vprintfmt+0x1cc>
  80070b:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  80070e:	8b 4d c8             	mov    -0x38(%ebp),%ecx
  800711:	85 c9                	test   %ecx,%ecx
  800713:	b8 00 00 00 00       	mov    $0x0,%eax
  800718:	0f 49 c1             	cmovns %ecx,%eax
  80071b:	29 c1                	sub    %eax,%ecx
  80071d:	89 75 08             	mov    %esi,0x8(%ebp)
  800720:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800723:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800726:	89 cb                	mov    %ecx,%ebx
  800728:	eb 4d                	jmp    800777 <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  80072a:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  80072e:	74 1b                	je     80074b <vprintfmt+0x21f>
  800730:	0f be c0             	movsbl %al,%eax
  800733:	83 e8 20             	sub    $0x20,%eax
  800736:	83 f8 5e             	cmp    $0x5e,%eax
  800739:	76 10                	jbe    80074b <vprintfmt+0x21f>
					putch('?', putdat);
  80073b:	83 ec 08             	sub    $0x8,%esp
  80073e:	ff 75 0c             	pushl  0xc(%ebp)
  800741:	6a 3f                	push   $0x3f
  800743:	ff 55 08             	call   *0x8(%ebp)
  800746:	83 c4 10             	add    $0x10,%esp
  800749:	eb 0d                	jmp    800758 <vprintfmt+0x22c>
				else
					putch(ch, putdat);
  80074b:	83 ec 08             	sub    $0x8,%esp
  80074e:	ff 75 0c             	pushl  0xc(%ebp)
  800751:	52                   	push   %edx
  800752:	ff 55 08             	call   *0x8(%ebp)
  800755:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800758:	83 eb 01             	sub    $0x1,%ebx
  80075b:	eb 1a                	jmp    800777 <vprintfmt+0x24b>
  80075d:	89 75 08             	mov    %esi,0x8(%ebp)
  800760:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800763:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800766:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800769:	eb 0c                	jmp    800777 <vprintfmt+0x24b>
  80076b:	89 75 08             	mov    %esi,0x8(%ebp)
  80076e:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800771:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800774:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800777:	83 c7 01             	add    $0x1,%edi
  80077a:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  80077e:	0f be d0             	movsbl %al,%edx
  800781:	85 d2                	test   %edx,%edx
  800783:	74 23                	je     8007a8 <vprintfmt+0x27c>
  800785:	85 f6                	test   %esi,%esi
  800787:	78 a1                	js     80072a <vprintfmt+0x1fe>
  800789:	83 ee 01             	sub    $0x1,%esi
  80078c:	79 9c                	jns    80072a <vprintfmt+0x1fe>
  80078e:	89 df                	mov    %ebx,%edi
  800790:	8b 75 08             	mov    0x8(%ebp),%esi
  800793:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800796:	eb 18                	jmp    8007b0 <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  800798:	83 ec 08             	sub    $0x8,%esp
  80079b:	53                   	push   %ebx
  80079c:	6a 20                	push   $0x20
  80079e:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  8007a0:	83 ef 01             	sub    $0x1,%edi
  8007a3:	83 c4 10             	add    $0x10,%esp
  8007a6:	eb 08                	jmp    8007b0 <vprintfmt+0x284>
  8007a8:	89 df                	mov    %ebx,%edi
  8007aa:	8b 75 08             	mov    0x8(%ebp),%esi
  8007ad:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8007b0:	85 ff                	test   %edi,%edi
  8007b2:	7f e4                	jg     800798 <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  8007b4:	8b 45 cc             	mov    -0x34(%ebp),%eax
  8007b7:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8007ba:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8007bd:	e9 90 fd ff ff       	jmp    800552 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  8007c2:	83 f9 01             	cmp    $0x1,%ecx
  8007c5:	7e 19                	jle    8007e0 <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
  8007c7:	8b 45 14             	mov    0x14(%ebp),%eax
  8007ca:	8b 50 04             	mov    0x4(%eax),%edx
  8007cd:	8b 00                	mov    (%eax),%eax
  8007cf:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8007d2:	89 55 dc             	mov    %edx,-0x24(%ebp)
  8007d5:	8b 45 14             	mov    0x14(%ebp),%eax
  8007d8:	8d 40 08             	lea    0x8(%eax),%eax
  8007db:	89 45 14             	mov    %eax,0x14(%ebp)
  8007de:	eb 38                	jmp    800818 <vprintfmt+0x2ec>
	else if (lflag)
  8007e0:	85 c9                	test   %ecx,%ecx
  8007e2:	74 1b                	je     8007ff <vprintfmt+0x2d3>
		return va_arg(*ap, long);
  8007e4:	8b 45 14             	mov    0x14(%ebp),%eax
  8007e7:	8b 00                	mov    (%eax),%eax
  8007e9:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8007ec:	89 c1                	mov    %eax,%ecx
  8007ee:	c1 f9 1f             	sar    $0x1f,%ecx
  8007f1:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  8007f4:	8b 45 14             	mov    0x14(%ebp),%eax
  8007f7:	8d 40 04             	lea    0x4(%eax),%eax
  8007fa:	89 45 14             	mov    %eax,0x14(%ebp)
  8007fd:	eb 19                	jmp    800818 <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
  8007ff:	8b 45 14             	mov    0x14(%ebp),%eax
  800802:	8b 00                	mov    (%eax),%eax
  800804:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800807:	89 c1                	mov    %eax,%ecx
  800809:	c1 f9 1f             	sar    $0x1f,%ecx
  80080c:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  80080f:	8b 45 14             	mov    0x14(%ebp),%eax
  800812:	8d 40 04             	lea    0x4(%eax),%eax
  800815:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  800818:	8b 55 d8             	mov    -0x28(%ebp),%edx
  80081b:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  80081e:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  800823:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  800827:	0f 89 0e 01 00 00    	jns    80093b <vprintfmt+0x40f>
				putch('-', putdat);
  80082d:	83 ec 08             	sub    $0x8,%esp
  800830:	53                   	push   %ebx
  800831:	6a 2d                	push   $0x2d
  800833:	ff d6                	call   *%esi
				num = -(long long) num;
  800835:	8b 55 d8             	mov    -0x28(%ebp),%edx
  800838:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  80083b:	f7 da                	neg    %edx
  80083d:	83 d1 00             	adc    $0x0,%ecx
  800840:	f7 d9                	neg    %ecx
  800842:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
  800845:	b8 0a 00 00 00       	mov    $0xa,%eax
  80084a:	e9 ec 00 00 00       	jmp    80093b <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  80084f:	83 f9 01             	cmp    $0x1,%ecx
  800852:	7e 18                	jle    80086c <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
  800854:	8b 45 14             	mov    0x14(%ebp),%eax
  800857:	8b 10                	mov    (%eax),%edx
  800859:	8b 48 04             	mov    0x4(%eax),%ecx
  80085c:	8d 40 08             	lea    0x8(%eax),%eax
  80085f:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  800862:	b8 0a 00 00 00       	mov    $0xa,%eax
  800867:	e9 cf 00 00 00       	jmp    80093b <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
  80086c:	85 c9                	test   %ecx,%ecx
  80086e:	74 1a                	je     80088a <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
  800870:	8b 45 14             	mov    0x14(%ebp),%eax
  800873:	8b 10                	mov    (%eax),%edx
  800875:	b9 00 00 00 00       	mov    $0x0,%ecx
  80087a:	8d 40 04             	lea    0x4(%eax),%eax
  80087d:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  800880:	b8 0a 00 00 00       	mov    $0xa,%eax
  800885:	e9 b1 00 00 00       	jmp    80093b <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
  80088a:	8b 45 14             	mov    0x14(%ebp),%eax
  80088d:	8b 10                	mov    (%eax),%edx
  80088f:	b9 00 00 00 00       	mov    $0x0,%ecx
  800894:	8d 40 04             	lea    0x4(%eax),%eax
  800897:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  80089a:	b8 0a 00 00 00       	mov    $0xa,%eax
  80089f:	e9 97 00 00 00       	jmp    80093b <vprintfmt+0x40f>
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
  8008a4:	83 ec 08             	sub    $0x8,%esp
  8008a7:	53                   	push   %ebx
  8008a8:	6a 58                	push   $0x58
  8008aa:	ff d6                	call   *%esi
			putch('X', putdat);
  8008ac:	83 c4 08             	add    $0x8,%esp
  8008af:	53                   	push   %ebx
  8008b0:	6a 58                	push   $0x58
  8008b2:	ff d6                	call   *%esi
			putch('X', putdat);
  8008b4:	83 c4 08             	add    $0x8,%esp
  8008b7:	53                   	push   %ebx
  8008b8:	6a 58                	push   $0x58
  8008ba:	ff d6                	call   *%esi
			break;
  8008bc:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8008bf:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
  8008c2:	e9 8b fc ff ff       	jmp    800552 <vprintfmt+0x26>

		// pointer
		case 'p':
			putch('0', putdat);
  8008c7:	83 ec 08             	sub    $0x8,%esp
  8008ca:	53                   	push   %ebx
  8008cb:	6a 30                	push   $0x30
  8008cd:	ff d6                	call   *%esi
			putch('x', putdat);
  8008cf:	83 c4 08             	add    $0x8,%esp
  8008d2:	53                   	push   %ebx
  8008d3:	6a 78                	push   $0x78
  8008d5:	ff d6                	call   *%esi
			num = (unsigned long long)
  8008d7:	8b 45 14             	mov    0x14(%ebp),%eax
  8008da:	8b 10                	mov    (%eax),%edx
  8008dc:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
  8008e1:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  8008e4:	8d 40 04             	lea    0x4(%eax),%eax
  8008e7:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
  8008ea:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
  8008ef:	eb 4a                	jmp    80093b <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  8008f1:	83 f9 01             	cmp    $0x1,%ecx
  8008f4:	7e 15                	jle    80090b <vprintfmt+0x3df>
		return va_arg(*ap, unsigned long long);
  8008f6:	8b 45 14             	mov    0x14(%ebp),%eax
  8008f9:	8b 10                	mov    (%eax),%edx
  8008fb:	8b 48 04             	mov    0x4(%eax),%ecx
  8008fe:	8d 40 08             	lea    0x8(%eax),%eax
  800901:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  800904:	b8 10 00 00 00       	mov    $0x10,%eax
  800909:	eb 30                	jmp    80093b <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
  80090b:	85 c9                	test   %ecx,%ecx
  80090d:	74 17                	je     800926 <vprintfmt+0x3fa>
		return va_arg(*ap, unsigned long);
  80090f:	8b 45 14             	mov    0x14(%ebp),%eax
  800912:	8b 10                	mov    (%eax),%edx
  800914:	b9 00 00 00 00       	mov    $0x0,%ecx
  800919:	8d 40 04             	lea    0x4(%eax),%eax
  80091c:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  80091f:	b8 10 00 00 00       	mov    $0x10,%eax
  800924:	eb 15                	jmp    80093b <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
  800926:	8b 45 14             	mov    0x14(%ebp),%eax
  800929:	8b 10                	mov    (%eax),%edx
  80092b:	b9 00 00 00 00       	mov    $0x0,%ecx
  800930:	8d 40 04             	lea    0x4(%eax),%eax
  800933:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  800936:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
  80093b:	83 ec 0c             	sub    $0xc,%esp
  80093e:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  800942:	57                   	push   %edi
  800943:	ff 75 e0             	pushl  -0x20(%ebp)
  800946:	50                   	push   %eax
  800947:	51                   	push   %ecx
  800948:	52                   	push   %edx
  800949:	89 da                	mov    %ebx,%edx
  80094b:	89 f0                	mov    %esi,%eax
  80094d:	e8 f1 fa ff ff       	call   800443 <printnum>
			break;
  800952:	83 c4 20             	add    $0x20,%esp
  800955:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800958:	e9 f5 fb ff ff       	jmp    800552 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  80095d:	83 ec 08             	sub    $0x8,%esp
  800960:	53                   	push   %ebx
  800961:	52                   	push   %edx
  800962:	ff d6                	call   *%esi
			break;
  800964:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800967:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  80096a:	e9 e3 fb ff ff       	jmp    800552 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  80096f:	83 ec 08             	sub    $0x8,%esp
  800972:	53                   	push   %ebx
  800973:	6a 25                	push   $0x25
  800975:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  800977:	83 c4 10             	add    $0x10,%esp
  80097a:	eb 03                	jmp    80097f <vprintfmt+0x453>
  80097c:	83 ef 01             	sub    $0x1,%edi
  80097f:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  800983:	75 f7                	jne    80097c <vprintfmt+0x450>
  800985:	e9 c8 fb ff ff       	jmp    800552 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
  80098a:	8d 65 f4             	lea    -0xc(%ebp),%esp
  80098d:	5b                   	pop    %ebx
  80098e:	5e                   	pop    %esi
  80098f:	5f                   	pop    %edi
  800990:	5d                   	pop    %ebp
  800991:	c3                   	ret    

00800992 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  800992:	55                   	push   %ebp
  800993:	89 e5                	mov    %esp,%ebp
  800995:	83 ec 18             	sub    $0x18,%esp
  800998:	8b 45 08             	mov    0x8(%ebp),%eax
  80099b:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  80099e:	89 45 ec             	mov    %eax,-0x14(%ebp)
  8009a1:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  8009a5:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  8009a8:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  8009af:	85 c0                	test   %eax,%eax
  8009b1:	74 26                	je     8009d9 <vsnprintf+0x47>
  8009b3:	85 d2                	test   %edx,%edx
  8009b5:	7e 22                	jle    8009d9 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  8009b7:	ff 75 14             	pushl  0x14(%ebp)
  8009ba:	ff 75 10             	pushl  0x10(%ebp)
  8009bd:	8d 45 ec             	lea    -0x14(%ebp),%eax
  8009c0:	50                   	push   %eax
  8009c1:	68 f2 04 80 00       	push   $0x8004f2
  8009c6:	e8 61 fb ff ff       	call   80052c <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  8009cb:	8b 45 ec             	mov    -0x14(%ebp),%eax
  8009ce:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  8009d1:	8b 45 f4             	mov    -0xc(%ebp),%eax
  8009d4:	83 c4 10             	add    $0x10,%esp
  8009d7:	eb 05                	jmp    8009de <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  8009d9:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  8009de:	c9                   	leave  
  8009df:	c3                   	ret    

008009e0 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  8009e0:	55                   	push   %ebp
  8009e1:	89 e5                	mov    %esp,%ebp
  8009e3:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  8009e6:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  8009e9:	50                   	push   %eax
  8009ea:	ff 75 10             	pushl  0x10(%ebp)
  8009ed:	ff 75 0c             	pushl  0xc(%ebp)
  8009f0:	ff 75 08             	pushl  0x8(%ebp)
  8009f3:	e8 9a ff ff ff       	call   800992 <vsnprintf>
	va_end(ap);

	return rc;
}
  8009f8:	c9                   	leave  
  8009f9:	c3                   	ret    

008009fa <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  8009fa:	55                   	push   %ebp
  8009fb:	89 e5                	mov    %esp,%ebp
  8009fd:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  800a00:	b8 00 00 00 00       	mov    $0x0,%eax
  800a05:	eb 03                	jmp    800a0a <strlen+0x10>
		n++;
  800a07:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  800a0a:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  800a0e:	75 f7                	jne    800a07 <strlen+0xd>
		n++;
	return n;
}
  800a10:	5d                   	pop    %ebp
  800a11:	c3                   	ret    

00800a12 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  800a12:	55                   	push   %ebp
  800a13:	89 e5                	mov    %esp,%ebp
  800a15:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800a18:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800a1b:	ba 00 00 00 00       	mov    $0x0,%edx
  800a20:	eb 03                	jmp    800a25 <strnlen+0x13>
		n++;
  800a22:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800a25:	39 c2                	cmp    %eax,%edx
  800a27:	74 08                	je     800a31 <strnlen+0x1f>
  800a29:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  800a2d:	75 f3                	jne    800a22 <strnlen+0x10>
  800a2f:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
  800a31:	5d                   	pop    %ebp
  800a32:	c3                   	ret    

00800a33 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  800a33:	55                   	push   %ebp
  800a34:	89 e5                	mov    %esp,%ebp
  800a36:	53                   	push   %ebx
  800a37:	8b 45 08             	mov    0x8(%ebp),%eax
  800a3a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  800a3d:	89 c2                	mov    %eax,%edx
  800a3f:	83 c2 01             	add    $0x1,%edx
  800a42:	83 c1 01             	add    $0x1,%ecx
  800a45:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  800a49:	88 5a ff             	mov    %bl,-0x1(%edx)
  800a4c:	84 db                	test   %bl,%bl
  800a4e:	75 ef                	jne    800a3f <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  800a50:	5b                   	pop    %ebx
  800a51:	5d                   	pop    %ebp
  800a52:	c3                   	ret    

00800a53 <strcat>:

char *
strcat(char *dst, const char *src)
{
  800a53:	55                   	push   %ebp
  800a54:	89 e5                	mov    %esp,%ebp
  800a56:	53                   	push   %ebx
  800a57:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  800a5a:	53                   	push   %ebx
  800a5b:	e8 9a ff ff ff       	call   8009fa <strlen>
  800a60:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  800a63:	ff 75 0c             	pushl  0xc(%ebp)
  800a66:	01 d8                	add    %ebx,%eax
  800a68:	50                   	push   %eax
  800a69:	e8 c5 ff ff ff       	call   800a33 <strcpy>
	return dst;
}
  800a6e:	89 d8                	mov    %ebx,%eax
  800a70:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  800a73:	c9                   	leave  
  800a74:	c3                   	ret    

00800a75 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  800a75:	55                   	push   %ebp
  800a76:	89 e5                	mov    %esp,%ebp
  800a78:	56                   	push   %esi
  800a79:	53                   	push   %ebx
  800a7a:	8b 75 08             	mov    0x8(%ebp),%esi
  800a7d:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800a80:	89 f3                	mov    %esi,%ebx
  800a82:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800a85:	89 f2                	mov    %esi,%edx
  800a87:	eb 0f                	jmp    800a98 <strncpy+0x23>
		*dst++ = *src;
  800a89:	83 c2 01             	add    $0x1,%edx
  800a8c:	0f b6 01             	movzbl (%ecx),%eax
  800a8f:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  800a92:	80 39 01             	cmpb   $0x1,(%ecx)
  800a95:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800a98:	39 da                	cmp    %ebx,%edx
  800a9a:	75 ed                	jne    800a89 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  800a9c:	89 f0                	mov    %esi,%eax
  800a9e:	5b                   	pop    %ebx
  800a9f:	5e                   	pop    %esi
  800aa0:	5d                   	pop    %ebp
  800aa1:	c3                   	ret    

00800aa2 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  800aa2:	55                   	push   %ebp
  800aa3:	89 e5                	mov    %esp,%ebp
  800aa5:	56                   	push   %esi
  800aa6:	53                   	push   %ebx
  800aa7:	8b 75 08             	mov    0x8(%ebp),%esi
  800aaa:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800aad:	8b 55 10             	mov    0x10(%ebp),%edx
  800ab0:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  800ab2:	85 d2                	test   %edx,%edx
  800ab4:	74 21                	je     800ad7 <strlcpy+0x35>
  800ab6:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
  800aba:	89 f2                	mov    %esi,%edx
  800abc:	eb 09                	jmp    800ac7 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  800abe:	83 c2 01             	add    $0x1,%edx
  800ac1:	83 c1 01             	add    $0x1,%ecx
  800ac4:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  800ac7:	39 c2                	cmp    %eax,%edx
  800ac9:	74 09                	je     800ad4 <strlcpy+0x32>
  800acb:	0f b6 19             	movzbl (%ecx),%ebx
  800ace:	84 db                	test   %bl,%bl
  800ad0:	75 ec                	jne    800abe <strlcpy+0x1c>
  800ad2:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
  800ad4:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  800ad7:	29 f0                	sub    %esi,%eax
}
  800ad9:	5b                   	pop    %ebx
  800ada:	5e                   	pop    %esi
  800adb:	5d                   	pop    %ebp
  800adc:	c3                   	ret    

00800add <strcmp>:

int
strcmp(const char *p, const char *q)
{
  800add:	55                   	push   %ebp
  800ade:	89 e5                	mov    %esp,%ebp
  800ae0:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800ae3:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  800ae6:	eb 06                	jmp    800aee <strcmp+0x11>
		p++, q++;
  800ae8:	83 c1 01             	add    $0x1,%ecx
  800aeb:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  800aee:	0f b6 01             	movzbl (%ecx),%eax
  800af1:	84 c0                	test   %al,%al
  800af3:	74 04                	je     800af9 <strcmp+0x1c>
  800af5:	3a 02                	cmp    (%edx),%al
  800af7:	74 ef                	je     800ae8 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800af9:	0f b6 c0             	movzbl %al,%eax
  800afc:	0f b6 12             	movzbl (%edx),%edx
  800aff:	29 d0                	sub    %edx,%eax
}
  800b01:	5d                   	pop    %ebp
  800b02:	c3                   	ret    

00800b03 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  800b03:	55                   	push   %ebp
  800b04:	89 e5                	mov    %esp,%ebp
  800b06:	53                   	push   %ebx
  800b07:	8b 45 08             	mov    0x8(%ebp),%eax
  800b0a:	8b 55 0c             	mov    0xc(%ebp),%edx
  800b0d:	89 c3                	mov    %eax,%ebx
  800b0f:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  800b12:	eb 06                	jmp    800b1a <strncmp+0x17>
		n--, p++, q++;
  800b14:	83 c0 01             	add    $0x1,%eax
  800b17:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  800b1a:	39 d8                	cmp    %ebx,%eax
  800b1c:	74 15                	je     800b33 <strncmp+0x30>
  800b1e:	0f b6 08             	movzbl (%eax),%ecx
  800b21:	84 c9                	test   %cl,%cl
  800b23:	74 04                	je     800b29 <strncmp+0x26>
  800b25:	3a 0a                	cmp    (%edx),%cl
  800b27:	74 eb                	je     800b14 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  800b29:	0f b6 00             	movzbl (%eax),%eax
  800b2c:	0f b6 12             	movzbl (%edx),%edx
  800b2f:	29 d0                	sub    %edx,%eax
  800b31:	eb 05                	jmp    800b38 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  800b33:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  800b38:	5b                   	pop    %ebx
  800b39:	5d                   	pop    %ebp
  800b3a:	c3                   	ret    

00800b3b <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  800b3b:	55                   	push   %ebp
  800b3c:	89 e5                	mov    %esp,%ebp
  800b3e:	8b 45 08             	mov    0x8(%ebp),%eax
  800b41:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800b45:	eb 07                	jmp    800b4e <strchr+0x13>
		if (*s == c)
  800b47:	38 ca                	cmp    %cl,%dl
  800b49:	74 0f                	je     800b5a <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  800b4b:	83 c0 01             	add    $0x1,%eax
  800b4e:	0f b6 10             	movzbl (%eax),%edx
  800b51:	84 d2                	test   %dl,%dl
  800b53:	75 f2                	jne    800b47 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  800b55:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800b5a:	5d                   	pop    %ebp
  800b5b:	c3                   	ret    

00800b5c <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  800b5c:	55                   	push   %ebp
  800b5d:	89 e5                	mov    %esp,%ebp
  800b5f:	8b 45 08             	mov    0x8(%ebp),%eax
  800b62:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800b66:	eb 03                	jmp    800b6b <strfind+0xf>
  800b68:	83 c0 01             	add    $0x1,%eax
  800b6b:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  800b6e:	38 ca                	cmp    %cl,%dl
  800b70:	74 04                	je     800b76 <strfind+0x1a>
  800b72:	84 d2                	test   %dl,%dl
  800b74:	75 f2                	jne    800b68 <strfind+0xc>
			break;
	return (char *) s;
}
  800b76:	5d                   	pop    %ebp
  800b77:	c3                   	ret    

00800b78 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  800b78:	55                   	push   %ebp
  800b79:	89 e5                	mov    %esp,%ebp
  800b7b:	57                   	push   %edi
  800b7c:	56                   	push   %esi
  800b7d:	53                   	push   %ebx
  800b7e:	8b 7d 08             	mov    0x8(%ebp),%edi
  800b81:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  800b84:	85 c9                	test   %ecx,%ecx
  800b86:	74 36                	je     800bbe <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  800b88:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800b8e:	75 28                	jne    800bb8 <memset+0x40>
  800b90:	f6 c1 03             	test   $0x3,%cl
  800b93:	75 23                	jne    800bb8 <memset+0x40>
		c &= 0xFF;
  800b95:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  800b99:	89 d3                	mov    %edx,%ebx
  800b9b:	c1 e3 08             	shl    $0x8,%ebx
  800b9e:	89 d6                	mov    %edx,%esi
  800ba0:	c1 e6 18             	shl    $0x18,%esi
  800ba3:	89 d0                	mov    %edx,%eax
  800ba5:	c1 e0 10             	shl    $0x10,%eax
  800ba8:	09 f0                	or     %esi,%eax
  800baa:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
  800bac:	89 d8                	mov    %ebx,%eax
  800bae:	09 d0                	or     %edx,%eax
  800bb0:	c1 e9 02             	shr    $0x2,%ecx
  800bb3:	fc                   	cld    
  800bb4:	f3 ab                	rep stos %eax,%es:(%edi)
  800bb6:	eb 06                	jmp    800bbe <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800bb8:	8b 45 0c             	mov    0xc(%ebp),%eax
  800bbb:	fc                   	cld    
  800bbc:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  800bbe:	89 f8                	mov    %edi,%eax
  800bc0:	5b                   	pop    %ebx
  800bc1:	5e                   	pop    %esi
  800bc2:	5f                   	pop    %edi
  800bc3:	5d                   	pop    %ebp
  800bc4:	c3                   	ret    

00800bc5 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800bc5:	55                   	push   %ebp
  800bc6:	89 e5                	mov    %esp,%ebp
  800bc8:	57                   	push   %edi
  800bc9:	56                   	push   %esi
  800bca:	8b 45 08             	mov    0x8(%ebp),%eax
  800bcd:	8b 75 0c             	mov    0xc(%ebp),%esi
  800bd0:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800bd3:	39 c6                	cmp    %eax,%esi
  800bd5:	73 35                	jae    800c0c <memmove+0x47>
  800bd7:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800bda:	39 d0                	cmp    %edx,%eax
  800bdc:	73 2e                	jae    800c0c <memmove+0x47>
		s += n;
		d += n;
  800bde:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800be1:	89 d6                	mov    %edx,%esi
  800be3:	09 fe                	or     %edi,%esi
  800be5:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800beb:	75 13                	jne    800c00 <memmove+0x3b>
  800bed:	f6 c1 03             	test   $0x3,%cl
  800bf0:	75 0e                	jne    800c00 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
  800bf2:	83 ef 04             	sub    $0x4,%edi
  800bf5:	8d 72 fc             	lea    -0x4(%edx),%esi
  800bf8:	c1 e9 02             	shr    $0x2,%ecx
  800bfb:	fd                   	std    
  800bfc:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800bfe:	eb 09                	jmp    800c09 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800c00:	83 ef 01             	sub    $0x1,%edi
  800c03:	8d 72 ff             	lea    -0x1(%edx),%esi
  800c06:	fd                   	std    
  800c07:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800c09:	fc                   	cld    
  800c0a:	eb 1d                	jmp    800c29 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800c0c:	89 f2                	mov    %esi,%edx
  800c0e:	09 c2                	or     %eax,%edx
  800c10:	f6 c2 03             	test   $0x3,%dl
  800c13:	75 0f                	jne    800c24 <memmove+0x5f>
  800c15:	f6 c1 03             	test   $0x3,%cl
  800c18:	75 0a                	jne    800c24 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
  800c1a:	c1 e9 02             	shr    $0x2,%ecx
  800c1d:	89 c7                	mov    %eax,%edi
  800c1f:	fc                   	cld    
  800c20:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800c22:	eb 05                	jmp    800c29 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800c24:	89 c7                	mov    %eax,%edi
  800c26:	fc                   	cld    
  800c27:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800c29:	5e                   	pop    %esi
  800c2a:	5f                   	pop    %edi
  800c2b:	5d                   	pop    %ebp
  800c2c:	c3                   	ret    

00800c2d <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  800c2d:	55                   	push   %ebp
  800c2e:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  800c30:	ff 75 10             	pushl  0x10(%ebp)
  800c33:	ff 75 0c             	pushl  0xc(%ebp)
  800c36:	ff 75 08             	pushl  0x8(%ebp)
  800c39:	e8 87 ff ff ff       	call   800bc5 <memmove>
}
  800c3e:	c9                   	leave  
  800c3f:	c3                   	ret    

00800c40 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800c40:	55                   	push   %ebp
  800c41:	89 e5                	mov    %esp,%ebp
  800c43:	56                   	push   %esi
  800c44:	53                   	push   %ebx
  800c45:	8b 45 08             	mov    0x8(%ebp),%eax
  800c48:	8b 55 0c             	mov    0xc(%ebp),%edx
  800c4b:	89 c6                	mov    %eax,%esi
  800c4d:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800c50:	eb 1a                	jmp    800c6c <memcmp+0x2c>
		if (*s1 != *s2)
  800c52:	0f b6 08             	movzbl (%eax),%ecx
  800c55:	0f b6 1a             	movzbl (%edx),%ebx
  800c58:	38 d9                	cmp    %bl,%cl
  800c5a:	74 0a                	je     800c66 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  800c5c:	0f b6 c1             	movzbl %cl,%eax
  800c5f:	0f b6 db             	movzbl %bl,%ebx
  800c62:	29 d8                	sub    %ebx,%eax
  800c64:	eb 0f                	jmp    800c75 <memcmp+0x35>
		s1++, s2++;
  800c66:	83 c0 01             	add    $0x1,%eax
  800c69:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800c6c:	39 f0                	cmp    %esi,%eax
  800c6e:	75 e2                	jne    800c52 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  800c70:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800c75:	5b                   	pop    %ebx
  800c76:	5e                   	pop    %esi
  800c77:	5d                   	pop    %ebp
  800c78:	c3                   	ret    

00800c79 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800c79:	55                   	push   %ebp
  800c7a:	89 e5                	mov    %esp,%ebp
  800c7c:	53                   	push   %ebx
  800c7d:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
  800c80:	89 c1                	mov    %eax,%ecx
  800c82:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
  800c85:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800c89:	eb 0a                	jmp    800c95 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
  800c8b:	0f b6 10             	movzbl (%eax),%edx
  800c8e:	39 da                	cmp    %ebx,%edx
  800c90:	74 07                	je     800c99 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800c92:	83 c0 01             	add    $0x1,%eax
  800c95:	39 c8                	cmp    %ecx,%eax
  800c97:	72 f2                	jb     800c8b <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800c99:	5b                   	pop    %ebx
  800c9a:	5d                   	pop    %ebp
  800c9b:	c3                   	ret    

00800c9c <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800c9c:	55                   	push   %ebp
  800c9d:	89 e5                	mov    %esp,%ebp
  800c9f:	57                   	push   %edi
  800ca0:	56                   	push   %esi
  800ca1:	53                   	push   %ebx
  800ca2:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800ca5:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800ca8:	eb 03                	jmp    800cad <strtol+0x11>
		s++;
  800caa:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800cad:	0f b6 01             	movzbl (%ecx),%eax
  800cb0:	3c 20                	cmp    $0x20,%al
  800cb2:	74 f6                	je     800caa <strtol+0xe>
  800cb4:	3c 09                	cmp    $0x9,%al
  800cb6:	74 f2                	je     800caa <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800cb8:	3c 2b                	cmp    $0x2b,%al
  800cba:	75 0a                	jne    800cc6 <strtol+0x2a>
		s++;
  800cbc:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800cbf:	bf 00 00 00 00       	mov    $0x0,%edi
  800cc4:	eb 11                	jmp    800cd7 <strtol+0x3b>
  800cc6:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800ccb:	3c 2d                	cmp    $0x2d,%al
  800ccd:	75 08                	jne    800cd7 <strtol+0x3b>
		s++, neg = 1;
  800ccf:	83 c1 01             	add    $0x1,%ecx
  800cd2:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800cd7:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800cdd:	75 15                	jne    800cf4 <strtol+0x58>
  800cdf:	80 39 30             	cmpb   $0x30,(%ecx)
  800ce2:	75 10                	jne    800cf4 <strtol+0x58>
  800ce4:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  800ce8:	75 7c                	jne    800d66 <strtol+0xca>
		s += 2, base = 16;
  800cea:	83 c1 02             	add    $0x2,%ecx
  800ced:	bb 10 00 00 00       	mov    $0x10,%ebx
  800cf2:	eb 16                	jmp    800d0a <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  800cf4:	85 db                	test   %ebx,%ebx
  800cf6:	75 12                	jne    800d0a <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800cf8:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800cfd:	80 39 30             	cmpb   $0x30,(%ecx)
  800d00:	75 08                	jne    800d0a <strtol+0x6e>
		s++, base = 8;
  800d02:	83 c1 01             	add    $0x1,%ecx
  800d05:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
  800d0a:	b8 00 00 00 00       	mov    $0x0,%eax
  800d0f:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800d12:	0f b6 11             	movzbl (%ecx),%edx
  800d15:	8d 72 d0             	lea    -0x30(%edx),%esi
  800d18:	89 f3                	mov    %esi,%ebx
  800d1a:	80 fb 09             	cmp    $0x9,%bl
  800d1d:	77 08                	ja     800d27 <strtol+0x8b>
			dig = *s - '0';
  800d1f:	0f be d2             	movsbl %dl,%edx
  800d22:	83 ea 30             	sub    $0x30,%edx
  800d25:	eb 22                	jmp    800d49 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
  800d27:	8d 72 9f             	lea    -0x61(%edx),%esi
  800d2a:	89 f3                	mov    %esi,%ebx
  800d2c:	80 fb 19             	cmp    $0x19,%bl
  800d2f:	77 08                	ja     800d39 <strtol+0x9d>
			dig = *s - 'a' + 10;
  800d31:	0f be d2             	movsbl %dl,%edx
  800d34:	83 ea 57             	sub    $0x57,%edx
  800d37:	eb 10                	jmp    800d49 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
  800d39:	8d 72 bf             	lea    -0x41(%edx),%esi
  800d3c:	89 f3                	mov    %esi,%ebx
  800d3e:	80 fb 19             	cmp    $0x19,%bl
  800d41:	77 16                	ja     800d59 <strtol+0xbd>
			dig = *s - 'A' + 10;
  800d43:	0f be d2             	movsbl %dl,%edx
  800d46:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
  800d49:	3b 55 10             	cmp    0x10(%ebp),%edx
  800d4c:	7d 0b                	jge    800d59 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  800d4e:	83 c1 01             	add    $0x1,%ecx
  800d51:	0f af 45 10          	imul   0x10(%ebp),%eax
  800d55:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
  800d57:	eb b9                	jmp    800d12 <strtol+0x76>

	if (endptr)
  800d59:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800d5d:	74 0d                	je     800d6c <strtol+0xd0>
		*endptr = (char *) s;
  800d5f:	8b 75 0c             	mov    0xc(%ebp),%esi
  800d62:	89 0e                	mov    %ecx,(%esi)
  800d64:	eb 06                	jmp    800d6c <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800d66:	85 db                	test   %ebx,%ebx
  800d68:	74 98                	je     800d02 <strtol+0x66>
  800d6a:	eb 9e                	jmp    800d0a <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
  800d6c:	89 c2                	mov    %eax,%edx
  800d6e:	f7 da                	neg    %edx
  800d70:	85 ff                	test   %edi,%edi
  800d72:	0f 45 c2             	cmovne %edx,%eax
}
  800d75:	5b                   	pop    %ebx
  800d76:	5e                   	pop    %esi
  800d77:	5f                   	pop    %edi
  800d78:	5d                   	pop    %ebp
  800d79:	c3                   	ret    

00800d7a <set_pgfault_handler>:
// at UXSTACKTOP), and tell the kernel to call the assembly-language
// _pgfault_upcall routine when a page fault occurs.
//
void
set_pgfault_handler(void (*handler)(struct UTrapframe *utf))
{
  800d7a:	55                   	push   %ebp
  800d7b:	89 e5                	mov    %esp,%ebp
  800d7d:	83 ec 08             	sub    $0x8,%esp
	int r;

	if (_pgfault_handler == 0) {
  800d80:	83 3d 08 20 80 00 00 	cmpl   $0x0,0x802008
  800d87:	75 31                	jne    800dba <set_pgfault_handler+0x40>
		// First time through!
		// LAB 4: Your code here.
		void* addr = (void*) (UXSTACKTOP-PGSIZE);
		r=sys_page_alloc(thisenv->env_id, addr, PTE_W|PTE_U|PTE_P);
  800d89:	a1 04 20 80 00       	mov    0x802004,%eax
  800d8e:	8b 40 48             	mov    0x48(%eax),%eax
  800d91:	83 ec 04             	sub    $0x4,%esp
  800d94:	6a 07                	push   $0x7
  800d96:	68 00 f0 bf ee       	push   $0xeebff000
  800d9b:	50                   	push   %eax
  800d9c:	e8 c7 f3 ff ff       	call   800168 <sys_page_alloc>
		if( r < 0)
  800da1:	83 c4 10             	add    $0x10,%esp
  800da4:	85 c0                	test   %eax,%eax
  800da6:	79 12                	jns    800dba <set_pgfault_handler+0x40>
			panic("No memory for the UxStack, the mistake is %d\n",r);
  800da8:	50                   	push   %eax
  800da9:	68 28 13 80 00       	push   $0x801328
  800dae:	6a 23                	push   $0x23
  800db0:	68 84 13 80 00       	push   $0x801384
  800db5:	e8 9c f5 ff ff       	call   800356 <_panic>
		//panic("set_pgfault_handler not implemented");
	}

	// Save handler pointer for assembly to call.
	_pgfault_handler = handler;
  800dba:	8b 45 08             	mov    0x8(%ebp),%eax
  800dbd:	a3 08 20 80 00       	mov    %eax,0x802008
	if(( r= sys_env_set_pgfault_upcall(sys_getenvid(), _pgfault_upcall))<0)
  800dc2:	e8 63 f3 ff ff       	call   80012a <sys_getenvid>
  800dc7:	83 ec 08             	sub    $0x8,%esp
  800dca:	68 17 03 80 00       	push   $0x800317
  800dcf:	50                   	push   %eax
  800dd0:	e8 9c f4 ff ff       	call   800271 <sys_env_set_pgfault_upcall>
  800dd5:	83 c4 10             	add    $0x10,%esp
  800dd8:	85 c0                	test   %eax,%eax
  800dda:	79 12                	jns    800dee <set_pgfault_handler+0x74>
		panic("sys_env_set_pgfault_upcall is not right %d\n", r);
  800ddc:	50                   	push   %eax
  800ddd:	68 58 13 80 00       	push   $0x801358
  800de2:	6a 2a                	push   $0x2a
  800de4:	68 84 13 80 00       	push   $0x801384
  800de9:	e8 68 f5 ff ff       	call   800356 <_panic>


}
  800dee:	c9                   	leave  
  800def:	c3                   	ret    

00800df0 <__udivdi3>:
  800df0:	55                   	push   %ebp
  800df1:	57                   	push   %edi
  800df2:	56                   	push   %esi
  800df3:	53                   	push   %ebx
  800df4:	83 ec 1c             	sub    $0x1c,%esp
  800df7:	8b 74 24 3c          	mov    0x3c(%esp),%esi
  800dfb:	8b 5c 24 30          	mov    0x30(%esp),%ebx
  800dff:	8b 4c 24 34          	mov    0x34(%esp),%ecx
  800e03:	8b 7c 24 38          	mov    0x38(%esp),%edi
  800e07:	85 f6                	test   %esi,%esi
  800e09:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800e0d:	89 ca                	mov    %ecx,%edx
  800e0f:	89 f8                	mov    %edi,%eax
  800e11:	75 3d                	jne    800e50 <__udivdi3+0x60>
  800e13:	39 cf                	cmp    %ecx,%edi
  800e15:	0f 87 c5 00 00 00    	ja     800ee0 <__udivdi3+0xf0>
  800e1b:	85 ff                	test   %edi,%edi
  800e1d:	89 fd                	mov    %edi,%ebp
  800e1f:	75 0b                	jne    800e2c <__udivdi3+0x3c>
  800e21:	b8 01 00 00 00       	mov    $0x1,%eax
  800e26:	31 d2                	xor    %edx,%edx
  800e28:	f7 f7                	div    %edi
  800e2a:	89 c5                	mov    %eax,%ebp
  800e2c:	89 c8                	mov    %ecx,%eax
  800e2e:	31 d2                	xor    %edx,%edx
  800e30:	f7 f5                	div    %ebp
  800e32:	89 c1                	mov    %eax,%ecx
  800e34:	89 d8                	mov    %ebx,%eax
  800e36:	89 cf                	mov    %ecx,%edi
  800e38:	f7 f5                	div    %ebp
  800e3a:	89 c3                	mov    %eax,%ebx
  800e3c:	89 d8                	mov    %ebx,%eax
  800e3e:	89 fa                	mov    %edi,%edx
  800e40:	83 c4 1c             	add    $0x1c,%esp
  800e43:	5b                   	pop    %ebx
  800e44:	5e                   	pop    %esi
  800e45:	5f                   	pop    %edi
  800e46:	5d                   	pop    %ebp
  800e47:	c3                   	ret    
  800e48:	90                   	nop
  800e49:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800e50:	39 ce                	cmp    %ecx,%esi
  800e52:	77 74                	ja     800ec8 <__udivdi3+0xd8>
  800e54:	0f bd fe             	bsr    %esi,%edi
  800e57:	83 f7 1f             	xor    $0x1f,%edi
  800e5a:	0f 84 98 00 00 00    	je     800ef8 <__udivdi3+0x108>
  800e60:	bb 20 00 00 00       	mov    $0x20,%ebx
  800e65:	89 f9                	mov    %edi,%ecx
  800e67:	89 c5                	mov    %eax,%ebp
  800e69:	29 fb                	sub    %edi,%ebx
  800e6b:	d3 e6                	shl    %cl,%esi
  800e6d:	89 d9                	mov    %ebx,%ecx
  800e6f:	d3 ed                	shr    %cl,%ebp
  800e71:	89 f9                	mov    %edi,%ecx
  800e73:	d3 e0                	shl    %cl,%eax
  800e75:	09 ee                	or     %ebp,%esi
  800e77:	89 d9                	mov    %ebx,%ecx
  800e79:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800e7d:	89 d5                	mov    %edx,%ebp
  800e7f:	8b 44 24 08          	mov    0x8(%esp),%eax
  800e83:	d3 ed                	shr    %cl,%ebp
  800e85:	89 f9                	mov    %edi,%ecx
  800e87:	d3 e2                	shl    %cl,%edx
  800e89:	89 d9                	mov    %ebx,%ecx
  800e8b:	d3 e8                	shr    %cl,%eax
  800e8d:	09 c2                	or     %eax,%edx
  800e8f:	89 d0                	mov    %edx,%eax
  800e91:	89 ea                	mov    %ebp,%edx
  800e93:	f7 f6                	div    %esi
  800e95:	89 d5                	mov    %edx,%ebp
  800e97:	89 c3                	mov    %eax,%ebx
  800e99:	f7 64 24 0c          	mull   0xc(%esp)
  800e9d:	39 d5                	cmp    %edx,%ebp
  800e9f:	72 10                	jb     800eb1 <__udivdi3+0xc1>
  800ea1:	8b 74 24 08          	mov    0x8(%esp),%esi
  800ea5:	89 f9                	mov    %edi,%ecx
  800ea7:	d3 e6                	shl    %cl,%esi
  800ea9:	39 c6                	cmp    %eax,%esi
  800eab:	73 07                	jae    800eb4 <__udivdi3+0xc4>
  800ead:	39 d5                	cmp    %edx,%ebp
  800eaf:	75 03                	jne    800eb4 <__udivdi3+0xc4>
  800eb1:	83 eb 01             	sub    $0x1,%ebx
  800eb4:	31 ff                	xor    %edi,%edi
  800eb6:	89 d8                	mov    %ebx,%eax
  800eb8:	89 fa                	mov    %edi,%edx
  800eba:	83 c4 1c             	add    $0x1c,%esp
  800ebd:	5b                   	pop    %ebx
  800ebe:	5e                   	pop    %esi
  800ebf:	5f                   	pop    %edi
  800ec0:	5d                   	pop    %ebp
  800ec1:	c3                   	ret    
  800ec2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800ec8:	31 ff                	xor    %edi,%edi
  800eca:	31 db                	xor    %ebx,%ebx
  800ecc:	89 d8                	mov    %ebx,%eax
  800ece:	89 fa                	mov    %edi,%edx
  800ed0:	83 c4 1c             	add    $0x1c,%esp
  800ed3:	5b                   	pop    %ebx
  800ed4:	5e                   	pop    %esi
  800ed5:	5f                   	pop    %edi
  800ed6:	5d                   	pop    %ebp
  800ed7:	c3                   	ret    
  800ed8:	90                   	nop
  800ed9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800ee0:	89 d8                	mov    %ebx,%eax
  800ee2:	f7 f7                	div    %edi
  800ee4:	31 ff                	xor    %edi,%edi
  800ee6:	89 c3                	mov    %eax,%ebx
  800ee8:	89 d8                	mov    %ebx,%eax
  800eea:	89 fa                	mov    %edi,%edx
  800eec:	83 c4 1c             	add    $0x1c,%esp
  800eef:	5b                   	pop    %ebx
  800ef0:	5e                   	pop    %esi
  800ef1:	5f                   	pop    %edi
  800ef2:	5d                   	pop    %ebp
  800ef3:	c3                   	ret    
  800ef4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800ef8:	39 ce                	cmp    %ecx,%esi
  800efa:	72 0c                	jb     800f08 <__udivdi3+0x118>
  800efc:	31 db                	xor    %ebx,%ebx
  800efe:	3b 44 24 08          	cmp    0x8(%esp),%eax
  800f02:	0f 87 34 ff ff ff    	ja     800e3c <__udivdi3+0x4c>
  800f08:	bb 01 00 00 00       	mov    $0x1,%ebx
  800f0d:	e9 2a ff ff ff       	jmp    800e3c <__udivdi3+0x4c>
  800f12:	66 90                	xchg   %ax,%ax
  800f14:	66 90                	xchg   %ax,%ax
  800f16:	66 90                	xchg   %ax,%ax
  800f18:	66 90                	xchg   %ax,%ax
  800f1a:	66 90                	xchg   %ax,%ax
  800f1c:	66 90                	xchg   %ax,%ax
  800f1e:	66 90                	xchg   %ax,%ax

00800f20 <__umoddi3>:
  800f20:	55                   	push   %ebp
  800f21:	57                   	push   %edi
  800f22:	56                   	push   %esi
  800f23:	53                   	push   %ebx
  800f24:	83 ec 1c             	sub    $0x1c,%esp
  800f27:	8b 54 24 3c          	mov    0x3c(%esp),%edx
  800f2b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
  800f2f:	8b 74 24 34          	mov    0x34(%esp),%esi
  800f33:	8b 7c 24 38          	mov    0x38(%esp),%edi
  800f37:	85 d2                	test   %edx,%edx
  800f39:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  800f3d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800f41:	89 f3                	mov    %esi,%ebx
  800f43:	89 3c 24             	mov    %edi,(%esp)
  800f46:	89 74 24 04          	mov    %esi,0x4(%esp)
  800f4a:	75 1c                	jne    800f68 <__umoddi3+0x48>
  800f4c:	39 f7                	cmp    %esi,%edi
  800f4e:	76 50                	jbe    800fa0 <__umoddi3+0x80>
  800f50:	89 c8                	mov    %ecx,%eax
  800f52:	89 f2                	mov    %esi,%edx
  800f54:	f7 f7                	div    %edi
  800f56:	89 d0                	mov    %edx,%eax
  800f58:	31 d2                	xor    %edx,%edx
  800f5a:	83 c4 1c             	add    $0x1c,%esp
  800f5d:	5b                   	pop    %ebx
  800f5e:	5e                   	pop    %esi
  800f5f:	5f                   	pop    %edi
  800f60:	5d                   	pop    %ebp
  800f61:	c3                   	ret    
  800f62:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800f68:	39 f2                	cmp    %esi,%edx
  800f6a:	89 d0                	mov    %edx,%eax
  800f6c:	77 52                	ja     800fc0 <__umoddi3+0xa0>
  800f6e:	0f bd ea             	bsr    %edx,%ebp
  800f71:	83 f5 1f             	xor    $0x1f,%ebp
  800f74:	75 5a                	jne    800fd0 <__umoddi3+0xb0>
  800f76:	3b 54 24 04          	cmp    0x4(%esp),%edx
  800f7a:	0f 82 e0 00 00 00    	jb     801060 <__umoddi3+0x140>
  800f80:	39 0c 24             	cmp    %ecx,(%esp)
  800f83:	0f 86 d7 00 00 00    	jbe    801060 <__umoddi3+0x140>
  800f89:	8b 44 24 08          	mov    0x8(%esp),%eax
  800f8d:	8b 54 24 04          	mov    0x4(%esp),%edx
  800f91:	83 c4 1c             	add    $0x1c,%esp
  800f94:	5b                   	pop    %ebx
  800f95:	5e                   	pop    %esi
  800f96:	5f                   	pop    %edi
  800f97:	5d                   	pop    %ebp
  800f98:	c3                   	ret    
  800f99:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800fa0:	85 ff                	test   %edi,%edi
  800fa2:	89 fd                	mov    %edi,%ebp
  800fa4:	75 0b                	jne    800fb1 <__umoddi3+0x91>
  800fa6:	b8 01 00 00 00       	mov    $0x1,%eax
  800fab:	31 d2                	xor    %edx,%edx
  800fad:	f7 f7                	div    %edi
  800faf:	89 c5                	mov    %eax,%ebp
  800fb1:	89 f0                	mov    %esi,%eax
  800fb3:	31 d2                	xor    %edx,%edx
  800fb5:	f7 f5                	div    %ebp
  800fb7:	89 c8                	mov    %ecx,%eax
  800fb9:	f7 f5                	div    %ebp
  800fbb:	89 d0                	mov    %edx,%eax
  800fbd:	eb 99                	jmp    800f58 <__umoddi3+0x38>
  800fbf:	90                   	nop
  800fc0:	89 c8                	mov    %ecx,%eax
  800fc2:	89 f2                	mov    %esi,%edx
  800fc4:	83 c4 1c             	add    $0x1c,%esp
  800fc7:	5b                   	pop    %ebx
  800fc8:	5e                   	pop    %esi
  800fc9:	5f                   	pop    %edi
  800fca:	5d                   	pop    %ebp
  800fcb:	c3                   	ret    
  800fcc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800fd0:	8b 34 24             	mov    (%esp),%esi
  800fd3:	bf 20 00 00 00       	mov    $0x20,%edi
  800fd8:	89 e9                	mov    %ebp,%ecx
  800fda:	29 ef                	sub    %ebp,%edi
  800fdc:	d3 e0                	shl    %cl,%eax
  800fde:	89 f9                	mov    %edi,%ecx
  800fe0:	89 f2                	mov    %esi,%edx
  800fe2:	d3 ea                	shr    %cl,%edx
  800fe4:	89 e9                	mov    %ebp,%ecx
  800fe6:	09 c2                	or     %eax,%edx
  800fe8:	89 d8                	mov    %ebx,%eax
  800fea:	89 14 24             	mov    %edx,(%esp)
  800fed:	89 f2                	mov    %esi,%edx
  800fef:	d3 e2                	shl    %cl,%edx
  800ff1:	89 f9                	mov    %edi,%ecx
  800ff3:	89 54 24 04          	mov    %edx,0x4(%esp)
  800ff7:	8b 54 24 0c          	mov    0xc(%esp),%edx
  800ffb:	d3 e8                	shr    %cl,%eax
  800ffd:	89 e9                	mov    %ebp,%ecx
  800fff:	89 c6                	mov    %eax,%esi
  801001:	d3 e3                	shl    %cl,%ebx
  801003:	89 f9                	mov    %edi,%ecx
  801005:	89 d0                	mov    %edx,%eax
  801007:	d3 e8                	shr    %cl,%eax
  801009:	89 e9                	mov    %ebp,%ecx
  80100b:	09 d8                	or     %ebx,%eax
  80100d:	89 d3                	mov    %edx,%ebx
  80100f:	89 f2                	mov    %esi,%edx
  801011:	f7 34 24             	divl   (%esp)
  801014:	89 d6                	mov    %edx,%esi
  801016:	d3 e3                	shl    %cl,%ebx
  801018:	f7 64 24 04          	mull   0x4(%esp)
  80101c:	39 d6                	cmp    %edx,%esi
  80101e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  801022:	89 d1                	mov    %edx,%ecx
  801024:	89 c3                	mov    %eax,%ebx
  801026:	72 08                	jb     801030 <__umoddi3+0x110>
  801028:	75 11                	jne    80103b <__umoddi3+0x11b>
  80102a:	39 44 24 08          	cmp    %eax,0x8(%esp)
  80102e:	73 0b                	jae    80103b <__umoddi3+0x11b>
  801030:	2b 44 24 04          	sub    0x4(%esp),%eax
  801034:	1b 14 24             	sbb    (%esp),%edx
  801037:	89 d1                	mov    %edx,%ecx
  801039:	89 c3                	mov    %eax,%ebx
  80103b:	8b 54 24 08          	mov    0x8(%esp),%edx
  80103f:	29 da                	sub    %ebx,%edx
  801041:	19 ce                	sbb    %ecx,%esi
  801043:	89 f9                	mov    %edi,%ecx
  801045:	89 f0                	mov    %esi,%eax
  801047:	d3 e0                	shl    %cl,%eax
  801049:	89 e9                	mov    %ebp,%ecx
  80104b:	d3 ea                	shr    %cl,%edx
  80104d:	89 e9                	mov    %ebp,%ecx
  80104f:	d3 ee                	shr    %cl,%esi
  801051:	09 d0                	or     %edx,%eax
  801053:	89 f2                	mov    %esi,%edx
  801055:	83 c4 1c             	add    $0x1c,%esp
  801058:	5b                   	pop    %ebx
  801059:	5e                   	pop    %esi
  80105a:	5f                   	pop    %edi
  80105b:	5d                   	pop    %ebp
  80105c:	c3                   	ret    
  80105d:	8d 76 00             	lea    0x0(%esi),%esi
  801060:	29 f9                	sub    %edi,%ecx
  801062:	19 d6                	sbb    %edx,%esi
  801064:	89 74 24 04          	mov    %esi,0x4(%esp)
  801068:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  80106c:	e9 18 ff ff ff       	jmp    800f89 <__umoddi3+0x69>
