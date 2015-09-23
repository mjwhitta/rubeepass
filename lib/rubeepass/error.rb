class RubeePass::Error < RuntimeError
end

require "rubeepass/error/invalid_gzip_error"
require "rubeepass/error/invalid_header_error"
require "rubeepass/error/invalid_magic_error"
require "rubeepass/error/invalid_password_error"
require "rubeepass/error/invalid_protected_data_error"
require "rubeepass/error/invalid_protected_stream_key_error"
require "rubeepass/error/invalid_version_error"
require "rubeepass/error/not_aes_error"
require "rubeepass/error/not_salsa20_error"
