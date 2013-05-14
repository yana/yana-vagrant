// Select Grails environment (one of "production", "staging", "development", "test"):
grails {
   env = "production"
   serverURL="@server_url@"
}

// The path to a writable dir for storing the search index. If not specified you
// can configure it via Java System property "yana2.searchindex.location".
// If totally unspecified, it will default to an in-memory index, which is probably
// not what you want, but will at least allow the server to run:
searchable {
    compassConnection = "@index_dir@"
}



// H2 configuration:
dataSource {
   driverClassName = "org.h2.Driver"
   url = "jdbc:h2:file:@yana_db_dir@/prodDb"
   username = "sa"
   password = ""
}

// Default application credentials if not using LDAP
root {
   login = "admin"
   password = "admin"
}

images {
   icons {
      large = "/resource/images/64/"
      med = "/resource/images/32/"
      small = "/resource/images/16/"
   }
}

grails {
   plugins {
      springsecurity {
         portMapper {
            httpPort = "@http_port@"
            httpsPort = "@https_port@"
         }
         //uncomment below to use LDAP
         /*
         ldap {
            context {
               managerDn = "cn=Manager,dc=yana,dc=org"
               managerPassword = "secret"
               server = "ldap://localhost:389"
            }
            authorities {
               groupSearchBase = "ou=roles,dc=yana,dc=org"
               groupSearchFilter = "memberUid={1}"
               retrieveGroupRoles = "true"
            }
            search {
               searchSubtree = "true"
               base = "dc=yana,dc=org"
            }
         }
         */
      }
   }
}
