# 20180713_Day24



## Rails_ google Login

>https://github.com/zquestz/omniauth-google-oauth2



*Gemfile*

```ruby
# ominiauth
gem 'omniauth-google-oauth2'
```



### Google API Setup

* 구글 API 페이지에서 API key를 가져와야한다.

- Go to '[https://console.developers.google.com](https://console.developers.google.com/)'
- New project 생성.
- *사용자 인증 정보* 에서 OAuth 클라이언트 ID를 만든다.
- Get your API key at: <https://code.google.com/apis/console/> Note the Client ID and the Client Secret 
- *대시보드* -> *API 및 서비스 사용 설정* -> *Social* -> **Google+ API** 클릭 -> 사용자 인증정보 -> client_secret.json 다운을 다운받는다.



### Devise

#### figaro 설치

* api키를 숨기기 위해서 figaro를 설치해서 `application.yml` 파일을 만든다.

```ruby
gem 'figaro'
```

`$ bundle install`

`$ figaro install`

*config/application.yml*

```ruby
development:
        GOOGLE_CLIENT_ID: 입력
        GOOGLE_CLIENT_SECRET: 입력
```



*config/initializers/devise.rb*

```ruby
  config.omniauth :google_oauth2, ENV['GOOGLE_CLIENT_ID'], ENV['GOOGLE_CLIENT_SECRET'], 
  {
    scope: 'email',   #권한을 받을 때 이메일만 받겠다.
    prompt: 'select_account'
  }
```



`$ rails g migration add_columns_to_users`  : User 모델에 custom 컬럼을 추가하겠다.



*db/migrate/20180713013258_add_columns_to_users.rb*

```ruby
class AddColumnsToUsers < ActiveRecord::Migration[5.0]
  def change
    # add_columns :DB명(복수), :컬럼명, :타입
    add_column :users, :provider,    :string  
    add_column :users, :name,        :string
    add_column :users, :uid,         :string 
    # 필요한 정보있으면 더 추가 가능
  end
end
```

* provider : 어디서 정보가 날아왔는지 ( 구글 / 페이스북/ 네이버 등등)

* uid : 토큰, 인증받은 유저임을 알려준다. 처음 로그인한 이후에는 더이상 인증창뜨지않고 로그인된다. 

  

`$ rake db:migrate`



*app/models/user.rb*   : :omniauthable 추가

```ruby
...
  devise :database_authenticatable, :registerable, 
         :recoverable, :rememberable, :trackable, :validatable,
         :omniauthable, omniauth_providers: [:google_oauth2]  # 이 줄 추가
...
```



*routes.rb*

```ruby
...
  devise_for :users, controllers: { omniauth_callbacks: 'users/omniauth_callbacks' }
...
```



### 여기까지하면 */users/sign_in* 페이지에 <u>Sign in with GoogleOauth2</u>  버튼이 생긴다. 클릭하면 구글로 연결되지만 로그인은 아직 정상작동은 하지 않는 상태이다.

* **Error: redirect_uri_mismatch**   리디렉션 에러 발생

* 리디렉션 오류를 해결하기 위해서 Google API 사용자 인증정보 ->  *웹 애플리케이션의 클라이언트 ID*의  ***승인된 리디렉션 URI***에 google에러메세지(callback uri)에 있는 주소를 붙여넣고 저장한다.

* 새로고침하면 **Google  계정으로 로그인**(계정 선택) 화면이 뜬다. 

  

  

### But, 계정선택을 하면 routing error가  발생

* devise와 관련된 controller를 만들지않아서 발생하는 에러

