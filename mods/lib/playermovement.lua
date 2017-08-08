Hooks:PostHook( PlayerMovement , "change_state" , "DynamicCrosshairsPostPlayerMovementChangeState" , function( self , name )

	if not self._current_state_name then return end
	
	local a_s = {
		[ "standard" ] = true,
		[ "bleed_out" ] = true,
		[ "carry" ] = true,
		[ "bipod" ] = true
	}
	
	if a_s[ self._current_state_name ] then
		managers.hud:show_crosshair_panel( true )
	else
		managers.hud:show_crosshair_panel( false )
	end
		

end )