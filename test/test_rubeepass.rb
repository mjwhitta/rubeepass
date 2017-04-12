require "minitest/autorun"
require "pathname"
require "rubeepass"

class RPassTest < Minitest::Test
    def setup
        @kdbx = Pathname.new("test/asdf.kdbx").expand_path
        @keyfile1 = Pathname.new("test/asdf.xml").expand_path
        @keyfile2 = Pathname.new("test/asdf.key1").expand_path
        @keyfile3 = Pathname.new("test/asdf.key2").expand_path
        @keepass = RubeePass.new(@kdbx, "asdf", @keyfile1).open

        @db = @keepass.db
        @asdf = @db.groups["asdf"]
        @bank = @asdf.groups["Bank"]
        @internet = @asdf.groups["Internet"]

        @chase = @bank.entries["Chase"]
        @facebook = @internet.entries["Facebook"]
        @google = @internet.entries["Google"]
    end

    def test_absolute_path
        assert_equal(@asdf.path, @keepass.absolute_path("asdf"))
        assert_equal(
            @internet.path,
            @keepass.absolute_path("Internet", "asdf")
        )
        assert_equal(
            @bank.path,
            @keepass.absolute_path("../Bank", @internet.path)
        )
        assert_equal(
            @bank.path,
            @keepass.absolute_path(@bank.path, @internet.path)
        )
        assert_equal("/asdf/Ban", @keepass.absolute_path("/asdf/Ban"))
    end

    def test_additional_attributes
        assert_equal(Hash.new, @chase.additional_attributes)
    end

    def test_attachments
        assert(@chase.has_attachment?("rick.txt"))
        assert_equal("roller\n", @chase.attachment("rick.txt"))
        assert_equal({"rick.txt" => "roller\n"}, @chase.attachments)
    end

    def test_attributes
        assert(@chase.has_attribute?("Password"))
        assert_equal(@chase.password, @chase.attribute("Password"))
        assert_equal(@chase.password, @chase.attributes["Password"])
    end

    def test_find_group
        assert_equal(@asdf, @keepass.find_group("asdf"))
        assert_nil(@keepass.find_group("ASDF"))
        assert_equal(@asdf, @keepass.find_group_like("ASDF"))
        assert_equal(@internet, @asdf.find_group("Internet"))
        assert_equal(@internet, @keepass.find_group(@internet.path))
        assert_equal(@internet, @bank.find_group("../Internet"))
        assert_nil(@bank.find_group("../internet"))
        assert_equal(@internet, @bank.find_group_like("../internet"))
        assert_equal(
            @bank,
            @keepass.find_group("asdf/Internet/../Bank")
        )
        assert_nil(@keepass.find_group("blah"))
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
        assert_raises(RubeePass::Error::InvalidPassword) do
            RubeePass.new(@kdbx, "password").open
        end
    end

    def test_open_no_exception
        RubeePass.new(@kdbx, "asdf", @keyfile1).open
        RubeePass.new(@kdbx, "asdf", @keyfile2).open
        RubeePass.new(@kdbx, "asdf", @keyfile3).open
    end

    def test_passwords
        assert_equal("chase_password", @chase.password)
        assert_equal("facebook_password", @facebook.password)
        assert_equal("google_password", @google.password)
    end
end
