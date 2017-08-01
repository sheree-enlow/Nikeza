module Nikeza.Server.DB

open System
open Nikeza.Server.Models
open System.Data.SqlClient

[<Literal>]
let ConnectionString = @"Data Source=DESKTOP-GE7O8JT\SQLEXPRESS;Initial Catalog=Nikeza;Integrated Security=True;Connect Timeout=15;Encrypt=False;TrustServerCertificate=True;ApplicationIntent=ReadWrite;MultiSubnetFailover=False"

let findUser email passwordHash =
    let query = "SELECT * FROM Profile Where Email = @email AND PasswordHash = @hash"
    use connection = new SqlConnection(ConnectionString)

    use command = new SqlCommand(query,connection)
    command.Parameters.AddWithValue("@email", email)       |> ignore
    command.Parameters.AddWithValue("@hash", passwordHash) |> ignore

    connection.Open()
    let reader = command.ExecuteReader()
    let profiles = 
        seq {
            while reader.Read() do 
                yield { 
                    ProfileId = reader.["Id"].ToString() |> int
                    FirstName = reader.["FirstName"].ToString()
                    LastName =  reader.["LastName"].ToString()
                    Email =     reader.["Email"].ToString()
                    ImageUrl =  reader.["ImageUrl"].ToString()
                    Bio =       reader.["Bio"].ToString()
                    Created =   DateTime.Parse(reader.["Created"].ToString()) 
                }
        }
        
    profiles |> Seq.tryHead

let follow (request:FollowRequest) =
    let query = @"INSERT INTO [dbo].[Subscription]
                        ([ProfileId]
                        ,[ProviderId])
                  VALUES
                         @ProfileId
                        ,@ProviderId"

    use connection = new SqlConnection(ConnectionString)
    use command =    new SqlCommand(query,connection)

    command.Parameters.AddWithValue("@ProfileId",  request.SubscriberId) |> ignore
    command.Parameters.AddWithValue("@ProviderId", request.ProviderId)   |> ignore
    command.ExecuteNonQuery() |> ignore
    
let unsubscribe request = () // TO BE IMPLEMENTED
let featureLink request = () // TO BE IMPLEMENTED