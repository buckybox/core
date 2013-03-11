require 'spec_helper'

include Bucky::TransactionImports

describe Bucky::TransactionImports::OmniImport do
  it 'should import the correct rows' do
    Bucky::TransactionImports::OmniImport.test.process.should eq([{:DATE=>"15/02/2013",
  :DESC=>"DEB '77-22-08 26108268 WWW.WELSHFRUITSTOC CD 7115 ",
  :AMOUNT=>"27.5",
  :raw_data=>
   {:date=>"15/02/2013",
    :trans_type=>"DEB",
    :sort_code=>"'77-22-08",
    :account_number=>"26108268",
    :description=>"WWW.WELSHFRUITSTOC CD 7115 ",
    :debt_amount=>nil,
    :credit_amount=>"27.5"}},
 {:DATE=>"15/02/2013",
  :DESC=>
   "FPI '77-22-08 26108268 DULEY LMM DULEY - THURSDAY 198959821141512001 ",
  :AMOUNT=>"24",
  :raw_data=>
   {:date=>"15/02/2013",
    :trans_type=>"FPI",
    :sort_code=>"'77-22-08",
    :account_number=>"26108268",
    :description=>"DULEY LMM DULEY - THURSDAY 198959821141512001 ",
    :debt_amount=>nil,
    :credit_amount=>"24"}},
 {:DATE=>"15/02/2013",
  :DESC=>
   "FPI '77-22-08 26108268 MS RUSSELL & DOCTO CHRISTIE 000000000026803143 ",
  :AMOUNT=>"16",
  :raw_data=>
   {:date=>"15/02/2013",
    :trans_type=>"FPI",
    :sort_code=>"'77-22-08",
    :account_number=>"26108268",
    :description=>"MS RUSSELL & DOCTO CHRISTIE 000000000026803143 ",
    :debt_amount=>nil,
    :credit_amount=>"16"}},
 {:DATE=>"15/02/2013",
  :DESC=>
   "FPI '77-22-08 26108268 WARD MJ&HE     PBM WARDEAKRING 53024055720433000N ",
  :AMOUNT=>"12",
  :raw_data=>
   {:date=>"15/02/2013",
    :trans_type=>"FPI",
    :sort_code=>"'77-22-08",
    :account_number=>"26108268",
    :description=>"WARD MJ&HE     PBM WARDEAKRING 53024055720433000N ",
    :debt_amount=>nil,
    :credit_amount=>"12"}},
 {:DATE=>"15/02/2013",
  :DESC=>"CHQ '77-22-08 26108268 44",
  :AMOUNT=>"-217.5",
  :raw_data=>
   {:date=>"15/02/2013",
    :trans_type=>"CHQ",
    :sort_code=>"'77-22-08",
    :account_number=>"26108268",
    :description=>"44",
    :debt_amount=>"217.5",
    :credit_amount=>nil}},
 {:DATE=>"15/02/2013",
  :DESC=>"DD '77-22-08 26108268 LONDON&ZURICHPLC 008798 ",
  :AMOUNT=>"-54.14",
  :raw_data=>
   {:date=>"15/02/2013",
    :trans_type=>"DD",
    :sort_code=>"'77-22-08",
    :account_number=>"26108268",
    :description=>"LONDON&ZURICHPLC 008798 ",
    :debt_amount=>"54.14",
    :credit_amount=>nil}},
 {:DATE=>"15/02/2013",
  :DESC=>"SO '77-22-08 26108268 T BLOWER BLOWER ",
  :AMOUNT=>"21.4",
  :raw_data=>
   {:date=>"15/02/2013",
    :trans_type=>"SO",
    :sort_code=>"'77-22-08",
    :account_number=>"26108268",
    :description=>"T BLOWER BLOWER ",
    :debt_amount=>nil,
    :credit_amount=>"21.4"}},
 {:DATE=>"14/02/2013",
  :DESC=>
   "FPI '77-22-08 26108268 JACKSON & JACKSON SUZY JACKSON 31023454163603000N ",
  :AMOUNT=>"21",
  :raw_data=>
   {:date=>"14/02/2013",
    :trans_type=>"FPI",
    :sort_code=>"'77-22-08",
    :account_number=>"26108268",
    :description=>"JACKSON & JACKSON SUZY JACKSON 31023454163603000N ",
    :debt_amount=>nil,
    :credit_amount=>"21"}},
 {:DATE=>"13/02/2013",
  :DESC=>
   "FPI '77-22-08 26108268 DULEY LMM DULEY - THURSDAY 291934914412312001 ",
  :AMOUNT=>"24",
  :raw_data=>
   {:date=>"13/02/2013",
    :trans_type=>"FPI",
    :sort_code=>"'77-22-08",
    :account_number=>"26108268",
    :description=>"DULEY LMM DULEY - THURSDAY 291934914412312001 ",
    :debt_amount=>nil,
    :credit_amount=>"24"}},
 {:DATE=>"13/02/2013",
  :DESC=>"DEB '77-22-08 26108268 HORTICULTURAL SPPL CD 7115 ",
  :AMOUNT=>"-372",
  :raw_data=>
   {:date=>"13/02/2013",
    :trans_type=>"DEB",
    :sort_code=>"'77-22-08",
    :account_number=>"26108268",
    :description=>"HORTICULTURAL SPPL CD 7115 ",
    :debt_amount=>"372",
    :credit_amount=>nil}},
 {:DATE=>"13/02/2013",
  :DESC=>"FPI '77-22-08 26108268 STEVENSON N M NATASHA RP4659983979662400 ",
  :AMOUNT=>"10",
  :raw_data=>
   {:date=>"13/02/2013",
    :trans_type=>"FPI",
    :sort_code=>"'77-22-08",
    :account_number=>"26108268",
    :description=>"STEVENSON N M NATASHA RP4659983979662400 ",
    :debt_amount=>nil,
    :credit_amount=>"10"}}])
  end

  it 'should skip the correct rows' do
    Bucky::TransactionImports::OmniImport.test2.process.each do |row|
      row[:DESC].should_not eq("Opening Balance")
      row[:DESC].should_not eq("Closing Balance")
    end
  end
end
