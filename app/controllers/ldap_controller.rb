require 'net/ldap'
class LdapController < ApplicationController
    def connect
        ldap = NET::LDAP.new(
            host: 'academy-ldap',
            port: 389,
            auth: {
                method: :simple,
                dn: "cn=admin,dc=arqsoft,dc=unal,dc=edu,dc=co",
                password: "admin"
            }
        )
        return ldap.bind
    end

    def create
        email = params[:email]
        password = params[:password]
        email = email[/\A\w+/].downcase

        if connect()
            ldap = NET::LDAP.new(
                host: 'academy-ldap',
                port: 389,
                auth: {
                    methiod: :simple,
                    dn: "cn=" + email + "@unal.edu.co, ou=academy,dc=arqsoft,dc=unal,dc=edu,dc=co",
                    password: password
                }
            )

            if ldap.bind 
                query = "select * from students where email LIKE '" + email + "@unal.edu.co'"
                results = ActiveRecord::Base.connection.exec_query(query)
                if results.present?
                    @newAuth = ObjAuth.new(email, password, "true")
                    puts("Authentication satisfactory")
                    render json: @newAuth
                else
                    puts("Authentication not satisfactory, the user isn't registered on the DB")
                    @newAuth = ObjAuth(email, password, "false")
                    render json @newAuth
                end
            else
                puts("Authentication not satisfactory, the user isn't registered on the LDAP")
                @newAuth = ObjAuth.new(email, password, "false")
                render json: @newAuth
            end
        end 
    end
end

class ObjAuth 
    def initialize(email, password, answer)
        @email = email
        @password = password
        @answer = answer
    end
end