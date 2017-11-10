# Declarative Authorization

The declarative authorization plugin offers an authorization mechanism inspired 
by _RBAC_. The most notable distinction to other authorization plugins is the
declarative approach. That is, authorization rules are not defined
programmatically in between business logic but in an authorization configuration.

With programmatic authorization rules, the developer needs to specify which roles are
allowed to access a specific controller action or a part of a view, which is
not DRY. With a growing application code base roles' permissions often
change and new roles are introduced. Then, at several places of the source code
the changes have to be implemented, possibly leading to omissions and thus hard
to find errors. In these cases, a declarative approach as offered by decl_auth
increases the development and maintenance efficiency.


Plugin features
* Authorization at controller action level
* Authorization helpers for Views
* Authorization at model level
  * Authorize CRUD (Create, Read, Update, Delete) activities
  * Query rewriting to automatically only fetch authorized records
* DSL for specifying Authorization rules in an authorization configuration
* Support for Rails 4 and 5


Requirements
* An authentication mechanism 
  * User object in Controller#current_user
  * (For model security) Setting Authorization.current_user
* User objects need to respond to a method `:role_symbols` that returns an
  array of role symbols
See below for installation instructions.


There is a decl_auth screencast by Ryan Bates, nicely introducing the main concepts:
http://railscasts.com/episodes/188-declarative-authorization


## Quick Start

### Install

Declarative Authorization comes with an installer to make setup easy.

First, include ae_declarative_authorization in your gemfile.

```ruby
gem 'ae_declarative_authorization'
```

Next, bundle and install.

    $ bundle
    $ rails g authorization:install [UserModel=User] [field:type field:type ...] [--create-user --commit --user-belongs-to-role]

This installer will create a Role model, an admin and a user role, and set a
has_and_belongs_to_many relationship between the User model and the Role model.
It will also add a `role_symbols` method to the user model to meet
declarative_authorization's requirements. The default User model is User. You can override this by simply typing the name of a model as above.

You can create the model with the fields provided by using the `--create-user` option.

The `--commit` option will run `rake db:migrate` and `rake db:seed`.

The `--user-belongs-to-role` option will set up a one-to-many relationship between Users and Roles.
That is, each user has a role_id column and can only have one role. Role inheritance can be used
in authorization rules.

Finally, the installer also copies default authorization rules, as below.

### Generate Authorization Rules

To copy a default set of authorization rules which includes CRUD priveleges, run:

    $ rails g authorization:rules

This command will copy the following to `config/authorization_rules.rb`. Remember
to implement the requirements of this gem as described in the Installation section
at the end of this README if you do not use the above installer.

```ruby
authorization do
  role :guest do
    # add permissions for guests here, e.g.
    # has_permission_on :conferences, :to => :read
  end
  
  # permissions on other roles, such as
  # role :admin do
  #   has_permission_on :conferences, :to => :manage
  # end
  # role :user do
  #   has_permission_on :conferences, :to => [:read, :create]
  #   has_permission_on :conferences, :to => [:update, :delete] do
  #     if_attribute :user_id => is {user.id}
  #   end
  # end
  # See the readme or GitHub for more examples
end

privileges do
  # default privilege hierarchies to facilitate RESTful Rails apps
  privilege :manage, :includes => [:create, :read, :update, :delete]
  privilege :create, :includes => :new
  privilege :read, :includes => [:index, :show]
  privilege :update, :includes => :edit
  privilege :delete, :includes => :destroy
end
```

### Controller Authorization

For RESTful controllers, add `filter_resource_access`:

```ruby
class MyRestfulController < ApplicationController
  filter_resource_access
end
```

For a non-RESTful controller, you can use `filter_access_to`:

```ruby
class MyOtherController < ApplicationController
  filter_access_to :all
  # or a group: filter_access_to [:action1, :action2]
end
```


### View Authorization

Declarative Authorization will use `current_user` to check authorization.

```erb
<%= link_to 'Edit Post', edit_post_path(@post) if permitted_to? :update, @post %>
```


## Authorization Data Model

