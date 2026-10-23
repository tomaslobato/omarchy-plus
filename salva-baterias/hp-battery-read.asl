DefinitionBlock ("", "SSDT", 2, "LOCAL", "HPBATRD", 1)
{
 External (\_SB.WMID, DeviceObj)
 External (\MSMT, MutexObj)
 External (\_SB.WMID.EHWB, FieldUnitObj)
 External (\_SB.WMID.HWRC, FieldUnitObj)
 External (\_SB.WMID.GHMI, MethodObj)
 Scope (\_SB.WMID)
 {
  Method (HBRD, 1, Serialized)
  {
   If (Acquire (\MSMT, 1000)) { Return (Package () { 255, Buffer () {} }) }
   EHWB = Arg0
   HWRC = 2
   GHMI (0, 0xFE)
   Local0 = HWRC
   Local1 = EHWB
   Release (\MSMT)
   Local2 = Package (2) { 0, Buffer (1) {} }
   Local2[0] = Local0
   Local2[1] = Local1
   Return (Local2)
  }
 }
}
