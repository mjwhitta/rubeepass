require "minitest/autorun"
require "pathname"
require "rubeepass"

class RPassTest < Minitest::Test
    def setup
        k="test/kdbx/kdf"
        @kdbx = [
            Pathname.new("#{k}3_aes_aes.kdbx").expand_path,
            Pathname.new("#{k}3_aes_aes.gz.kdbx").expand_path,
            Pathname.new("#{k}3_chacha20_aes.gz.kdbx").expand_path,
            Pathname.new("#{k}3_twofish_aes.gz.kdbx").expand_path,
            # Pathname.new("#{k}4_aes_aes.gz.kdbx").expand_path,
            # Pathname.new("#{k}4_aes_argon2.gz.kdbx").expand_path,
            # Pathname.new("#{k}4_chacha20_aes.gz.kdbx").expand_path,
            # Pathname.new("#{k}4_chacha20_argon2.gz.kdbx").expand_path,
            # Pathname.new("#{k}4_twofish_aes.gz.kdbx").expand_path,
            # Pathname.new("#{k}4_twofish_argon2.gz.kdbx").expand_path
        ]
        @keyfile1 = Pathname.new("test/key/bin.key").expand_path
        @keyfile2 = Pathname.new("test/key/hex.key").expand_path
        @keyfile3 = Pathname.new("test/key/key.xml").expand_path

        @aes = RubeePass.new(@kdbx[0], "asdf", @keyfile1).open
        @asdf = @aes.db.groups_by_name("asdf")[0]
        @bank = @asdf.groups_by_name("Bank")[0]
        @internet = @asdf.groups_by_name("Internet")[0]

        @chase = @bank.entries_by_title("Chase")[0]
        @facebook = @internet.entries_by_title("Facebook")[0]
        @google = @internet.entries_by_title("Google")[0]
    end

    def test_absolute_path
        assert_equal(@asdf.path, @aes.absolute_path("asdf"))
        assert_equal(
            @internet.path,
            @aes.absolute_path("Internet", "asdf")
        )
        assert_equal(
            @bank.path,
            @aes.absolute_path("../Bank", @internet.path)
        )
        assert_equal(
            @bank.path,
            @aes.absolute_path(@bank.path, @internet.path)
        )
        assert_equal("/asdf/Ban", @aes.absolute_path("/asdf/Ban"))
    end

    def test_additional_attributes
        assert_equal(Hash.new, @chase.additional_attributes)
    end

    def test_attachments
        assert(@chase.has_attachment?("rick.txt"))
        assert(!@chase.has_attachment?("Rick.txt"))
        assert(@chase.has_attachment_like?("Rick.txt"))
        assert_equal("roller\n", @chase.attachment("rick.txt"))
        assert_equal({"rick.txt" => "roller\n"}, @chase.attachments)
    end

    def test_attributes
        assert(@chase.has_attribute?("Password"))
        assert(!@chase.has_attribute?("password"))
        assert(@chase.has_attribute_like?("password"))
        assert_equal(@chase.password, @chase.attribute("Password"))
        assert_equal(@chase.password, @chase.attributes["Password"])
    end

    def test_find_group
        assert_equal(@asdf, @aes.find_group("asdf"))
        assert_nil(@aes.find_group("ASDF"))
        assert_equal(@asdf, @aes.find_group_like("ASDF"))
        assert_equal(@internet, @asdf.find_group("Internet"))
        assert_equal(@internet, @aes.find_group(@internet.path))
        assert_equal(@internet, @bank.find_group("../Internet"))
        assert_nil(@bank.find_group("../internet"))
        assert_equal(@internet, @bank.find_group_like("../internet"))
        assert_equal(@bank, @aes.find_group("asdf/Internet/../Bank"))
        assert_nil(@aes.find_group("blah"))
    end

    def test_has_entry
        assert(@bank.has_entry?("Chase"))
        assert(!@bank.has_entry?("chase"))
        assert(@bank.has_entry_like?("chase"))
    end

    def test_has_group
        assert(@asdf.has_group?("Internet"))
        assert(!@asdf.has_group?("internet"))
        assert(@asdf.has_group_like?("internet"))
    end

    def test_open_exception
        @kdbx.each do |kdbx|
            assert_raises(RubeePass::Error::InvalidPassword) do
                RubeePass.new(kdbx, "password").open
            end
        end
    end

    def test_open_no_exception
        @kdbx.each do |kdbx|
            RubeePass.new(kdbx, "asdf", @keyfile1).open
            RubeePass.new(kdbx, "asdf", @keyfile2).open
            RubeePass.new(kdbx, "asdf", @keyfile3).open
        end
    end

    def test_passwords
        assert_equal("chase_password", @chase.password)
        assert_equal("facebook_password", @facebook.password)
        assert_equal("google_password", @google.password)
    end
end
