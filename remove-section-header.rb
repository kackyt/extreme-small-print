#!/bin/ruby

require 'fileutils'
SHT_PROGBITS = 1

open(ARGV[0]) do |f|
  data = f.read
  # unpack elf header
  headers = data.unpack('I4SSIQQQISSSSSS')
  puts "entry point = 0x#{headers[7].to_s(16)}"
  puts "program header offset = #{headers[8]}"
  puts "section header offset = #{headers[9]}"
  puts "program header size = #{headers[12] * headers[13]}"
  puts "section header size = #{headers[14] * headers[15]}"

  f.seek(headers[9])

  offset = headers[9]
  o_size = offset

  until f.eof?
    header_data = f.read(64)
    header = header_data.unpack('IIQQQQIIQQ')
    puts "name #{header[0]}"
    puts "type #{header[1]}"
    puts "addr #{header[3].to_s(16)}"
    # type == SHT_PROGBITS
    if header[1] == SHT_PROGBITS
      o_size = header[4] + header[5]
      break
    end
  end

  # reduce 8 byte
  headers[8] -= 8
  headers[11] -= 8
  # remove section header
  headers[9] = 0

  data_elf_header = headers.pack('I4SSIQQQISS')
  f.seek(64)
  data_program_header = f.read(56)
  program_header = data_program_header.unpack('IIQQQQQQ')
  program_header[2] -= 8
  
  data_program_header = program_header.pack('IIQQQQQQ')
  data_without_header = f.read(o_size - 64 - 56)

  open(ARGV[1], 'w') do |out|
    out.write(data_elf_header)
    out.write(data_program_header)
    out.write(data_without_header)
  end
  FileUtils.chmod(0755, ARGV[1])
end
