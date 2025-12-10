---@diagnostic disable: deprecated, undefined-field, inject-field
local Path = {
    _NAME = 'nodejs-path.lua',
    _VERSION = '1.0.0',
    _URL = 'https://github.com/shemiakin/lua-nodejs-path',
    _DESCRIPTION = 'File and directory path utilities',
    _LICENSE = [[
        MIT License

        Copyright (c) 2023 Maxim Shemiakin <maxim.shemiakin@gmail.com>

        Permission is hereby granted, free of charge, to any person obtaining a copy
        of this software and associated documentation files (the "Software"), to deal
        in the Software without restriction, including without limitation the rights
        to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
        copies of the Software, and to permit persons to whom the Software is
        furnished to do so, subject to the following conditions:

        The above copyright notice and this permission notice shall be included in all
        copies or substantial portions of the Software.

        THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
        IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
        FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
        AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
        LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
        OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
        SOFTWARE.
    ]]
}

---@param isPosix boolean
---@return table
function Path:new(isPosix)
    local private = {}
    local public = {}

    private.isPosix = isPosix == true
    private.isWin32 = not private.isPosix

    if private.isPosix then
        public.sep = '/'
        private.sepSplitPattern = '[^/]+'
        private.trailingSlashPattern = '/$'
        public.delimiter = ':'
        private.basenamePattern = '([^/]*)[/]?$'
        private.rootPatternsLists = {
            {
                pattern = '^/',
                path = nil,
                type = 'root',
            },
        }
    else
        public.sep = '\\'
        private.sepSplitPattern = '[^\\/]+'
        private.trailingSlashPattern = '[\\/]$'
        public.delimiter = ';'
        private.basenamePattern = '([^\\/]*)[\\/]?$'
        private.rootPatternsLists = {
            {
                pattern = '^[\\/][\\/][^\\/]+[\\/][^\\/]+[\\/]?',
                path = nil,
                type = 'unc',
            },
            {
                pattern = '^%a:[\\/]',
                path = nil,
                type = 'drive',
            },
            {
                pattern = '^[\\/]',
                path = nil,
                type = 'net',
            },
        }
    end

    if _G.LUA_ENV == 'test' or os.getenv('LUA_ENV') == 'test' then
        public.private = private
    end

    ---The path:basename() method returns the last portion of a path, similar
    ---to the Unix basename command. Trailing directory separators are ignored.
    ---Although Windows usually treats file names, including file extensions,
    ---in a case-insensitive manner, this function does not.
    ---@param path string
    ---@param suffix string | nil
    ---@return string
    function public.basename(path, suffix)
        private.isString(path, 'path')
        if type(suffix) ~= 'string' and type(suffix) ~= 'nil' then
            error(string.format('The "suffix" argument must be of type string. Received %s', type(suffix)))
        end

        if path == '' or path == '.' or path == '..' then
            return path
        end

        if suffix == nil then
            suffix = ''
        else
            -- escaping `suffix` symbols
            suffix = string.gsub(suffix, '[%.%*%^%[%]%(%)]', function (sym)
                return '%' .. sym
            end)
        end

        if private.isWin32 == true then
            local rootInfo = private.getRootInfo(path)
            if rootInfo ~= nil then
                if rootInfo.type ~= 'unc' and rootInfo.path == path then
                    -- path.win32.basename('C:\\', 'anything') -> NodeJS return '\\'
                    if rootInfo.type == 'drive' and string.len(suffix) > 0 then
                        return '\\'
                    else
                        return ''
                    end
                end
            end
        end

        local basename = string.match(path, private.basenamePattern)
        local basenameWithoutSuffix = string.gsub(basename, suffix .. '$', '')

        return basenameWithoutSuffix
    end

    ---The path:dirname() method returns the directory name of a path, similar
    ---to the Unix dirname command. Trailing directory separators are ignored.
    ---@param path string
    ---@return string
    function public.dirname(path)
        private.isString(path, 'path')

        if path == '' or path == '.' or path == '..' then
            return '.'
        elseif path == '/' then
            return '/'
        end

        if private.isRoot(path) == true then
            return path
        end

        local basenameStartPos = string.find(path, private.basenamePattern)
        if basenameStartPos == nil then
            -- TODO it's misbehaviour
            return ''
        elseif basenameStartPos == 1 then
            return '.'
        end

        local dir = string.sub(path, 1, basenameStartPos - 1)

        if private.isRoot(dir) == false then
            dir = string.gsub(dir, private.trailingSlashPattern, '')
        end

        return dir
    end

    ---The path:extname() method returns the extension of the path,
    ---from the last occurrence of the . (period) character to end of string
    ---in the last portion of the path. If there is no . in the last portion
    ---of the path, or if there no . characters other than the first character
    ---of the basename of path (see path.basename()) , an empty string
    ---is returned.
    ---@param path string
    ---@return string
    function public.extname(path)
        private.isString(path, 'path')

        if path == '' or path == '.' or path == '..' or path == '/' or path == '\\' then
            return ''
        end

        local _, ext = private.parseNameAndExt(public.basename(path))
        return ext
    end

    ---The path:format() method returns a path string from an object.
    ---This is the opposite of path:parse().
    ---When providing properties to the pathObject remember that there
    ---are combinations where one property has priority over another:
    --- * pathObject.root is ignored if pathObject.dir is provided
    --- * pathObject.ext and pathObject.name are ignored if pathObject.base exists
    ---@param pathList { dir: string, root: string, base: string, name: string, ext: string }
    ---@return string
    function public.format(pathList)
        local dir = tostring(pathList.dir or '')
        local base = tostring(pathList.base or '')

        if pathList.dir == nil and pathList.root ~= nil then
            dir = tostring(pathList.root)
        end

        if pathList.base == nil then
            local name = tostring(pathList.name or '')
            local ext = tostring(pathList.ext or '')
            if string.len(ext) > 0 and string.sub(ext, 1, 1) ~= '.' then
                ext = '.' .. ext
            end
            base = name .. ext
        end

        return public.join(dir, base)
    end

    ---The path:isAbsolute() method determines if path is an absolute path.
    ---If the given path is a zero-length string, false will be returned.
    ---@param path string
    ---@return boolean
    function public.isAbsolute(path)
        private.isString(path, 'path')

        if private.getRootInfo(path) ~= nil then
            return true
        end

        return false
    end

    ---The path:join() method joins all given path segments together using
    ---the platform-specific separator as a delimiter, then normalizes
    ---the resulting path.
    ---Zero-length path segments are ignored. If the joined path string
    ---is a zero-length string then '.' will be returned,
    ---representing the current working directory.
    ---@param ... string
    ---@return string
    function public.join(...)
        local arguments = private.tablePack(...)
        local segments = {}
        for i = 1, arguments.n do
            private.isString(arguments[i], 'path')
            if arguments[i] ~= '' and arguments[i] ~= '.' then
                table.insert(segments, arguments[i])
            end
        end

        local path = table.concat(segments, public.sep)
        local normalizedPath = public.normalize(path)
        return normalizedPath
    end

    ---The path:handleJumps() method normalizes the given path, resolving '..'
    ---and '.' segments.
    ---When multiple, sequential path segment separation characters are found
    ---(e.g. / on POSIX and either \ or / on Windows),
    ---they are replaced by a single instance of the platform-specific path
    ---segment separator (/ on POSIX and \ on Windows).
    ---Trailing separators are preserved.
    ---@param path string
    ---@return string
    function public.normalize(path)
        private.isString(path, 'path')

        local pathDataList = private.handleJumps(private.getPathDataList(path))

        local normalizedPath = pathDataList.rootSegment .. table.concat(pathDataList.segments, public.sep)

        local trailingSlash = string.match(path, private.trailingSlashPattern)
        if #pathDataList.segments > 0 and trailingSlash ~= nil then
            normalizedPath = normalizedPath .. trailingSlash
        end

        if string.len(normalizedPath) == 0 then
            return '.'
        end

        if private.isWin32 and string.find(normalizedPath, '^%a:$') ~= nil then
            -- dirty hack: 'C:' => 'C:.'
            return normalizedPath .. '.'
        end

        return private.replaceSep(normalizedPath)
    end

    ---The path:parse() method returns an object whose properties represent
    ---significant elements of the path.
    ---Trailing directory separators are ignored.
    ---Although Windows usually treats file names, including file extensions,
    ---in a case-insensitive manner, this function does not.
    ---@param path string
    ---@return { dir: string, root: string, base: string, name: string, ext: string }
    function public.parse(path)
        private.isString(path, 'path')

        local parsedPath = {
            dir = '',
            root = '',
            base = '',
            name = '',
            ext = '',
        }

        if path == '.' or path == '..' or path == '' then
            return parsedPath
        end

        local rootInfo = private.getRootInfo(path)
        if rootInfo ~= nil then
            parsedPath.root = rootInfo.path
        end

        parsedPath.dir = public.dirname(path)
        if rootInfo == nil and parsedPath.dir == '.' then
            parsedPath.dir = ''
        end

        parsedPath.base = public.basename(path)
        parsedPath.name, parsedPath.ext = private.parseNameAndExt(parsedPath.base)

        return parsedPath
    end

    ---The path:relative() method returns the relative path from `from` to `to`
    ---based on the current working directory. If `from` and `to` each resolve
    ---to the same path (after calling path.resolve() on each), a zero-length
    ---string is returned.
    ---If a zero-length string is passed as `from` or `to`, the current working
    ---directory will be used instead of the zero-length strings.
    ---@param from string
    ---@param to string
    ---@return string relativePath
    function public.relative(from, to)
        private.isString(from, 'from')
        private.isString(to, 'to')

        if public.isAbsolute(from) == false then
            from = private.cwd() .. public.sep .. from
        end

        if public.isAbsolute(to) == false then
            to = private.cwd() .. public.sep .. to
        end

        local fromList = private.handleJumps(private.getPathDataList(from))
        local toList = private.handleJumps(private.getPathDataList(to))

        local countOfIdenticalSegments = 0
        local indexOfTheDifferentSegment

        for i, segmentTo in ipairs(toList.segments) do
            local segmentFrom = fromList.segments[i]
            if segmentTo ~= segmentFrom then
                indexOfTheDifferentSegment = i
                break
            else
                countOfIdenticalSegments = countOfIdenticalSegments + 1
            end
        end

        local countJumpFromSegments = #fromList.segments - countOfIdenticalSegments

        local jumps = {}
        for _ = 1, countJumpFromSegments, 1 do
            table.insert(jumps, '..')
        end
        local jumpsFrom = table.concat(jumps, public.sep)

        local pathTo = ''
        if indexOfTheDifferentSegment ~= nil then
            pathTo = table.concat({
                private.tableUnpack(toList.segments, indexOfTheDifferentSegment, #toList.segments)
            }, public.sep)
        end

        local relativePath = table.concat({ jumpsFrom, pathTo }, public.sep)
        if string.len(jumpsFrom) == 0 then
            relativePath = pathTo
        elseif string.len(pathTo) == 0 then
            relativePath = jumpsFrom
        end

        if relativePath == '.' then
            -- Replacing because by default public.join() for an empty path returns '.'
            relativePath = ''
        end

        return relativePath
    end

    ---The path:resolve() method resolves a sequence of paths or path segments
    ---into an absolute path. The given sequence of paths is processed from
    ---right to left, with each subsequent path prepended until an absolute
    ---path is constructed. For instance, given the sequence of path segments:
    ---/foo, /bar, baz, calling path:resolve('/foo', '/bar', 'baz') would
    ---return /bar/baz because 'baz' is not an absolute path, but
    ---'/bar' + '/' + 'baz' is.
    ---If, after processing all given path segments, an absolute path has
    ---not yet been generated, the current working directory is used.
    ---The resulting path is normalized and trailing slashes are removed
    ---unless the path is resolved to the root directory. Zero-length path
    ---segments are ignored. If no path segments are passed, path:resolve()
    ---will return the absolute path of the current working directory.
    ---@usage path:resolve('/foo/bar', './baz') -- Returns: '/foo/bar/baz'
    ---@param ... string
    ---@return string resolvedPath
    function public.resolve(...)
        local arguments = private.tablePack(...)
        for i = 1, arguments.n do
            private.isString(arguments[i], 'path')
        end

        local pathList = {}
        for _, path in ipairs(arguments) do
            if path ~= '.' and string.len(path) > 0 then
                if public.isAbsolute(path) == true then
                    pathList = {}
                end
                table.insert(pathList, path)
            end
        end

        if #pathList == 0 or public.isAbsolute(pathList[1]) == false then
            table.insert(pathList, 1, private.cwd())
        end

        local resolvedPath = public.normalize(table.concat(pathList, public.sep))

        resolvedPath = string.gsub(resolvedPath, private.trailingSlashPattern, '')

        return resolvedPath
    end

    ---On Windows systems only, returns an equivalent namespace-prefixed path
    ---for the given path. If path is not a string, path will be returned
    ---without modifications. This method is meaningful only on Windows systems.
    ---On POSIX systems, the method is non-operational and always returns path
    ---without modifications.
    ---@param path string | any
    ---@return string | any namespacedPath
    function public.toNamespacedPath(path)
        if private.isPosix or type(path) ~= 'string' or string.len(path) == 0 or path == '.' or path == '..' then
            return path
        end

        if string.find(path, '^%a:.+$') ~= nil then
            path = private.replaceSep(path)

            if string.len(path) == 2 then
                -- Replacing 'C:' on current working directory
                path = public.join(path, private.cwd())
            end

            return public.normalize('\\\\?\\' .. path)
        end

        return path
    end

    ---@param path string
    ---@return { path: string, pattern: string, preserveJump: boolean, type: 'root'|'unc'|'drive'|'net'  } | nil rootList
    function private.getRootInfo(path)
        for _, list in ipairs(private.rootPatternsLists) do
            local match = string.match(path, list.pattern)

            if match ~= nil then
                list.path = match
                return list
            end
        end
        return nil
    end

    function private.isString(value, argumentName)
        if type(value) ~= 'string' then
            error(string.format('The "%s" argument must be of type string. Received %s', argumentName, type(value)))
        end
    end

    ---@return string
    function private.cwd()
        return os.getenv('PWD') or io.popen('cd'):read()
    end

    ---@param path string
    ---@return string[]
    function private.splitBySep(path)
        local segments = {}
        for segment in string.gmatch(path, private.sepSplitPattern) do
            table.insert(segments, segment)
        end
        return segments
    end

    ---@param basename string
    ---@return string name
    ---@return string ext
    function private.parseNameAndExt(basename)
        if basename == '' or basename == '.' or basename == '..' then
            return basename, ''
        end

        local name = string.match(basename, '(.+)%.[^%.]*$') or ''
        local ext = string.match(basename, '.+(%.[^%.]*)$') or ''

        if ext == '' then
            name = basename
        end

        return name, ext
    end

    ---@param path string
    ---@return string path
    function private.replaceSep(path)
        if private.isWin32 == true then
            path = string.gsub(path, '/', '\\')
        end
        return path
    end

    ---@param path any
    ---@return { rootSegment: string, segments: string[], isAbsolute: boolean } pathDataList
    function private.getPathDataList(path)
        local pathDataList = {
            rootSegment = '',
            segments = {},
            isAbsolute = false
        }

        local rootInfo = private.getRootInfo(path)
        if rootInfo ~= nil then
            pathDataList.isAbsolute = true
            pathDataList.rootSegment = rootInfo.path
            path = string.sub(path, string.len(rootInfo.path), string.len(path))
        end

        for segment in string.gmatch(path, private.sepSplitPattern) do
            table.insert(pathDataList.segments, segment)
        end

        return pathDataList
    end

    function private.handleJumps(pathDataList)
        local segments = {}
        local preserveJump = pathDataList.isAbsolute == false

        for _, segment in ipairs(pathDataList.segments) do
            if segment ~= '.' then
                if segment == '..' then
                    if #segments == 0 then
                        if preserveJump == true then
                            table.insert(segments, segment)
                        end
                    else
                        if preserveJump == false then
                            if segments[#segments] ~= segment then
                                table.remove(segments, #segments)
                            end
                        else
                            if segments[#segments] == segment then
                                table.insert(segments, segment)
                            else
                                table.remove(segments, #segments)
                            end
                        end
                    end
                else
                    table.insert(segments, segment)
                end
            end
        end

        pathDataList.segments = segments

        return pathDataList
    end

    ---@param path string
    ---@return boolean
    function private.isRoot(path)
        local root = private.getRootInfo(path)
        return root ~= nil and root.path == path
    end

    function private.tablePack(...)
        local lua_version = _VERSION
        if lua_version == "Lua 5.1" then
            local t = {...}
            t.n = #t
            return t
        end
        return table.pack(...)
    end

    function private.tableUnpack(...)
        local lua_version = _VERSION
        if lua_version == "Lua 5.1" then
            return unpack(...)
        end
        return table.unpack(...)
    end

    setmetatable(public, self)
    self.__index = self;
    return public
end

Path.posix = Path:new(true)
Path.win32 = Path:new(false)

if package.config:sub(1,1) == '/' then
    return Path.posix
end

return Path.win32
