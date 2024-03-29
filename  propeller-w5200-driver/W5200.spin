'*********************************************************************************************
{
 AUTHOR: Mike Gebhard
 COPYRIGHT: Parallax Inc.
 LAST MODIFIED: 8/12/2012
 VERSION 1.0
 LICENSE: MIT (see end of file)

 DESCRIPTION:
 W5200 is a static representation of the W5200 common and socket registers.  The object
 provides a layered approach to socket programming. 

 PROGRAMMING CONCEPT:
 The W5200 is designed is an intermediate layer between the low level SPI bus and higher
 level sockets. The W5200 object encapsulates the SPI bus and exposes the bus through
 methods to the higher level objects.  The higher level Socket object further encapsulates
 the W5200 into a few methods.  At the socket level the SPI driver is abstacted.    
  
 The programmer does not have to know much about the interworkings of the W5200 or the SPI bus.
 However, the logic is openly pubished here in the W5200 and SpiPasm.   

 ┌─────────────────┐
 │ Socket Object   │
 ├─────────────────┤
 │ W5200 Object    │
 ├─────────────────┤
 │ SPI Driver      │
 └─────────────────┘

 STRUCTURE:
 W5200.spin is like a large structure. The majority of the methods are simply
 writing to W5200 registers. The Rx and Tx PUBs are the only methods
 that contain processing logic which happens to be a circular buffer handler.

 All methods utimately resolve to the following SPI interface methods.
  * Read
  * Write

  Below are two methods that read W5200 common registers.
  
        GetRxBytesToRead(socket)
          return ReadSocketWord(socket, S_RX_RCV_SIZE0)
         
        GetFreeTxSize(socket)
          return ReadSocketWord(socket, S_TX_FREE0)

  The only difference bwtween these methods are the constants; S_RX_RCV_SIZE0
  and S_TX_FREE0.  However, the method name is a little more human readable.
  That's the jist of the W5200 object.  It simply wraps W5200 register read and
  writes into humam readable method names.

  There is one more item to mention.  The W5200 object also holds network
  paramters; DNS server, DHCP, and Router (Gateway).  DNS and DHCP objects
  populate these paramters.


}
'*********************************************************************************************
CON
  {{ W5200 Common register enumeration }}
  '      1              2              3              4              5              6
  '--------------------|--------------|--------------|--------------|--------------|-------------|    
  #0000,  MODE_REG,{
  01-04}  GATEWAY0,      GATEWAY1,      GATEWAY2,      GATEWAY3,{
  05-08}  SUBNET_MASK0,  SUBNET_MASK1,  SUBNET_MASK2,  SUBNET_MASK3,{
  09-0E}  MAC0,          MAC1,          MAC2,          MAC3,          MAC4,          MAC5,{
  0F-12}  SOURCE_IP0,    SOURCE_IP1,    SOURCE_IP2,    SOURCE_IP3,{
  13-14}  RES13,RES14,{
  15}     INTR,{
  16}     INTM2,{
  17-18}  RTIME0,        RTIME1,{
  19}     RETRY_COUNT,{
  1A-1B}  RES1A,         RES1B,{
  1C-1D}  P_AUTH_TYPE0,  P_AUTH_TYPE1,{
  1E}     PPPALGO,{
  1F}     VERSION,{
  20-27}  RES20,RES21,RES22,RES23,RES24,RES25,RES26,RES27,{
  28}     PTIMER,{
  29}     PMAGIC,{
  2A-2F}  RES2A,RES2B,RES2C,RES2D,RES2E,RES2F, {
  30-31}  INTLR0,        INTLR1,{
  32-33}  IR2,{
  34}     PSTATUS,{
  36}     IMR                                                                                               

  {{ W5200  Socket Register Base Addresses }}
  #0000,  S_MR,{
 01     } S_CR,{
 02     } S_IR,{
 03     } S_SR,{
 04-05  } S_PORT0,      S_PORT1,{
 06-0B  } S_DEST_MAC0,  S_DEST_MAC1,   S_DEST_MAC2,   S_DEST_MAC3,   S_DEST_MAC4,   S_DEST_MAC5,{
 0C-0F  } S_DEST_IP0,   S_DEST_IP1,    S_DEST_IP2,    S_DEST_IP3,{
 10-11  } S_DEST_PORT0, S_DEST_PORT1,{
 12-13  } S_MAX_SEGM0,  S_MAX_SEGM1,{
 14     } S_PROTOCOL,{
 15     } S_TOS,{
 16     } S_TTL,{
 17-1D  } S_RES17,S_RES18,S_RES19,S_RES1A,S_RES1B,S_RES1C,S_RES1D,{
 1E     } S_RX_MEM_SIZE, {
 1F     } S_TX_MEM_SIZE, {
 20-21  } S_TX_FREE0,   S_TX_FREE1,{
 22-23  } S_TX_R_PTR0,  S_TX_R_PTR1, {
 24-25  } S_TX_W_PTR0,  S_TX_W_PTR1, {
 26-27  } S_RX_RCV_SIZE0,S_RX_RCV_SIZE1,{
 28-29  } S_RX_R_PTR0,  S_RX_R_PTR1, {
 2A-2B  } S_RX_W_PTR0,  S_RX_W_PTR1, {
 2C     } S_INT_MASK, {
 2D-2E  } S_IP_HEADER_FRAG_OFFSET {
         Reservered $4n30 to $4nFF}
         
  {{Socket Register Offsets}}
  SOCKET_BASE_ADDRESS = $4000
  SOCKET_REG_SIZE     = $0100

  {{ Socket Buffer Defaults }}
  INTERNAL_RX_BUFFER_ADDRESS    = $C000
  INTERNAL_TX_BUFFER_ADDRESS    = $8000
  DEFAULT_RX_TX_BUFFER          = $800
  DEFAULT_RX_TX_BUFFER_MASK     = DEFAULT_RX_TX_BUFFER - 1

  {{ Socket Command Register }}
  OPEN              = $01
  LISTEN            = $02
  CONNECT           = $04
  DISCONNECT        = $08
  CLOSE             = $10
  SEND              = $20
  SEND_MAC          = $21
  SEND_KEEP         = $22
  RECV              = $40
  'ADSL 
  #$23, PCON, PDISCON, PCR, PCN, PCJ
  
  {{ Status Register States}}
  SOCK_CLOSED       = $00
  SOCK_INIT         = $13
  SOCK_LISTEN       = $14
  SOCK_ESTABLISHED  = $17
  SOCK_CLOSE_WAIT   = $1C
  SOCK_UPD          = $22
  SOCK_IPRAW        = $32
  SOCK_MACRAW       = $42
  SOCK_PPPOE        = $5F
  {{ Status Change States }}
  SOCK_SYSENT       = $15
  SOCK_SYNRECV      = $16
  SOCK_FIN_WAIT     = $18
  SOCK_CLOSING      = $1A
  SOCK_TIME_WAIT    = $1B
  SOCK_LAST_ACK     = $1D
  SOCK_ARP          = $01


  'MACRAW and PPPOE can only be used with socket 0
  #0, CLOSED, TCP, UDP, IPRAW, MACRAW, PPPOE
  
  {{ Buffers }}
  BUFFER_2K         = $800
  BUFFER_WS         = $20

  {{ Number of Sockets }}
  SOCKETS           = 8

  {{ Command Op Codes }}
  #0, READ_OPCODE, WRITE_OPCODE

  { Spinneret PIN IO  
  SPI_MISO          = 0 ' SPI master in serial out from slave 
  SPI_MOSI          = 1 ' SPI master out serial in to slave
  SPI_CS            = 2 ' SPI chip select (active low)
  SPI_SCK           = 3  ' SPI clock from master to all slaves
  WIZ_INT           = 13
  WIZ_RESET         = 14
  WIZ_SPI_MODE      = 15
  }
  
  {{ Dev Board PIN IO }}
  {
  SPI_SCK           = 0 ' SPI clock from master to all slaves
  SPI_MISO          = 2 ' SPI master in serial out from slave
  SPI_MOSI          = 1 ' SPI master out serial in to slave
  SPI_CS            = 3 ' SPI chip select (active low)
  'WIZ_POWER_DOWN    =  ' Power down (active high)       
  'WIZ_INT           = 0 ' Interupt (active low)
  WIZ_RESET         =  4' Reset (active low)
  }
  {{ WizNet W5200 for QuickStart PIN IO }}
  {   }  
  SPI_SCK           = 12 ' SPI clock from master to all slaves
  SPI_MISO          = 13 ' SPI master in serial out from slave
  SPI_MOSI          = 14 ' SPI master out serial in to slave
  SPI_CS            = 15 ' SPI chip select (active low)
  WIZ_POWER_DOWN    = 24 ' Power down (active high)       
  WIZ_INT           = 25 ' Interupt (active low)
  WIZ_RESET         = 26 ' Reset (active low)

  
