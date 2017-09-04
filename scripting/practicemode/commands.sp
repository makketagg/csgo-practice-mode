public Action Command_LaunchPracticeMode(int client, int args) {
  if (!CanStartPracticeMode(client)) {
    PM_Message(client, "You cannot start practice mode right now.");
    return Plugin_Handled;
  }

  if (!g_InPracticeMode) {
    if (g_PugsetupLoaded && PugSetup_GetGameState() >= GameState_Warmup) {
      return Plugin_Continue;
    }
    LaunchPracticeMode();
    if (IsPlayer(client)) {
      GivePracticeMenu(client);
    }
  }
  return Plugin_Handled;
}

public Action Command_ExitPracticeMode(int client, int args) {
  if (g_InPracticeMode) {
    ExitPracticeMode();
  }
  return Plugin_Handled;
}

public Action Command_Time(int client, int args) {
  if (!g_InPracticeMode) {
    return Plugin_Handled;
  }

  if (!g_RunningTimeCommand[client]) {
    // Start command.
    PM_Message(client, "When you start moving a timer will run until you stop moving.");
    g_RunningTimeCommand[client] = true;
    g_RunningLiveTimeCommand[client] = false;
    g_TimerType[client] = TimerType_Movement;
  } else {
    // Early stop command.
    g_RunningTimeCommand[client] = false;
    g_RunningLiveTimeCommand[client] = false;
    StopClientTimer(client);
  }

  return Plugin_Handled;
}

public Action Command_Time2(int client, int args) {
  if (!g_InPracticeMode) {
    return Plugin_Handled;
  }

  if (!g_RunningTimeCommand[client]) {
    // Start command.
    PM_Message(client, "Type .timer2 to stop the timer again.");
    g_RunningTimeCommand[client] = true;
    g_RunningLiveTimeCommand[client] = false;
    g_TimerType[client] = TimerType_Manual;
    StartClientTimer(client);
  } else {
    // Stop command.
    g_RunningTimeCommand[client] = false;
    g_RunningLiveTimeCommand[client] = false;
    StopClientTimer(client);
  }

  return Plugin_Handled;
}

public void StartClientTimer(int client) {
  g_LastTimeCommand[client] = GetEngineTime();
  CreateTimer(0.1, Timer_DisplayClientTimer, GetClientSerial(client),
              TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public void StopClientTimer(int client) {
  float dt = GetEngineTime() - g_LastTimeCommand[client];
  PM_Message(client, "Timer result: %.2f seconds", dt);
  PrintHintText(client, "<b>Time: %.2f</b> seconds", dt);
}

public Action Timer_DisplayClientTimer(Handle timer, int serial) {
  int client = GetClientFromSerial(serial);
  if (IsPlayer(client) && g_RunningTimeCommand[client]) {
    if (g_RunningTimeCommand[client]) {
      float dt = GetEngineTime() - g_LastTimeCommand[client];
      PrintHintText(client, "<b>Time: %.1f</b> seconds", dt);
      return Plugin_Continue;
    } else {
      return Plugin_Stop;
    }
  }
  return Plugin_Stop;
}

public Action Command_CopyGrenade(int client, int args) {
  if (!g_InPracticeMode) {
    return Plugin_Handled;
  }

  if (!IsPlayer(client) || args != 1) {
    PM_Message(client, "Usage: .copy <id>");
    return Plugin_Handled;
  }

  char name[MAX_NAME_LENGTH];
  char id[GRENADE_ID_LENGTH];
  GetCmdArg(1, id, sizeof(id));

  char targetAuth[AUTH_LENGTH];
  if (FindId(id, targetAuth, sizeof(targetAuth))) {
    int newid = CopyGrenade(targetAuth, id, client);
    if (newid != -1) {
      PM_Message(client, "Copied nade to new id %d", newid);
    } else {
      PM_Message(client, "Could not find grenade %s from %s", newid, name);
    }
  }

  return Plugin_Handled;
}

public Action Command_Respawn(int client, int args) {
  if (!g_InPracticeMode) {
    return Plugin_Handled;
  }

  g_SavedRespawnActive[client] = true;
  GetClientAbsOrigin(client, g_SavedRespawnOrigin[client]);
  GetClientEyeAngles(client, g_SavedRespawnAngles[client]);
  PM_Message(
      client,
      "Saved respawn point. When you die will you respawn here, use .stoprespawn to cancel.");
  return Plugin_Handled;
}

public Action Command_StopRespawn(int client, int args) {
  if (!g_InPracticeMode) {
    return Plugin_Handled;
  }

  g_SavedRespawnActive[client] = false;
  PM_Message(client, "Cancelled respawning at your saved position.");
  return Plugin_Handled;
}

public Action Command_StopAll(int client, int args) {
  if (!g_InPracticeMode) {
    return Plugin_Handled;
  }
  if (g_SavedRespawnActive[client]) {
    Command_StopRespawn(client, 0);
  }
  if (g_TestingFlash[client]) {
    Command_StopFlash(client, 0);
  }
  return Plugin_Handled;
}

public Action Command_FastForward(int client, int args) {
  if (!g_InPracticeMode) {
    return Plugin_Handled;
  }

  // Freeze clients so its not really confusing.
  for (int i = 1; i <= MaxClients; i++) {
    if (IsPlayer(i)) {
      g_PreFastForwardMoveTypes[i] = GetEntityMoveType(i);
      SetEntityMoveType(i, MOVETYPE_NONE);
    }
  }

  // Smokes last around 18 seconds.
  SetCvar("host_timescale", 20);
  CreateTimer(20.0, Timer_ResetTimescale);

  return Plugin_Handled;
}

public Action Timer_ResetTimescale(Handle timer) {
  if (!g_InPracticeMode) {
    return Plugin_Handled;
  }

  SetCvar("host_timescale", 1);

  for (int i = 1; i <= MaxClients; i++) {
    if (IsPlayer(i)) {
      SetEntityMoveType(i, g_PreFastForwardMoveTypes[i]);
    }
  }
  return Plugin_Handled;
}
