class AddColumnsToUsers < ActiveRecord::Migration[5.0]
  def change
    # add_columns :DB명, :컬럼명, :타입
    add_column :users, :provider,     :string  #provider: 어디서 정보가 날아왔니
    add_column :users, :name,        :string
    add_column :users, :uid,         :string  # 토큰, 따라서 첫번째 로그인하고 나면 더이상 여기서 로그인할거니? 이런거 안물어본다.
    # 필요한 정보있으면 더 추가 가능
  end
end
