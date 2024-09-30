--@name Sound Manager
--@author toakley682
--@shared

if CLIENT then
    
    SoundManager = class( "SoundManager" )
    
    function SoundManager:initialize()
         
        self.Settings = "3D noblock"
        
        self.UninitializedSongs = {}
        self.Songs = {}
        
        self.SongRequests = {}
        
    end
    
    function SoundManager:addSound( Name, URL )
        
        self.UninitializedSongs[ #self.UninitializedSongs + 1 ] = { Name=Name, URL=URL }
        
    end
    
    function SoundManager:Setup()
        
        for Index, SongData in ipairs( self.UninitializedSongs ) do
            
            bass.loadURL( SongData.URL, self.Settings, function( Bass, Err, ErrCode )
                
                if ErrCode != "" then printConsole( player():getName() .. " could not load sound " .. SongData.Name .. " - Error : " .. ErrCode ) return end
                
                self.Songs[ SongData.Name ] = Bass
                table.remove( self.UninitializedSongs, Index )
                
                hook.run( "LoadedSound:"..SongData.Name, Bass )
                
            end)
            
        end
        
    end
    
    function SoundManager:getBass( Name, Callback )
        
        if not self.Songs[ Name ] then printConsole( "Song " .. Name .. " does not exist!" ) return end
        
        Callback( self.Songs[ Name ] )
        
    end
    
end