```
----- App domain ----|-------- Authorization conf ---------|------- App domain ------

                      includes                   includes
                       .--.                        .---.
                       |  v                        |   v
 .------.  can_play  .------.  has_permission  .------------.  requires  .----------.
 | User |----------->| Role |----------------->| Permission |<-----------| Activity |
 '------' *        * '------' *              * '------------' 1        * '----------'
                                                     |
                                             .-------+------.
                                          1 /        | 1     \ *
                                .-----------.   .---------.  .-----------.
                                | Privilege |   | Context |  | Attribute |
                                '-----------'   '---------'  '-----------'
```

In the application domain, each *User* may be assigned to *Roles* that should 
define the users' job in the application, such as _Administrator_. On the 
right-hand side of this diagram, application developers specify which *Permissions* 
are necessary for users to perform activities, such as calling a controller action,
viewing parts of a View or acting on records in the database. Note that
Permissions consist of an *Privilege* that is to be performed, such as _read_, 
and a *Context* in that the Operation takes place, such as _companies_.

In the authorization configuration, Permissions are assigned to Roles and Role
and Permission hierarchies are defined. *Attributes* may be employed to allow
authorization according to dynamic information about the context and the
current user, e.g. "only allow access on employees that belong to the
current user's branch."


## Examples

A fully functional example application can be found at
http://github.com/stffn/decl_auth_demo_app


## Controller

If authentication is in place, there are two ways to enable user-specific
access control on controller actions. For resource controllers, which more
or less follow the CRUD pattern, `filter_resource_access` is the simplest
approach. It sets up instance variables in before filters and calls
`filter_access_to` with the appropriate parameters to protect the CRUD methods.

```ruby
class EmployeesController < ApplicationController
  filter_resource_access
end
```

See `Authorization::AuthorizationInController::ClassMethods` for options on
nested resources and custom member and collection actions.

By default, Declarative Authorization will enable `filter_resource_access` compatibility with `strong_parameters`.
If you want to disable this behavior, you can use the `:strong_parameters` option.

```ruby
class EmployeesController < ApplicationController
  filter_resource_access :strong_parameters => false
end
```

If you prefer less magic or your controller has no resemblance with the resource
controllers, directly calling `filter_access_to` may be the better option. Examples
are given in the following. E.g. the privilege index users is required for
action index. This works as a first default configuration for RESTful
controllers, with these privileges easily handled in the authorization
configuration, which will be described below.

```ruby
class EmployeesController < ApplicationController
  filter_access_to :all
  def index
  end
end
```

When custom actions are added to such a controller, it helps to define more
clearly which privileges are the respective requirements. That is when the
`filter_access_to` call may become more verbose:

```ruby
class EmployeesController < ApplicationController
  filter_access_to :all

  # this one would be included in :all, but :read seems to be
  # a more suitable privilege than :auto_complete_for_user_name
  filter_access_to :auto_complete_for_employee_name, :require => :read

  def auto_complete_for_employee_name
  end
end
```

For some actions it might be necessary to check certain attributes of the
object the action is to be acting on. Then, the object needs to be loaded 
before the action's access control is evaluated. On the other hand, some actions
might prefer the authorization to ignore specific attribute checks as the object is
unknown at checking time, so attribute checks and thus automatic loading of
objects needs to be enabled explicitly.

```ruby
class EmployeesController < ApplicationController
  filter_access_to :update, :attribute_check => true
  def update
    # @employee is already loaded from param[:id] because of :attribute_check
  end
end
```

You can provide the needed object through before_actions. This way, you have
full control over the object that the conditions are checked against. Just make
sure, your before_actions occur before any of the `filter_access_to` calls.

```ruby
class EmployeesController < ApplicationController
  before_action :new_employee_from_params, :only => :create
  before_action :new_employee, :only => [:index, :new]
  filter_access_to :all, :attribute_check => true

  def create
    @employee.save!
  end

  protected
  def new_employee_from_params
    @employee = Employee.new(params[:employee])
  end
end
```

If the access is denied, a `permission_denied` method is called on the
current_controller, if defined, and the issue is logged.
For further customization of the filters and object loading, have a look at 
the complete API documentation of `filter_access_to` in 
`Authorization::AuthorizationInController::ClassMethods`.