DAT
  _mode           byte  %0000_0000                      'enable ping  
  _dns1           byte  $00, $00, $00, $00
  _dns2           byte  $00, $00, $00, $00
  _dns3           byte  $00, $00, $00, $00

  workSpace       byte  $0[BUFFER_WS]
  
  sockRxMem       byte  $02[SOCKETS]
  sockTxMem       byte  $02[SOCKETS]
  sockRxBase      word  INTERNAL_RX_BUFFER_ADDRESS[SOCKETS]
  sockRxMask      word  DEFAULT_RX_TX_BUFFER_MASK[SOCKETS]
  sockTxBase      word  INTERNAL_TX_BUFFER_ADDRESS[SOCKETS]
  sockTxMask      word  DEFAULT_RX_TX_BUFFER_MASK[SOCKETS]

  null            long  $00

  _flushB1         long  $00
  _flushB2         long  $00

  _cnt1      long  $00
  _cnt2      long  $00
  

OBJ
  'spi           : "Spi.spin"
  'spi           : "SpiPasm.spin" 
  spi           : "SpiCounterPasm.spin"

PUB Cnt1
  return spi.Cnt1

PUB Cnt2
  return spi.Cnt2


PUB Start(m_cs, m_clk, m_mosi, m_miso)
{{
DESCRIPTION:
  Initialize default values.  All 8 Rx/Tx bufffers are set to 2k.

PARMS:
  m_cs   - SPI chip select (active low)
  c_clk  - SPI clock from master to all slaves
  m_mosi - SPI master out serial in to slave
  m_miso - SPI master in serial out from slave 

RETURNS:
  Nothing
}}
  'Init the SPI bus
  spi.Init( m_cs, m_clk, m_mosi, m_miso )
  'SoftReset 

  SetCommonDefaults

  'Set up the interrupt mask register
  SetIMR2($FF)