`$ rails g devise:controllers users`   ( [문서 참고](<https://github.com/plataformatec/devise> ) )



controller 생성

      create  app/controllers/users/confirmations_controller.rb  # 컨펌메일
      create  app/controllers/users/passwords_controller.rb     
      create  app/controllers/users/registrations_controller.rb   # 회원가입관련 controller
      create  app/controllers/users/sessions_controller.rb		# 로그인
      create  app/controllers/users/unlocks_controller.rb			#계정을 잠그고열고할때 관련
      create  app/controllers/users/omniauth_callbacks_controller.rb  #외부 sns 로그인




*app/controllers/users/omniauth_callbacks_controller.rb*

```ruby
# frozen_string_literal: true

class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
   def google_oauth2
      # You need to implement the method below in your model (e.g. app/models/user.rb)
      p request.env('omniauth.auth')
      @user = User.from_omniauth(request.env['omniauth.auth'])  # user.rb의 access token

      if @user.persisted?
        flash[:notice] = I18n.t 'devise.omniauth_callbacks.success', kind: 'Google'
        sign_in_and_redirect @user, event: :authentication
      else
        session['devise.google_data'] = request.env['omniauth.auth'].except(:extra) # Removing extra as it can overflow some session stores
        redirect_to new_user_registration_url, alert: @user.errors.full_messages.join("\n")
      end
  end
end
```

`.persisted?` : 있으면 True, 없으면 False



*app/models/user.rb*

```ruby
def self.from_omniauth(access_token)
    data = access_token.info
    user = User.where(email: data['email']).first
        # Uncomment the section below if you want users to be created if they don't exist
     unless user
    #     user = User.create(name: data['name'],
    #        email: data['email'],
    #        password: Devise.friendly_token[0,20]
    #     )
    # end
    user
  end
```

* `unless user` 아래 주석을 해제하고 토큰정보를 받기위해서 컬럼을 추가한다. 우리는 구글 이메일로 로그인한 유저의 아이디를 만들어 주지않았으므로!

  ↓  ↓  ↓  ↓  ↓  

```ruby
...
def self.from_omniauth(access_token)  # 클래스 메소드
    data = access_token.info
    user = User.where(email: data['email']).first  #데이터가 해쉬형태여서 이메일을 찾아서 user에 넣어줌

    # Uncomment the section below if you want users to be created if they don't exist 
    unless user
        user = User.create(name: data['name'],
            email: data['email'],
            password: Devise.friendly_token[0,20],
            provider: access_token.provider,    # 우리가 추가한 컬럼 추가
            uid: access_token.uid
        )
    end
    user
end
...
```



* 정상적으로 구글로 로그인이 가능하다!

  ```ruby
   SQL (0.5ms)  INSERT INTO "users" ("email", "encrypted_password", "created_at", "updated_at", "provider", "name", "uid") VALUES (?, ?, ?, ?, ?, ?, ?)  [["email", "gksdnf719@gmail.com"], ["encrypted_password", "$2a$11$TAZqWtaxV9tpdN7L//wj8O5cg8JO/j3JHtY8Vgxt3mQgYjja8ekwy"], ["created_at", "2018-07-13 02:37:31.913422"], ["updated_at", "2018-07-13 02:37:31.913422"], ["provider", "google_oauth2"], ["name", "---"], ["uid", "---------------"]]
  ```

  * *add_columns_to_users.rb* 에서 추가한 컬럼들도 추가된 결과
  * 구글에서 정보를 넘겨준게 Insert된다.(*user.rb* 에서 User.create로 만들어짐) update로 id 부여

  





## kakao 로그인_API



* [카카오톡 api](https://developers.kakao.com/apps/212041/settings/user) 에서 앱만들기 -> 개요 -> 사용자관리 ON

* 설정-> 일반 -> 플랫폼을 추가(사이트 도메인: 서버주소)한다. 

* 리다이렉트 path에 콜백받는 url를 써주어야한다. 

* 여기서 devise_scope 사용해서 콜백uri를 만든다.

  

### devise_scope

*routes.rb*

```ruby
...
  devise_scope :user do
    get '/users/auth/kakao', to: 'users/omniauth_callbacks#kakao'  # 클릭하면 대신 요청을 보냄
    get '/users/auth/kakao/callback', to: 'users/omniauth_callbacks#kakao_auth'    # callback을 받는 친구
  end
...
```

* ` /users/auth/google_oauth2/callback` 형식과 같이 route를 설정한다.



#### 카카오는 요청을하면 카카오로그인페이지가나오고 정보를받아서 그 token가지고 사용자 정보받을 수 있다. 즉, google 로그인할때 요청하고 요청받는 작업이 2번 이루어진다고 생각하면 된다.



* 설정-> 일반 에서 *REST API 키* 를 가져와서 *config/application.yml*에 추가한다. 

* 개발가이드 -> REST API 도구에서 계정로그인



`$ rails generate devise:views`

*app/views/devise/sessions/new.html.erb* : 카카오로 로그인 버튼 추가

```erb
...
<%= link_to 'Sign in with Kakao', users_auth_kakao_path -%><br/>
```



[REST API 개발가이드_로그인](https://developers.kakao.com/docs/restapi/user-management#%EB%A1%9C%EA%B7%B8%EC%9D%B8)      ->  **[Request]** 복사해오기

*app/controllers/users/omniauth_callbacks_controllers.rb*

```ruby
...
  def kakao
    redirect_to "https://kauth.kakao.com/oauth/authorize?client_id=#{ENV['KAKAO_REST_API_KEY']}&redirect_uri=https://my-second-rails-app-hanullllje.c9users.io/users/auth/kakao/callback&response_type=code HTTP/1.1"
  end
...
```

* 여기까지 하면 토큰 uri는 완료, But 아직 에러발생



### 사용자 토큰 받기

* 코드를 얻은 다음, 이를 이용하여 실제로 API를 호출할 수 있는 사용자 토큰(Access Token, Refresh Token)을 받아 올 수 있다.

*app/controllers/users/omniauth_callbacks_controller.rb*

```ruby
...
  def kakao_auth
    code = params[:code]  # 요청해서 받은 코드
    base_url = "https://kauth.kakao.com/oauth/token"  
    base_response = RestClient.post(base_url, {grant_type: "authorization_code",
                                               client_id: ENV['KAKAO_REST_API_KEY'],
                                               redirect_uri: "https://my-second-rails-app-hanullllje.c9users.io/users/auth/kakao/callback",
                                               code: code})   #어디로 요청을 보낼지, parameter 보낼 key들 입력
    puts base_response
  end
...
```

-> 서버 실행 아직 error!

아래창에 base_response정보 `{"access_token":~~` 이 나온다.



* 요청을 한번더 보내서 email, name 을 받아와야 한다.

> [REST API 도구 - 사용자정보요청](https://developers.kakao.com/docs/restapi/tool)  



* base_response로 받은 token을 빼내야한다.

*app/controllers/users/omniauth_callbacks_controller.rb*

```ruby
...
  def kakao_auth
    code = params[:code]  # 요청해서 받은 코드
    base_url = "https://kauth.kakao.com/oauth/token"  
    base_response = RestClient.post(base_url, {grant_type: "authorization_code",
                                               client_id: ENV['KAKAO_REST_API_KEY'],
                                               redirect_uri: "https://my-second-rails-app-hanullllje.c9users.io/users/auth/kakao/callback",
                                               code: code})   #어디로 요청을 보낼지, parameter 보낼 key들 입력
    puts base_response
  end
...
```

↓ ↓ ↓ ↓ ↓

```ruby
...
  def kakao_auth
    code = params[:code]  # 요청해서 받은 코드
    base_url = "https://kauth.kakao.com/oauth/token"  
    base_response = RestClient.post(base_url, {grant_type: "authorization_code",
                                               client_id: ENV['KAKAO_REST_API_KEY'],
                                               redirect_uri: "https://my-second-rails-app-hanullllje.c9users.io/users/auth/kakao/callback",
                                               code: code})   #어디로 요청을 보낼지, parameter 보낼 key들 입력
    res = JSON.parse(base_response)
    access_token = res["access_token"]
    info_url= "https://kapi.kakao.com/v2/user/me"  # 카카오에서 요청정보 url을 가져옴
	info_response = RestClient.post(info_url, params:{secure_resource: false},
                                    Authorization: "Bearer #{access_token}")
                                    
    puts info_response
  end
...
```

↓ ↓ ↓ ↓ ↓

```ruby
...
    info_response = RestClient.get(info_url, Authorization: "Bearer #{access_token}") # 수정
     @user = User.from_omniauth_kakao(JSON.parse(info_response))
  end
...
```



이제 정보를 받아오는 것을 확인할 수 있다.

```bash
{"id":811949663,"properties":{"nickname":"--","profile_image":"http://k.kakaocdn.net/dn/op4xO/btqngOdZZAY/gZiDwhG1IKv1KEAO50TSkK/profile_640x640s.jpg","thumbnail_image":"http://k.kakaocdn.net/dn/op4xO/btqngOdZZAY/gZiDwhG1IKv1KEAO50TSkK/profile_110x110c.jpg"},"kakao_account":{"has_email":true,"is_email_valid":true,"is_email_verified":true,"email":"gksdnf719@naver.com","has_age_range":true,"has_birthday":true,"has_gender":true}}
```