## Views

In views, a simple permitted_to? helper makes showing blocks according to the
current user's privileges easy:

```erb
<% permitted_to? :create, :employees do %>
  <%= link_to 'New', new_employee_path %>
<% end %>
```

Only giving a symbol :employees as context prevents any checks of attributes
as there is no object to check against. For example, in case of nested resources
a new object may come in handy:

```erb
<% permitted_to? :create, Branch.new(:company => @company) do
        # or @company.branches.new
        # or even @company.branches %>
  <%= link_to 'New', new_company_branch_path(@company) %>
<% end %>
```

Lists are straight-forward:

```erb
<% for employee in @employees do %>
  <%= link_to 'Edit', edit_employee_path(employee) if permitted_to? :update, employee %>
<% end %>
```

See also `Authorization::AuthorizationHelper`.


## Models

There are two distinct features for model security built into this plugin:
authorizing CRUD operations on objects as well as query rewriting to limit
results according to certain privileges.

See also Authorization::AuthorizationInModel.


### Model security for CRUD operations

To activate model security, all it takes is an explicit enabling for each
model that model security should be enforced on, i.e.

```ruby
class Employee < ActiveRecord::Base
  using_access_control
end
```

Thus,
    `Employee.create(...)`
fails, if the current user is not allowed to `:create` `:employees` according
to the authorization rules. For the application to find out about what 
happened if an operation is denied, the filters throw 
`Authorization::NotAuthorized` exceptions.

As access control on read are costly, with possibly lots of objects being
loaded at a time in one query, checks on read need to be activated explicitly by
adding the `:include_read` option.


### Query rewriting through named scopes

When retrieving large sets of records from databases, any authorization needs
to be integrated into the query in order to prevent inefficient filtering
afterwards and to use LIMIT and OFFSET in SQL statements. To keep authorization
rules out of the source code, this plugin offers query rewriting mechanisms
through named scopes. Thus,

```ruby
Employee.with_permissions_to(:read)
```

returns all employee records that the current user is authorized to read. In
addition, just like normal named scopes, query rewriting may be chained with
the usual find method:

```ruby
Employee.with_permissions_to(:read).find(:all, :conditions => ...)
```

If the current user is completely missing the permissions, an 
`Authorization::NotAuthorized` exception is raised. Through 
`Model.obligation_conditions`, application developers may retrieve
the conditions for manual rewrites.


## Authorization Rules

Authorization rules are defined in config/authorization_rules.rb
(Or redefine rules files path via `Authorization::AUTH_DSL_FILES`). E.g.

```ruby
authorization do
  role :admin do
    has_permission_on :employees, :to => [:create, :read, :update, :delete]
  end
end
```

There is a default role `:guest` that is used if a request is not associated
with any user or with a user without any roles. So, if your application has
public pages, `:guest` can be used to allow access for users that are not
logged in. All other roles are application defined and need to be associated
with users by the application.

If you need to change the default role, you can do so by adding an initializer
that contains the following statement:

```ruby
Authorization.default_role = :anonymous
```

Privileges, such as :create, may be put into hierarchies to simplify
maintenance. So the example above has the same meaning as

```ruby
authorization do
  role :admin do
    has_permission_on :employees, :to => :manage
  end
end

privileges do
  privilege :manage do
    includes :create, :read, :update, :delete
  end
end
```

Privilege hierarchies may be context-specific, e.g. applicable to `:employees`.

```ruby
privileges do
  privilege :manage, :employees, :includes => :increase_salary
end
```
For more complex use cases, authorizations need to be based on attributes. Note 
that you then also need to set `:attribute_check => true` in controllers for `filter_access_to`.
E.g. if a branch admin should manage only employees of his branch (see 
`Authorization::Reader` in the API docs for a full list of available operators):

```ruby
    authorization do
      role :branch_admin do
        has_permission_on :employees do
          to :manage
          # user refers to the current_user when evaluating
          if_attribute :branch => is {user.branch}
        end
      end
    end
```

To reduce redundancy in has_permission_on blocks, a rule may depend on
permissions on associated objects:

