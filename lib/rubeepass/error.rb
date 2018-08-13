class RubeePass::Error < RuntimeError; end

require "rubeepass/error/file_not_found"
require "rubeepass/error/file_not_readable"
require "rubeepass/error/invalid_gzip"
require "rubeepass/error/invalid_header"
require "rubeepass/error/invalid_magic"
require "rubeepass/error/invalid_password"
require "rubeepass/error/invalid_protected_data"
require "rubeepass/error/invalid_protected_stream_key"
require "rubeepass/error/invalid_version"
require "rubeepass/error/invalid_xml"
require "rubeepass/error/not_salsa20"
require "rubeepass/error/not_supported"
