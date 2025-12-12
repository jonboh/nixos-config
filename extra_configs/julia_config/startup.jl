using Pkg
if isfile("Project.toml") && isfile("Manifest.toml")
    Pkg.activate(".")
end

atreplinit() do repl
    try
        @eval using OhMyREPL
        @eval enable_autocomplete_brackets(false)
    catch e
        @warn "error while importing OhMyREPL" e
    end
end

try
    using Revise
catch e
    @warn "Error initializing Revise" exception = (e, catch_backtrace())
end