PUB QS_Init
{{
DESCRIPTION:
  Initialize default values for the WizNet 5200 for QuickStart board.
  
  All 8 Rx/Tx bufffers are set to 2k.

PARMS:
  None

RETURNS:
  Nothing
}}
  HardReset(WIZ_RESET)
  waitcnt(((clkfreq / 1_000 * 1500) #> 381) + cnt )
  Start(SPI_CS, SPI_SCK, SPI_MOSI, SPI_MISO)

PUB ReStart
  spi.ReStart

PUB Stop
  spi.Stop

PUB GetCogId
  return spi.GetCogId
  
PUB HardReset(pin) | uSec, mSec
{{
DESCRIPTION:
  Reset the W5200.  This action will clear all W5200 register values  

PARMS:
  Pin     - W5200 reset pin 

RETURNS:
  Nothing
}}
                                                         
  uSec := ((clkfreq / 1_000_000) * 5) #> 381
  mSec := ((clkfreq / 1_000) * 200) #> 381 
  
  dira[pin]~~
  outa[pin]~
  waitcnt(uSec + cnt)
  outa[pin]~~
  waitcnt(mSec + cnt)
  dira[pin]~
  'waitcnt(mSec*5 + cnt) 
  

  
PUB SoftReset
{{
DESCRIPTION:
  Software reset will clear all W5200 register values  

PARMS:
  None

RETURNS:
  Nothing
}}
  bytemove(@workspace, %1000_0000, 1)
  Write(MODE_REG, @workspace, 1)


PUB PowerDown(pin)
{{
DESCRIPTION:
   

PARMS:
  None

RETURNS:
  Nothing
}}
  dira[pin]~~
  outa[pin]~~

PUB PowerUp(pin)
{{
DESCRIPTION:
   

PARMS:
  None

RETURNS:
  Nothing
}}
  dira[pin]~~
  outa[pin]~
  
PUB IsInt(pin)
{{
DESCRIPTION:
  Read the W5200 Interupt pin. A high on the nInt pin means an
  interupt has occured. Use GetSocketIR(sock) to read a socket interupt
  status byte.  wiz.SetSocketIR(sock, $FF) will reset the socket interupt.  

PARMS:
  Pin     - W5200 pin to read.  

RETURNS:
  Nothing
}}
  dira[pin]~
  return ina[pin] 

  
PUB InitSocket(socket, protocol, port)
{{
DESCRIPTION:
  Initialize a socket.
  W5100 has 4 sockets
  W5200 has 8 sockets

PARMS:
  socket    - Socket ID to initialize (0-n)
  protocol  - TCP/UPD
  port      - Listener port (0-65535)  

RETURNS:
  Nothing
}}
  SetSocketMode(socket, protocol)
  SetSocketPort(socket, port)

'----------------------------------------------------
' Receive data
'----------------------------------------------------  
PUB Rx(socket, buffer, length) | src_mask, src_ptr, upper_size, left_size
{{
DESCRIPTION:
  Read the Rx socket(n) buffer into HUB memory.  The W5200/W5100
  use a circlar buffer. If the buffer is 100 bytes, we're
  currently at 91 and receice 20 bytes the first 10 bytes fill
  addresses 91-100. The remaining 10 bytes fill addresses 0-9.

  The Rx method figures ot if the buffer wraps an updates the
  buffer pointers for the next read.

PARMATERS:
  socket    - Socket ID
  buffer    - Pointer to HUB memory
  length    - Bytes to read into HUB memory

RETURNS:
  Nothing
}}
  'Rx memory buffer offset and Physical Rx buffer address
  src_mask := GetRxReadPointer(socket) & sockRxMask[socket]
  src_ptr :=  src_mask + sockRxBase[socket]

  'Check for Rx buffer wrap
  if((src_mask + length) > (sockRxMask[socket] + 1))
  
    'Data wraps, get the upper buffer, read into HUB memory
    'and update the buffer pointer
    upper_size := sockRxMask[socket] + 1 - src_mask
    Read(src_ptr, buffer, upper_size)
    buffer += upper_size
    
    'Calculate the remaining byte and read Rx into
    'HUB memory starting at the base buffer address
    left_size := length - upper_size
    Read(sockRxBase[socket] , buffer, left_size)
    
  else
    'The data did not wrap, just copy Rx to HUB memory
    Read(src_ptr, buffer, length)

  'Update the current Rx read buffer pointer
  length += GetRxReadPointer(socket)
  SetRxReadPointer(socket, length)

  'Set the command register to receive
  SetSocketCommandRegister(socket, RECV) 

'----------------------------------------------------
' Transmit data
'----------------------------------------------------
PUB Tx(socket, buffer, length) | dst_mask, dst_ptr, upper_size, left_size, ptr
{{
DESCRIPTION:
  Write HUB memory to the socket(n) Tx buffer.  If the Tx buffer is 100
  bytes, we're  currently pointing to 91, and we need to transmit 20 bytes
  the first 10 byte fill addresses 91-100. The remaining 10 bytes
  fill addresses 0-9.

PARMS:
  socket    - Socket ID
  buffer    - Pointer to HUB memory
  length    - Bytes to write to the socket(n) buffer
  
RETURNS:
  Nothing
}}
  'Calculate the physical socket(n) Tx address
  ptr := GetTxWritePointer(socket)
  dst_mask := ptr & sockTxMask[socket]  
  dst_ptr :=  sockTxBase[socket] + dst_mask
  
  if((dst_mask + length) > (sockTxMask[socket] + 1))
    'Wrap and write the Tx data
    upper_size := (sockTxMask[socket] + 1) - dst_mask
    Write(dst_ptr, buffer, upper_size)
    buffer += upper_size
    left_size := length - upper_size
    Write(sockTxBase[socket], buffer, left_size)
  else
    Write(dst_ptr, buffer, length)

  'Set Tx pointers for the next Tx
  SetTxWritePointer(socket, length+ptr)

  'Send
  return  FlushSocketBuffer(socket, length)
  'FlushSocket(socket)
  'return length
  

PUB FlushSocketBuffer(socket, length) | bytesSent, ptr_txrd1, ptr_txrd2 
{{
DESCRIPTION: Send buffered socket(n) data 

PARMS:
  socket    - Socket ID 
  
RETURNS: Nothing
}}

  '_flushB1 := _flushB2 := 0

  bytesSent := ptr_txrd1:= ptr_txrd2 := 0
  ptr_txrd1 := GetTxReadPointer(socket)
   
  FlushSocket(socket)
    
  ptr_txrd2 := GetTxReadPointer(socket)
  
  if(ptr_txrd2 => ptr_txrd1)
    bytesSent := ptr_txrd2 - ptr_txrd1
    '_flushB1 :=  bytesSent
  else
    bytesSent :=  $FFFF - ptr_txrd1 + ptr_txrd2 + 1
   ' _flushB2  := bytesSent
    '

  if(bytesSent < length AND bytesSent > 0)
    FlushSocket(socket)  
    ptr_txrd2 := GetTxReadPointer(socket)
     
    if( ptr_txrd2 => ptr_txrd1)
      bytesSent := ptr_txrd2 - ptr_txrd1
    else
      bytesSent :=  $FFFF - ptr_txrd1 + ptr_txrd2 + 1

  return bytesSent
    
PUB FlushSocket(socket)
  SetSocketCommandRegister(socket, SEND)
 
'----------------------------------------------------
' Socket Buffer Pointer Methods
'----------------------------------------------------
PUB GetMaximumSegmentSize(socket)
  return ReadSocketWord(socket, S_MAX_SEGM0)
  
PUB GetTimeToLive(socket)
  return ReadSocketByte(socket, S_TTL)

PUB SetTimeToLive(socket, value)
  SocketWriteByte(socket, S_TTL, value)
  

PUB GetRxBytesToRead(socket)
{{
DESCRIPTION:
  Read socket(n) receive size register
  
PARMS:
  socket    - Socket ID
    
RETURNS:
  2 bytes: Number of bytes received
}}
  return ReadSocketWord(socket, S_RX_RCV_SIZE0)

PUB GetFreeTxSize(socket)
{{
DESCRIPTION:
  Read 2 byte socket(n) Tx available size register
  
PARMS:
  socket    - Socket ID
   
RETURNS:
  2 bytes: Socket(n) available Tx size   
}}
  return ReadSocketWord(socket, S_TX_FREE0)

PUB GetRxReadPointer(socket)
{{
DESCRIPTION: Read socket(n) Rx read pointer

PARMS:
  socket    - Socket ID
  
RETURNS: 2 bytes: Socket(n) Rx read pointer   
}}
  return ReadSocketWord(socket, S_RX_R_PTR0)

PUB SetRxReadPointer(socket, value)
{{
DESCRIPTION: Write socket(n) Rx read pointer

PARMS:
  socket    - Socket ID
  
RETURNS: Nothing  
}}
  SocketWriteWord(socket, S_RX_R_PTR0, value) 


{ ****  Debug
PUB GetTxWritePointer(socket) | rc1, rc2
{{
DESCRIPTION: Read socket(n) Tx write pointer

PARMS:
  socket    - Socket ID
  
RETURNS: 2 bytes: Socket(n) Tx write pointer   
}}
  rc1 := 0
  rc2 := 1
  repeat until rc1 == rc2
    rc2 := ReadSocketWord(socket, S_TX_W_PTR0)
    ifnot(rc2 == 0)
      rc1 := ReadSocketWord(socket, S_TX_W_PTR0)
  return rc1
 *****}
 
PUB GetTxWritePointer(socket)
{{
DESCRIPTION: Read socket(n) Tx write pointer

PARMS:
  socket    - Socket ID
  
RETURNS: 2 bytes: Socket(n) Tx write pointer   
}}
  return ReadSocketWord(socket, S_TX_W_PTR0)
  
PUB SetTxWritePointer(socket, value)
{{
DESCRIPTION: Write socket(n) Tx write pointer 

PARMS:
  socket    - Socket ID 
  
RETURNS: 2 bytes: Socket(n) Tx write pointer 
}}
  SocketWriteWord(socket, S_TX_W_PTR0, value)

PUB GetTxReadPointer(socket)
{{
DESCRIPTION: Read socket(n) Tx read pointer 

PARMS:
  socket    - Socket ID 
  
RETURNS: 2 bytes: Socket(n) Tx read pointer 
}}
  return ReadSocketWord(socket, S_TX_R_PTR0)

PUB SocketRxSize(socket)
{{
DESCRIPTION: Configuration: Rx socket(n) size in bytes 

PARMS:
  socket    - Socket ID 
  
RETURNS: Rx socket(n) size in bytes 
}}
  return sockRxMem[socket] * 1024

PUB SocketTxSize(socket)
{{
DESCRIPTION: Configuration: Tx socket(n) size in bytes 

PARMS:
  socket    - Socket ID 
  
RETURNS: Tx socket(n) size in bytes
}}
  return sockTxMem[socket] * 1024
  
'----------------------------------------------------
' Socket Commands
'----------------------------------------------------  
PUB OpenSocket(socket)
{{
DESCRIPTION: Open socket(n)

PARMS:
  socket    - Socket ID  
  
RETURNS: Nothing
}}
  SetSocketCommandRegister(socket, OPEN)

PUB StartListener(socket)
{{
DESCRIPTION: Listen on socket(n)

PARMS:
  socket    - Socket ID 
  
RETURNS: Nothing
}}
  SetSocketCommandRegister(socket, LISTEN)



PUB OpenRemoteSocket(socket)
{{
DESCRIPTION: Connect remote socket(n)

PARMS:
  socket    - Socket ID  
  
RETURNS: Nothing
}}
  SetSocketCommandRegister(socket, CONNECT)  

PUB DisconnectSocket(socket)
{{
DESCRIPTION: Disconnect socket(n)

PARMS:
  socket    - Socket ID 
  
RETURNS: Nothing
}}
  SetSocketCommandRegister(socket, DISCONNECT)

PUB CloseSocket(socket)
{{
DESCRIPTION: Close socket(n)

PARMS:
  socket    - Socket ID 
  
RETURNS: Nothing
}}
  SetSocketCommandRegister(socket, CLOSE)
  
'----------------------------------------------------
' Socket Status
'----------------------------------------------------
PUB IsInit(socket)
{{
DESCRIPTION: Determine if the socket is initialized

PARMS:
  socket    - Socket ID 
  
RETURNS: True if the socket is initialized; otherwise returns false. 
}}
  return GetSocketStatus(socket) ==  SOCK_INIT

PUB IsEstablished(socket)
{{
DESCRIPTION: Determine if the socket is established

PARMS:
  socket    - Socket ID 
  
RETURNS: True if the socket is established; otherwise returns false. 
}}
  return GetSocketStatus(socket) ==  SOCK_ESTABLISHED

PUB IsCloseWait(socket)
{{
DESCRIPTION: Determine if the socket is close wait

PARMS:
  socket    - Socket ID 
  
RETURNS: True if the socket is close wait; otherwise returns false. 
}}
  return GetSocketStatus(socket) ==  SOCK_CLOSE_WAIT

PUB IsClosed(socket)
{{
DESCRIPTION: Determine if the socket is closed

PARMS:
  socket    - Socket ID 
  
RETURNS: True if the socket is closed; otherwise returns false. 
}}
  return GetSocketStatus(socket) ==  SOCK_CLOSED

PUB SocketStatus(socket)
{{
DESCRIPTION: Read the status of socket(n)

PARMS:
  socket    - Socket ID 
  
RETURNS: Byte: Socket(n) status register
}}
  return GetSocketStatus(socket)  

'----------------------------------------------------
' Common Register Initialize Methods
'----------------------------------------------------
PUB SetCommonDefaults
  bytefill(@workspace, 0, BUFFER_WS)
  bytemove(@workspace, @_mode,1)
  Write(MODE_REG, @workspace, 19)
  'SetCommonnMode(0)
  SetDefault2kRxTxBuffers

PUB SetCommonnMode(value)
  workSpace := value & $FF 
  Write(MODE_REG, @workSpace, 1)     
 
PUB SetGateway(octet3, octet2, octet1, octet0)
  workSpace[0] := octet3 
  workSpace[1] := octet2
  workSpace[2] := octet1
  workSpace[3] := octet0
  'long[@gateway] := octet3 << 8 + octet2 << 16 + octet1 << 24 + octet0
  Write(GATEWAY0, @workSpace, 4)

PUB SetSubnetMask(octet3, octet2, octet1, octet0)
  workSpace[0] := octet3 
  workSpace[1] := octet2
  workSpace[2] := octet1
  workSpace[3] := octet0
  Write(SUBNET_MASK0, @workSpace, 4) 

PUB SetMac(octet5, octet4, octet3, octet2, octet1, octet0)
  workSpace[0] := octet5 
  workSpace[1] := octet4
  workSpace[2] := octet3
  workSpace[3] := octet2
  workSpace[4] := octet1
  workSpace[5] := octet0
  Write(MAC0, @workSpace, 6)

PUB SetIp(octet3, octet2, octet1, octet0)
  workSpace[0] := octet3 
  workSpace[1] := octet2
  workSpace[2] := octet1
  workSpace[3] := octet0
  Write(SOURCE_IP0, @workSpace, 4 )

PUB RemoteIp(socket, octet3, octet2, octet1, octet0)
  workSpace[0] := octet3 
  workSpace[1] := octet2
  workSpace[2] := octet1
  workSpace[3] := octet0
  Write(GetSocketRegister(socket, S_DEST_IP0), @workSpace, 4)
  return @workspace


'----------------------------------------------------
' Common Register Properties
'----------------------------------------------------
PUB GetIp
{{
DESCRIPTION:

PARMS:
  
RETURNS:
  
}}
  Read( SOURCE_IP0, @workspace, 4 )
  return @workspace
  
PUB GetSubnetMask
  Read( SUBNET_MASK0, @workspace, 4)
   return @workspace
    
PUB GetRemoteIp(socket)
  Read(GetSocketRegister(socket, S_DEST_IP0), @workspace, 4)
  return @workspace 

PUB SetRemotePort(socket, port)
  SocketWriteWord(socket, S_DEST_PORT0, port)
  
PUB GetGatewayIp
  Read( GATEWAY0, @workspace, 4)
  return @workspace

PUB GetMac
  Read( MAC0, @workspace, 6 )
  return @workspace  

PUB GetIR2
  return ReadByte(IR2)
  
PUB SetIR2(value)   
  WriteByte(IR2, value)

PUB GetIMR2
  return ReadByte(INTM2)

Pub SetIMR2(value)
  WriteByte(INTM2, value)

PUB GetVersion
  'bytefill(@workspace, null, BUFFER_32)
  return ReadByte(VERSION) 



'----------------------------------------------------
' DHCP and DNS
' These methods are accessed by DHCP and DNS
' objects
'----------------------------------------------------
PUB CopyDns(source, len)
{{
DESCRIPTION:

PARMS:
  
RETURNS:
  
}}
  bytemove(@_dns1, source, len)

PUB CopyGateway(source, len)
  bytemove(@workspace, source, len)
  Write(GATEWAY0, @workspace, 4)

PUB CopySubnet(source, len)
  bytemove(@workspace, source, len)
  Write(SUBNET_MASK0, @workspace, 4)

PUB GetDns
  return GetDnsByIndex(0)

PUB GetDnsByIndex(idx)
  if(IsNullIp( @_dns1 + idx*4 ) )
    return NULL
  return @_dns1 + idx*4
 

PRI IsNullIp(ipaddr)
  return (byte[ipaddr][0] + byte[ipaddr][1] + byte[ipaddr][2] + byte[ipaddr][3]) == 0    


'----------------------------------------------------
' Set defaults
'----------------------------------------------------     
PRI SetDefault2kRxTxBuffers | i
{{
DESCRIPTION:

PARMS:
  
RETURNS:
  
}}
  repeat i from 0 to 7
    sockRxMem[i] := $02
    sockTxMem[i] := $02
    
  repeat i from 0 to 7
    sockRxMask[i] := DEFAULT_RX_TX_BUFFER_MASK
    sockTxMask[i] := DEFAULT_RX_TX_BUFFER_MASK

  repeat i from 1 to 7
    sockRxBase[i] := sockRxBase[i-1] + DEFAULT_RX_TX_BUFFER
    sockTxBase[i] := sockTxBase[i-1] + DEFAULT_RX_TX_BUFFER

  'repeat i from 0 to 7
    'WriteByte(GetSocketRegister(i, S_RX_MEM_SIZE) , sockRxMem[i])
    'WriteByte(GetSocketRegister(i, S_TX_MEM_SIZE) , sockTxMem[i])  


'----------------------------------------------------
' Wrapped Socket Register Methods
'----------------------------------------------------
PRI SetSocketMode(socket, value)
{{
DESCRIPTION:

PARMS:
  
RETURNS:
  
}}
  SocketWriteByte(socket, S_MR, value)

PRI SetSocketPort(socket, port)
  SocketWriteWord(socket, S_PORT0, port)

PUB GetSocketPort(socket)
  return ReadSocketWord(socket, S_PORT0)

PRI SetSocketCommandRegister(socket, value)
  SocketWriteByte(socket, S_CR, value)

PRI GetSocketCommandRegister(socket)
  return SocketReadByte(socket, S_CR)

PUB GetSocketStatus(socket)
  return SocketReadByte(socket, S_SR)

PUB GetSocketIR(socket)
  return SocketReadByte(socket, S_IR)

PUB SetSocketIR(socket, value)
  SocketWriteByte(socket, S_IR, value)
  
'----------------------------------------------------
' Socket Helper Methods
'----------------------------------------------------
PRI ReadSocketWord(socket, register)
{{
DESCRIPTION:

PARMS:
  
RETURNS:
  
}}
  Read(GetSocketRegister(socket, register), @workSpace, 2)
  return DeserializeWord(@workSpace)

PRI ReadSocketByte(socket, register)
  return ReadByte(GetSocketRegister(socket, register)) 
  
PRI SocketWriteWord(socket, register, value)
  SerializeWord(value, @workSpace)
  Write(GetSocketRegister(socket, register), @workSpace, 2)

PRI SocketReadByte(socket, register)
  return ReadByte(GetSocketRegister(socket, register))
  
PRI SocketWriteByte(socket, register, value)
  WriteByte(GetSocketRegister(socket, register), value)

'----------------------------------------------------
' Helper Methods
'---------------------------------------------------- 
PUB SerializeWord(value, buffer)
{{
DESCRIPTION:

PARMS:
  
RETURNS:
  
}}
  byte[buffer++] := (value & $FF00) >> 8
  byte[buffer] := value & $FF 

PUB DeserializeWord(buffer) | value
  value := byte[buffer++] << 8
  value += byte[buffer]
  return value

PRI GetSocketRegister(sock, register)
  return sock * SOCKET_REG_SIZE + SOCKET_BASE_ADDRESS + register


'----------------------------------------------------
' SPI Interface
'----------------------------------------------------  
PRI Read(register, buffer, length) 
{{
DESCRIPTION:

PARMS:
  
RETURNS:
  
}}
  spi.Read(register, length, buffer)

PRI Write(register, buffer, length) 
  spi.Write(register, length, buffer)

    
PRI ReadByte(register) 
  spi.Read(register, 1, @workSpace)
  return workSpace[0] & $FF

PRI WriteByte(register, value) 
  workSpace[0] := value
  spi.Write(register, 1, @workSpace)

{  }  
PUB GetCommonRegister(register)
  return @_mode + register


CON

{{
 ______________________________________________________________________________________________________________________________
|                                                   TERMS OF USE: MIT License                                                  |                                                            
|______________________________________________________________________________________________________________________________|
|Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation    |     
|files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,    |
|modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software|
|is furnished to do so, subject to the following conditions:                                                                   |
|                                                                                                                              |
|The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.|
|                                                                                                                              |
|THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE          |
|WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR         |
|COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,   |
|ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                         |
 ------------------------------------------------------------------------------------------------------------------------------ 
}}