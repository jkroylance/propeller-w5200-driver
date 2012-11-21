CON
  _clkmode = xtal1 + pll16x     
  _xinfreq = 5_000_000

  BUFFER_2K     = $800
  
  CR            = $0D
  LF            = $0A
  SOCKETS       = 4

  ' W5200 I/O
  SPI_MOSI      = 1 ' SPI master out serial in to slave
  SPI_SCK       = 0 ' SPI clock from master to all slaves
  SPI_CS        = 3 ' SPI chip select (active low)
  SPI_MISO      = 2 ' SPI master in serial out from slave
  RESET_PIN     = 4 ' Reset
  
  #0, CLOSED, TCP, UDP, IPRAW, MACRAW, PPPOE
    
VAR

DAT
  index         byte  "HTTP/1.1 200 OK", CR, LF, {
}                     "Content-Type: text/html", CR, LF, CR, LF, {
}                     "Hello World!", CR, LF, $0

  buff          byte  $0[BUFFER_2K]
  null          long  $00 

OBJ
  pst           : "Parallax Serial Terminal"
  wiz           : "W5200" 
  sock[4]       : "Socket"
 
PUB Main | i

  pst.Start(115_200)
  pause(500)

   'Set network parameters
  wiz.Start(SPI_CS, SPI_SCK, SPI_MOSI, SPI_MISO)
  wiz.HardReset(RESET_PIN)
  
  wiz.SetCommonnMode(0)
  wiz.SetGateway(192, 168, 1, 1)
  wiz.SetSubnetMask(255, 255, 255, 0)
  wiz.SetIp(192, 168, 1, 104)
  wiz.SetMac($00, $08, $DC, $16, $F8, $01)
  
  pst.str(string("Initialize Sockets",CR))
  repeat i from 0 to SOCKETS-1
    sock[i].Init(i, TCP, 8080)

  OpenListeners
  StartListners
      
  pst.str(string("Start Socket server",CR))
  MultiSocketServer
  pause(5000)

  
PUB OpenListeners | i
  pst.str(string("Open",CR))
  repeat i from 0 to SOCKETS-1  
    sock[i].Open
      
PUB StartListners | i
  repeat i from 0 to SOCKETS-1
    if(sock[i].Listen)
      pst.str(string("Listen "))
    else
      pst.str(string("Listener failed ",CR))
    pst.dec(i)
    pst.char(CR)

PUB CloseWait | i
  repeat i from 0 to SOCKETS-1  
    if(sock[i].IsCloseWait)
      sock[i].Disconnect
      sock[i].Open
      sock[i].Listen

PUB MultiSocketServer | bytesToRead, i
  bytesToRead := i := 0
  repeat
    pst.str(string("TCP Service", CR))
    CloseWait
    
   {
    repeat j from 0 to SOCKETS-1
      pst.str(string("Socket "))
      pst.dec(j)
      pst.str(string(" = "))
      pst.hex(wiz.GetSocketStatus(j), 2)
      pst.char(13)
    } 

    repeat until sock[i].Connected
      i := ++i // SOCKETS

    pst.str(string("Connected "))
    pst.dec(i)
    pst.char(CR)
    
    'Data in the buffer?
    repeat until NULL < bytesToRead := sock[i].Available

    'Check for a timeout
    if(bytesToRead < 0)
      pst.str(string("Timeout",CR))
      sock[i].Disconnect
      sock[i].Open
      sock[i].Listen
      bytesToRead~
      next
      
    'Get the Rx buffer
    pst.str(string("Copy Rx Data",CR))
    sock[i].Receive(@buff, bytesToRead)

    'Process the Rx data
    pst.char(CR)
    pst.str(string("Request:",CR))
    pst.str(@buff)

    pst.str(string("Send Response",CR))
    sock[i].Send(@index, strsize(@index))


    if(sock[i].Disconnect)
      pst.str(string("Disconnected", CR))
    else
      pst.str(string("Force Close", CR))
      
    sock[i].Open
    sock[i].Listen
    sock[i].SetSocketIR($FF)

    i := ++i // SOCKETS
    bytesToRead~
    
     
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