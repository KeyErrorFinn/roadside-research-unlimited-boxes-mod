using System.Reflection;
using BepInEx;
using BepInEx.Unity.IL2CPP;
using HarmonyLib;

namespace KeyErrorFinn.UnlimitedBoxes;

[BepInPlugin(Id, "Unlimited Universal Boxes", "1.0.1")]
public sealed class Plugin : BasePlugin
{
    public const string Id = "com.keyerrorfinn.roadsideresearch.unlimitedboxes";
    private static PropertyInfo identity = null!;
    private static PropertyInfo identityId = null!;
    public override void Load()
    {
        var harmony = new Harmony(Id);
        try
        {
            const BindingFlags flags = BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Static | BindingFlags.Instance;
            var limits = Type.GetType("Interaction.SpawnLimits, Assembly-CSharp", true)!;
            var dispenser = Type.GetType("Interaction.SpawnObjectOnInteract, Assembly-CSharp", true)!;
            var identityType = Type.GetType("Interaction.SpawnLimitIdentity, Assembly-CSharp", true)!;
            identity = dispenser.GetProperty("_spawnLimitIdentityPrefab", flags) ?? throw new MissingMemberException("_spawnLimitIdentityPrefab");
            identityId = identityType.GetProperty("SpawnLimitID", flags) ?? throw new MissingMemberException("SpawnLimitID");
            var canSpawn = limits.GetMethod("CanSpawn", flags, null, new[] { typeof(string) }, null)!;
            var reached = dispenser.GetMethod("get_ReachedSpawnLimit", flags)!;
            if (canSpawn == null || reached == null || canSpawn.ReturnType != typeof(bool) || reached.ReturnType != typeof(bool))
                throw new MissingMethodException("Spawn-limit signatures changed");
            harmony.Patch(canSpawn, prefix: new HarmonyMethod(typeof(Plugin), nameof(CanSpawn)));
            harmony.Patch(reached, prefix: new HarmonyMethod(typeof(Plugin), nameof(ReachedLimit)));
            Log.LogInfo("Unlimited Universal Boxes 1.0.1: GenericBox spawn limit bypass installed (dispenser and shared check).");
        }
        catch (Exception ex)
        {
            harmony.UnpatchSelf();
            Log.LogError($"Unlimited Universal Boxes disabled: {ex}");
        }
    }
    private static bool CanSpawn(string __0, ref bool __result)
    {
        if (__0 != "GenericBox") return true;
        __result = true;
        return false;
    }
    private static bool ReachedLimit(object __instance, ref bool __result)
    {
        var prefab = identity.GetValue(__instance);
        if (prefab == null || identityId.GetValue(prefab) as string != "GenericBox") return true;
        __result = false;
        return false;
    }
}
