function open_doors_check(m)
  
    local dist = 150
    local doorwarp = obj_get_nearest_object_with_behavior_id(m.marioObj, id_bhvDoorWarp)
    local door = obj_get_nearest_object_with_behavior_id(m.marioObj, id_bhvDoor)
    local stardoor = obj_get_nearest_object_with_behavior_id(m.marioObj, id_bhvStarDoor)
    local shell = obj_get_nearest_object_with_behavior_id(m.marioObj, id_bhvKoopaShell)
    
    if m.action == ACT_WALKING or m.action == ACT_HOLD_WALKING then
        if
        ((doorwarp ~= nil and dist_between_objects(m.marioObj, doorwarp) > dist) or
        (door ~= nil and dist_between_objects(m.marioObj, door) > dist) or
        (stardoor ~= nil and dist_between_objects(m.marioObj, stardoor) > dist) or (dist_between_objects(m.marioObj, shell) > dist and shell ~= nil) and m.heldObj == nil)
        then
            return set_mario_action(m, ACT_HONI_WALK, 0)
        elseif doorwarp == nil and door == nil and stardoor == nil and shell == nil then
            return set_mario_action(m, ACT_HONI_WALK, 0)
        end
    end
    
    if m.action == ACT_HONI_WALK then
        if
        (dist_between_objects(m.marioObj, doorwarp) < dist and doorwarp ~= nil) or
        (dist_between_objects(m.marioObj, door) < dist and door ~= nil) or
        (dist_between_objects(m.marioObj, stardoor) < dist and stardoor ~= nil) or (dist_between_objects(m.marioObj, shell) < dist and shell ~= nil)
        then
          if m.heldObj == nil then
            return set_mario_action(m, ACT_WALKING, 0)
            else
              return set_mario_action(m, ACT_HOLD_WALKING, 0)
          end
        
        end
    end
end