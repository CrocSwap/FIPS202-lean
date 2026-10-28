
/-! ## Pre-standard Keccak-256 (Ethereum) -/

#guard keccak256 [] = hex "c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470"
#guard keccak256 abc = hex "4e03657aea45a94fc7d47ba826c8d667c0d1e6e33a64a036ec44f58fa12d6c45"

/-! ## SP 800-185 examples -/

def key32 : List UInt8 := (List.range 32).map fun i => (0x40 + i).toUInt8

-- cSHAKE128 sample #1.
#guard cshake128 (hex "00010203") 32 [] (ascii "Email Signature") =
  hex "C1C36925B6409A04F1B504FCBCA9D82B4017277CB5ED2B2065FC1D3814D5AAF5"

-- cSHAKE256 sample #3.
#guard cshake256 (hex "00010203") 64 [] (ascii "Email Signature") =
  hex ("D008828E2B80AC9D2218FFEE1D070C48B8E4C87BFF32C9699D5B6896EEE0EDD1" ++
       "64020E2BE0560858D9C00C037E34A96937C561A74C412BB4C746469527281C8C")

-- KMAC128 sample #1.
#guard kmac128 key32 (hex "00010203") 32 [] =
  hex "E5780B0D3EA6F7D3A429C5706AA43A00FADBD7D49628839E3187243F456EE14E"

-- KMAC256 sample #4.
#guard kmac256 key32 (hex "00010203") 64 (ascii "My Tagged Application") =
  hex ("20C570C31346F703C9AC36C61C03CB64C3970D0CFC787E9B79599D273A68D2F7" ++
       "F69D4CC3DE9D104A351689F27CF6F5951F0103F33F4F24871024D9C27773A8DD")

-- cSHAKE with empty name and customization is SHAKE.
#guard cshake256 abc 64 [] [] = shake256 abc 64

end Fips202.Tests
