CON
  _clkmode = xtal1 + pll16x     
  _xinfreq = 5_000_000

  BUFFER_2K     = $800
  
  CR            = $0D
  LF            = $0A
  RESET_PIN     = 4 
  
  #0, CLOSED, TCP, UDP, IPRAW, MACRAW, PPPOE
  
       
VAR

DAT
  request       byte  "GET /index.htm HTTP/1.1", CR, LF, {
}               byte  "User-Agent: Wiz5200", CR, LF, CR, LF, $0

  request2      byte  "GET /default.aspx HTTP/1.1", CR, LF, {
}               byte  "Host: agaverobotics.com", CR, LF, {
}               byte  "User-Agent: Wiz5200", CR, LF, CR, LF, $0

  localhost     byte  "GET /hello/index.htm HTTP/1.1", CR, LF, {
}               byte  "Host: 192.168.1.102", CR, LF, {
}               byte  "User-Agent: Wiz5200", CR, LF, CR, LF, $0

  google        byte  "GET /finance/historical?q=FB&output=csv HTTP/1.1", CR, LF, {
}               byte  "Host: finance.google.com", CR, LF, {
}               byte  "User-Agent: Wiz5200", CR, LF, CR, LF, $0

  buff          byte  $0[BUFFER_2K]
  null          long  $00
  
OBJ
  pst           : "Parallax Serial Terminal"
  sock          : "Socket"
  wiz           : "W5200" 



 
PUB Main | bytesToRead, buffer, bytesSent, receiving, totalBytes

  receiving := true
  bytesToRead := 0
  pst.Start(115_200)
  pause(500)


  'wiz.QS_Init
  wiz.HardReset(WIZ#WIZ_RESET)
  wiz.Start(WIZ#SPI_CS, WIZ#SPI_SCK, WIZ#SPI_MOSI, WIZ#SPI_MISO)
  
  'Set network parameters
  wiz.SetCommonnMode(0)
  wiz.SetGateway(192, 168, 1, 1)
  wiz.SetSubnetMask(255, 255, 255, 0)
  wiz.SetIp(192, 168, 1, 105)
  wiz.SetMac($00, $08, $DC, $16, $F8, $01)


  pst.str(string("Initialize", CR))
  'Initialize Socket 0 port 8080
  buffer := sock.Init(0, TCP, -1)


  
  'sock.RemoteIp(65, 98, 8, 151)  'www.agaverobotics.com
  sock.RemoteIp(74,125,224,194)   'Google 
  'sock.RemoteIp(192,168,1,102)   'Localhost 
  sock.RemotePort(80)

  pst.str(string(CR, "Begin Client Web request", CR))

  'Client
  'pst.str(string("Open", CR))
  
  sock.Open
  WriteHexDebugLine(string("Open"), sock.GetStatus, 2) 
  pause(200)
  
  'pst.str(string("Connect", CR))
  sock.Connect
  pause(500)
   
  'Connection?
  WriteHexDebugLine(string("Connect"), sock.GetStatus, 2)
  repeat until sock.Connected
    pause(10)

  WriteHexDebugLine(string("Connected"), sock.GetStatus, 2)
  
  pst.str(string("Send HTTP Header", CR)) 
  bytesSent := sock.Send(@google, strsize(@google))
  pst.str(string("Bytes Sent: "))
  pst.dec(bytesSent)
  pst.char(13)

  repeat while receiving 
    'Data in the buffer?
    bytesToRead := sock.Available
    totalBytes += bytesToRead
     
    'Check for a timeout
    if(bytesToRead < 0)
      receiving := false
      pst.str(string("Timeout", CR))
      return

    if(bytesToRead == 0)
      receiving := false
      pst.str(string("Done", CR))
      next 

    if(bytesToRead > 0) 
      'Get the Rx buffer  
      buffer := sock.Receive(@buff, bytesToRead)
      pst.str(buffer)
      
    bytesToRead~

  pst.str(string("Total Bytes: "))
  pst.dec(totalBytes)
  pst.char(13)
  
  pst.str(string(CR, "Disconnect", CR)) 
  sock.Disconnect
  sock.Close
  WriteHexDebugLine(string("Done"), sock.GetStatus, 2)
   

PRI WriteHexDebugLine(label, value, digits)
  pst.str(label)
  repeat 25 - strsize(label)
    pst.char(".")

  pst.hex(value, digits)
  pst.char(CR)
  
PRI WriteDebugLine(label, value, isNum)
    pst.str(label)
  repeat 25 - strsize(label)
    pst.char(".")
  if(isNum)
    pst.dec(value)
  else
    pst.str(value)
  pst.char(CR)


PUB PrintNameValue(name, value, digits) | len
  len := strsize(name)
  
  pst.str(name)
  repeat 30 - len
    pst.char($2E)
  if(digits > 0)
    pst.hex(value, digits)
  else
    pst.dec(value)
  pst.char(CR)


PUB DisplayMemory(addr, len, isHex) | j
  pst.str(string(13,"-----------------------------------------------------",13))
  pst.str(string(13, "      "))
  repeat j from 0 to $F
    pst.hex(j, 2)
    pst.char($20)
  pst.str(string(13, "      ")) 
  repeat j from 0 to $F
    pst.str(string("-- "))

  pst.char(13) 
  repeat j from 0 to len
    if(j == 0)
      pst.hex(0, 4)
      pst.char($20)
      pst.char($20)
      
    if(isHex)
      pst.hex(byte[addr + j], 2)
    else
      pst.char($20)
      if(byte[addr+j] == 0)
        pst.char($20)
      pst.char(byte[addr+j])

    pst.char($20) 
    if((j+1) // $10 == 0) 
      pst.char($0D)
      pst.hex(j+1, 4)
      pst.char($20)
      pst.char($20)  
  pst.char(13)
  
  pst.char(13)
  pst.str(string("Start: "))
  pst.dec(addr)
  pst.str(string(" Len: "))
  pst.dec(len)
  pst.str(string(13,"-----------------------------------------------------",13,13))
      
PUB PrintIp(addr) | i
  repeat i from 0 to 3
    pst.dec(byte[addr][i])
    if(i < 3)
      pst.char($2E)
    else
      pst.char($0D)
  
PRI pause(Duration)  
  waitcnt(((clkfreq / 1_000 * Duration - 3932) #> 381) + cnt)
  return