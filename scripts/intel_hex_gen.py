def calc_checksum(record):
    return (-(sum(record)) & 0xFF)

def write_intel_hex(filename, depth):
    with open(filename, "w") as f:
        for addr in range(depth):
            # Example: initialize with a simple pattern (addr mod 512)
            word = addr & 0x1FF  # 9-bit value
            high = (word >> 8) & 0xFF
            low  = word & 0xFF

            byte_count = 2
            record_type = 0x00
            address = addr & 0xFFFF
            record = [byte_count, (address >> 8) & 0xFF, address & 0xFF, record_type, high, low]
            checksum = calc_checksum(record)
            line = ":{:02X}{:04X}{:02X}{:02X}{:02X}\n".format(
                byte_count, address, record_type, high, low
            )
            line = line.strip() + "{:02X}\n".format(checksum)
            f.write(line)
        
        # End-of-file record
        f.write(":00000001FF\n")

write_intel_hex("bram_init.hex", 65536)
print("Intel HEX file 'bram_init.hex' generated successfully!")
