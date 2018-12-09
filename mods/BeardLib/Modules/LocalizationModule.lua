LocalizationModule = LocalizationModule or class(BasicModuleBase)
LocalizationModule.type_name = "Localization"

function LocalizationModule:Load()
	self.LocalizationDirectory = self._config.directory and Path:Combine(self._mod.ModPath, self._config.directory) or self._mod.ModPath
    self.Localizations = {}

    for _, tbl in ipairs(self._config) do
        if tbl._meta == "localization" or tbl._meta == "loc" then
            if not self.DefaultLocalization then
                self.DefaultLocalization = tbl.file
            end
            self.Localizations[Idstring(tbl.language):key()] = tbl.file
        end
    end

    self.DefaultLocalization = self._config.default or self.DefaultLocalization

    if managers.localization then
        self:LoadLocalization()
    else
        Hooks:Add("LocalizationManagerPostInit", self._mod.Name .. "_Localization", function(loc)
            self:LoadLocalization()
    	end)
    end
end

function LocalizationModule:LoadLocalization()
    local path
    if self.Localizations[SystemInfo:language():key()] then
        path = Path:Combine(self.LocalizationDirectory, self.Localizations[SystemInfo:language():key()])
    else
        path = Path:Combine(self.LocalizationDirectory, self.DefaultLocalization)
    end

    --if it fails, just force the author to fix their errors.
    if not FileIO:Exists(path) then
        self:log("[ERROR] JSON file not found! Path %s", path)
    elseif not FileIO:LoadLocalization(path) then
        self:log("[ERROR] JSON file has errors and cannot be loaded! Path %s", path)
    end
end

BeardLib:RegisterModule(LocalizationModule.type_name, LocalizationModule)