```ruby
authorization do
  role :branch_admin do
    has_permission_on :branches, :to => :manage do
      if_attribute :managers => contains {user}
    end

    has_permission_on :employees, :to => :manage do
      if_permitted_to :manage, :branch
      # instead of
      # if_attribute :branch => {:managers => contains {user}}
    end
  end
end
```

Lastly, not only privileges may be organized in a hierarchy but roles as well.
Here, project manager inherit the permissions of employees.

```ruby
role :project_manager do
  includes :employee
end
```

See also `Authorization::Reader`.

## Testing

ae_declarative_authorization provides a few helpers to ease the testing with
authorization in mind.

In your test_helper.rb, to enable the helpers add

```ruby
require 'declarative_authorization/maintenance'

class Test::Unit::TestCase
  include Authorization::TestHelper
end
```

For using the test helpers with RSpec, just add the following lines to your
spec_helper.rb (somewhere after `require 'spec/rails'`):

```ruby
require 'declarative_authorization/maintenance'
include Authorization::TestHelper
```

Now, in unit tests, you may deactivate authorization if needed e.g. for test
setup and assume certain identities for tests:

```ruby
class EmployeeTest < ActiveSupport::TestCase
  def test_should_read
    without_access_control do
      Employee.create(...)
    end

    assert_nothing_raised do
      with_user(admin) do
        Employee.find(:first)
      end
    end
  end
end
```
    
Or, with RSpec, it would work like this:

```ruby
describe Employee do
  it 'should read' do
    without_access_control do
      Employee.create(...)
    end

    with_user(admin) do
      Employee.find(:first)
    end
  end
end
```

In functional tests, get, posts, etc. may be tested in the name of certain users:

```ruby
get_with admin, :index
post_with admin, :update, :employee => {...}
```

See `Authorization::TestHelper` for more information.


## Providing the Plugin's Requirements
The requirements are
* Rails >= 4.2.5.2 and Ruby >= 2.1.x
* An authentication mechanism 
* A user object returned by Controller#current_user
* An array of role symbols returned by User#role_symbols
* (For model security) Setting Authorization.current_user to the request's user

Of the various ways to provide these requirements, here is one way employing
restful_authentication.

* Install restful_authentication
   cd vendor/plugins && git clone git://github.com/technoweenie/restful-authentication.git restful_authentication
   cd ../.. && ruby script/generate authenticated user sessions
* Move "include AuthenticatedSystem" to ApplicationController
* Add +filter_access_to+ calls as described above.
* If you'd like to use model security, add a before_action that sets the user 
  globally to your ApplicationController. This is thread-safe.
   before_action :set_current_user
   protected
   def set_current_user
     Authorization.current_user = current_user
   end

* Add roles field to the User model through a :+has_many+ association
  (this is just one possible approach; you could just as easily use 
  :+has_many+ :+through+ or a serialized roles array):
  * create a migration for table roles 

     class CreateRoles < ActiveRecord::Migration
       def self.up
         create_table "roles" do |t|
           t.column :title, :string
           t.references :user
         end
       end

       def self.down
         drop_table "roles"
       end
     end

  * create a model Role,
     class Role < ActiveRecord::Base
       belongs_to :user
     end

  * add +has_many+ :+roles+ to the User model and a roles method that returns the roles 
    as an Array of Symbols, e.g.
     class User < ActiveRecord::Base
       has_many :roles
       def role_symbols
         (roles || []).map {|r| r.title.to_sym}
       end
     end

  * add roles to your User objects using e.g.
     user.roles.create(:title => "admin")

Note: If you choose to generate an Account model for restful_authentication
instead of a User model as described above, you have to customize the
examples and create a ApplicationController#current_user method.


## Debugging Authorization

Currently, the main means of debugging authorization decisions is logging and
exceptions. Denied access to actions is logged to `warn` or `info`, including
some hints about what went wrong.

All bang methods throw exceptions which may be used to retrieve more
information about a denied access than a Boolean value.


## License

Released under MIT license.

Copyright (c) 2008 Steffen Bartsch, TZI, Universität Bremen, Germany

Copyright (c) 2011-2017 AppFolio, Inc.
