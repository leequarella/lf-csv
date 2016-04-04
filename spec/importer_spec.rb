require 'lf-csv/importer'

describe LFCSV::Importer, "#Importer" do
  let(:csv_file){ File.read("spec/support/test.csv") }
  describe "column definition:" do
    it "allows columns to be defined" do
      LFCSV::Importer.column :column_a
      expect(LFCSV::Importer.header_aliases).to eq({
        column_a: {
          aliases: ["column_a"],
          required: false
        }
      })
    end

    it "allows columns to be defined with aliases" do
      LFCSV::Importer.column :column_a, ["column a"]
      expect(LFCSV::Importer.header_aliases).to eq({
        column_a:{
          aliases: ["column_a", "column a"],
          required: false
        }
      })
    end

    it "allows columns to be tagged as `required`" do
      LFCSV::Importer.column :column_a, required: true
      expect(LFCSV::Importer.header_aliases).to eq({
        column_a: {
          aliases: ["column_a"],
          required: true
        }
      })
    end
  end

  it "can be initialized with data" do
    importer = LFCSV::Importer.new(file: "A")
    expect(importer.file).to eq "A"
  end

  describe "processing csv files: " do
    context "when there are no required headers" do
      it "converts rows from a csv into hashes and passes them to `handle_row`" do
        LFCSV::Importer.column :column_a, ["column a"]
        importer = LFCSV::Importer.new(file: csv_file)

        expect(importer).to receive(:handle_row).with({
          column_a: "data from a"
        })
        importer.process
      end
    end

    context "when all required headers are present: " do
      it "converts rows from a csv into hashes and passes them to `handle_row`" do
        LFCSV::Importer.column :column_a, ["column a"], required: true
        importer = LFCSV::Importer.new(file: csv_file)

        expect(importer).to_not receive(:missing_column_headers)
        expect(importer).to receive(:handle_row).with({
          column_a: "data from a"
        })
        importer.process
      end
    end

    context "when a required header is missing:" do
      let(:importer){
        LFCSV::Importer.new(file: csv_file)
      }

      before(:each) do
        LFCSV::Importer.column :a_missing_column, required: true
        LFCSV::Importer.column :column_a, required: false
      end

      it "calls `missing_column_headers` and does not process any rows" do
        expect(importer).to_not receive(:handle_row)
        expect(importer).to receive(:missing_column_headers).with([:a_missing_column])
        importer.process
      end

      it "kicks an error telling user to implement `missing_column_headers` method" do
        expect{importer.process}.to raise_error RuntimeError
        #(
        #  "No method has been defined for handling this file when missing column headers.
        #   You must define a method named `missing_column_headers` in the class inheriting from LSCSV::Importer.
        #   You may allow `missing_column_headers` to accept the `missing_headers` arg which will be an array of headers missing."
        #)
      end
    end
  end
end
