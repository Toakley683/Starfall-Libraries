--@name model_library_v2
--@author toakley682
--@client

function AwaitUntil( Await, Callback, UID )
    
    local TimerName = "__AwaitUnitl:" .. UID
    
    if timer.exists( TimerName ) then timer.remove( TimerName ) end
    
    timer.create( TimerName, 0.1, 0, function()
        
        if Await() == false then return end
        Callback()
        timer.remove( TimerName )
        
    end)
    
end

Model = class( "Model" )

function Model:initialize()
    
    self.URL = ""
    self.TexturesInit = {}
    self.Textures = {}
    self.ModelTextureIndex = {}
    
    self.RenderBoundMins, self.RenderBoundMaxs = Vector( -16 ), Vector( 16 )
    
    self.CourotinePercent = 0.5
    
    self.MeshList = {}
    
    self.Shader = "VertexLitGeneric"
    
end

function Model:SetRenderBounds( Mins, Maxs ) self.RenderBoundMins, self.RenderBoundMaxs = Mins, Maxs end
function Model:SetShader( Shader ) self.Shader = Shader end

function Model:RegisterTextureURL( Name, Key, URL, CB, Done )
    
    self.TexturesInit[ #self.TexturesInit + 1 ] = { Name=Name, Shader=self.Shader, Key=Key, URL=URL, CB=CB, Done=Done }
    
end

function Model:KeyApplyTexture( MeshKey, TextureName )
    
    self.ModelTextureIndex[ MeshKey ] = TextureName
    
end

function Model:ModelURL( URL )
    
    self.URL = URL
    
end

function Model:__LoadTexture( Index )
    
    if not self.TexturesInit[ Index ] then table.remove( self.TexturesInit, Index ) return end
    
    local Data = self.TexturesInit[ Index ]
    
    if 
        self.Textures[ Data.Name ] != nil and
        self.Textures[ Data.Name ].Key == Data.Key
    then table.remove( self.TexturesInit, Index ) return end
    
    if 
        self.Textures[ Data.Name ] != nil and
        self.Textures[ Data.Name ].Key != Data.Key
    then
        
        self.Textures[ Data.Name ]:setTextureURL( Data.Key, Data.URL, Data.CB, Data.Done )
        table.remove( self.TexturesInit, Index )
        return
        
    end
    
    if not http.canRequest() then return end
    
    local Mat = material.create( Data.Shader )
    
    Mat.Key = Data.Key
    Mat:setTextureURL( Data.Key, Data.URL, Data.CB, Data.Done )
    
    self.Textures[ Data.Name ] = Mat
    table.remove( self.TexturesInit, Index )
    
end

function Model:__RenderModel( OnComplete )
    
    AwaitUntil(
        function() return http.canRequest() end,
        function()
            
            http.get( self.URL, function( MeshData )
                
                mesh_thread = coroutine.wrap( function()
                    
                    local MeshObjects = mesh.createFromObj( MeshData, true, false )
                    local ValuesKeyValues = table.getKeys( MeshObjects )
                    
                    self.MeshKeys = ValuesKeyValues
                    
                    for Index, Value in ipairs( self.MeshKeys ) do
                        
                        self.MeshList[ Value ] = MeshObjects[ Value ]
                        
                    end
                    
                    return true
                    
                end)
                
                local HookName = ( table.address( self ) .. ":__RenderModel" )
                
                hook.add( "think", HookName, function()
                    
                    while quotaAverage() < quotaMax() * self.CourotinePercent do
                
                        if mesh_thread() then
                            
                            OnComplete()
                            
                            hook.remove( "think", HookName )
                            return
                        
                        end
                    
                    end
                
                end)
                
            end)
            
        end,
        table.address( self ) .. ":__RenderModel"
    )
    
end

function Model:RenderHolograms( Meshes, Done, HologramSet )
    
    local HologramDepot = {}
    
    for Index, Mesh in pairs( Meshes ) do
        
        local E = hologram.create( chip():getPos(), Angle(), "models/hunter/blocks/cube025x025x025.mdl", Vector( 1 ) )
        
        E.Key = Index
        Texture = self.Textures[ self.ModelTextureIndex[ E.Key ] ]
        
        HologramSet( E.Key, E, Texture )
        
        E:setRenderBounds( self.RenderBoundMins, self.RenderBoundMaxs )
        
        E:setMesh( Mesh )
        if Texture then E:setMeshMaterial( Texture ) end
        
        HologramDepot[ #HologramDepot + 1 ] = E
        
    end
    
    Done( HologramDepot )
    
end

function Model:Compile( Callback )
    
    if self.URL == "" then error( "No model URL given!" ) end
    
    self.TimerName = ( table.address( self ) .. ":ModelTimer" )
    
    timer.create( self.TimerName, 0.1, 0, function()
        
        if #self.TexturesInit <= 0 then
            
            self:__RenderModel( function()
                
                Callback( self.MeshList, self.Textures )
                
            end)
            timer.remove( self.TimerName )
            return
            
        end
        
        self:__LoadTexture( 1 )
        
    end)
    
end
