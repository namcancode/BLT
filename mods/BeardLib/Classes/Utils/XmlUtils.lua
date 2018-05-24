local Utils = BeardLib.Utils
local XML = Utils.XML or {}
Utils.XML = XML

--Finds a node from table 'tbl' with 'meta' as the name of the meta.
function XML:GetNode(tbl, meta)
    if not tbl then return nil end

    for _, v in pairs(tbl) do
        if type(v) == "table" and v._meta == meta then
            return v
        end
    end

    return false
end

--Same as GetNode but allows you to find the node like this: node/a/b/c
function XML:FindNode(tbl, metas)
    if not tbl then return nil end

    local splt = metas:split("/")
    local meta = splt[1]

    for _, v in pairs(tbl) do
        if type(v) == "table" and v._meta == meta then
            if splt[2] then
                self:FindNode(table.concat(splt, 2))
            else
                return v
            end
        end
    end

    return false
end

--Finds a node and replaces it with 'new_node'
function XML:SetNode(tbl, node, new_node)
    if not tbl then return nil end
    
    for i, v in pairs(tbl) do
        if type(v) == "table" and v == node then
            tbl[i] = new_node
        end
    end
end

function XML:SetNodeMeta(tbl, meta, new_node)
    if not tbl then return nil end
    
    for i, v in pairs(tbl) do
        if type(v) == "table" and v._meta == meta then
            tbl[i] = new_node
        end
    end
end

--Same as GetNode but packs every node it finds.
function XML:GetNodes(tbl, meta)
    if not tbl then return nil end

    local t = {}

    for _, v in pairs(tbl) do
        if type(v) == "table" and v._meta == meta then
            table.insert(t, v)
        end
    end

    return t
end

--Gets index of node
function XML:GetNodeIndex(tbl, node)
    if not tbl then return nil end

    for i, v in pairs(tbl) do
        if v == node then
            return i
        end
    end
end

--Gets first index of meta
function XML:GetIndexMeta(tbl, meta)
    if not tbl then return nil end

    for i, v in pairs(tbl) do
        if type(v) == "table" and v._meta == meta then
            return i
        end
    end
end

--Same as GetMetaIndex but packs every result.
function XML:GetMetaIndices(tbl, meta)
    if not tbl then return nil end

    local t = {}

    for i, v in pairs(tbl) do
        if type(v) == "table" and v._meta == meta then
            table.insert(t, i)
        end
    end

    return t
end

--Removes key tables from the table
function XML:CleanKeys(tbl, shallow)
    if not tbl then return nil end

    for i, v in pairs(tbl) do
        if type(v) == "table" then
            if tonumber(i) == nil then
                tbl[i] = nil
            elseif not shallow then
                self:CleanKeys(v, shallow)
            end
        end
    end

    return tbl
end

--Removes indices from the table entirely.
function XML:CleanIndices(tbl, shallow)
    if not tbl then return nil end

    for i, v in pairs(tbl) do
        if type(v) == "table" then
            if tonumber(i) ~= nil then
                tbl[i] = nil
            elseif not shallow then
                self:CleanIndices(v, shallow)
            end
        end
    end

    return tbl
end

--Removes keys only if the table contains at least two indices of the same meta.
--Removes indices if only one of the same meta as the key exists.
--In other words, makes sure that when you save the XML it won't duplicate shit.

function XML:Clean(tbl, shallow)
    if not tbl then return nil end

    --Pack all keys
    local keys = {}
    for k, v in pairs(tbl) do
        if type(v) == "table" and not tonumber(k) then
            keys[k] = true
        end
    end

    --If key has two tables of the same meta remove key.
    local single_node = {}
    local multi_nodes = {}
    for k, v in pairs(tbl) do
        if type(v) == "table" and tonumber(k) then
            local meta = v._meta
            if single_node[meta] then
                single_node[meta] = nil
                keys[meta] = nil
                tbl[meta] = nil
            elseif keys[meta] then
                single_node[meta] = k
            end
            multi_nodes[k] = v
        end
    end

    --Remove duplicate of the key if only one exists.
    for meta, i in pairs(single_node) do
        tbl[i] = nil
        multi_nodes[i] = nil
    end

    --fix indices so it's saved to the XML.
    --first remove old indices so we won't overwrite any that were done before.
    for k, v in pairs(multi_nodes) do
        tbl[k] = nil
    end
    
    local i = 1
    for k, v in pairs(multi_nodes) do
        tbl[i] = v
        i = i + 1
    end

    --to avoid going through tables that are going to be removed we loop again.
    for k, v in pairs(tbl) do
        if type(v) == "table" and not shallow then
            self:Clean(v, shallow)
        end
    end

    return tbl
end

--allows both key and index to be removed, useful for tables cleaned by XML:Clean
function table.remove_key(tbl, key)
    if type(key) == "number" and #tbl <= key then
        table.remove(tbl, key)
    else
        tbl[key] = nil
    end
end

--like table delete only allows key values(doesn't force table.remove which accepts only indices)
function table.delete_value(tbl, value)
	local key = table.get_key(tbl, value)
	if key then
		table.remove_key(tbl, key)
	end
end