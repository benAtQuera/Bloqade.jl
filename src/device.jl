struct CuSparseDeviceMatrixCSR{Tv} <: AbstractCuSparseMatrix{Tv}
    rowPtr::CuDeviceVector{Cint, AS.Global}
    colVal::CuDeviceVector{Cint, AS.Global}
    nzVal::CuDeviceVector{Tv, AS.Global}
    dims::NTuple{2, Int}
    nnz::Cint
end

Base.size(H::CuSparseDeviceMatrixCSR) = H.dims

function Adapt.adapt_structure(to::CUDA.Adaptor, x::CuSparseMatrixCSR{Tv}) where Tv
    CuSparseDeviceMatrixCSR(cudaconvert(x.rowPtr), cudaconvert(x.colVal), cudaconvert(x.nzVal), x.dims, x.nnz)
end

function Base.show(io::IO, ::MIME"text/plain", A::CuSparseDeviceMatrixCSR)
    println(io, "$(length(A))-element device sparse matrix CSR at:")
    println(io, "  rowPtr $(pointer(A.rowPtr))")
    println(io, "  colVal $(pointer(A.colVal))")
    print(io, "  nzVal $(pointer(A.nzVal))")
end

function Adapt.adapt_structure(to, t::XTerm)
    XTerm(t.nsites, adapt(to, t.Ωs), adapt(to, t.ϕs))
end

function Adapt.adapt_structure(to, t::ZTerm)
    ZTerm(t.nsites, adapt(to, t.Δs))
end

function Adapt.adapt_structure(to, t::RydInteract)
    RydInteract(t.C, adapt(to, t.atoms))
end

function Adapt.adapt_structure(to, t::Hamiltonian)
    Hamiltonian(map(x->Adapt.adapt(to, x), t.terms))
end

function Adapt.adapt_structure(to, r::RydbergReg{N}) where {N}
    return RydbergReg{N}(adapt(to, r.state), adapt(to, r.subspace))
end

Adapt.adapt_structure(to, s::Subspace) = Subspace(s.map, adapt(to, s.subspace_v))

function Adapt.adapt_structure(to, Ks::KrylovSubspace)
    KrylovSubspace(Ks.m, Ks.maxiter, Ks.augmented, Ks.beta, adapt(to, Ks.V), adapt(to, Ks.H))
end

function Adapt.adapt_structure(to::Type{<:CuArray}, cache::EmulatorCache)
    return EmulatorCache(adapt(to, cache.Ks), CuSparseMatrixCSR(cache.H))
end

function RydbergEmulator.emulate!(r::Yao.ArrayReg{<:Any, <:Any, <:CuArray}, ts::Vector{<:Real}, hs::Vector{<:AbstractTerm}, cache=cu(EmulatorCache(ts, hs)))
    emulate_routine!(r, ts, hs, cache.Ks, cache.H)
    return r
end

function RydbergEmulator.emulate!(r::RydbergReg{<:Any, <:Any, <:CuArray}, ts::Vector{<:Real}, hs::Vector{<:AbstractTerm}, cache=cu(EmulatorCache(ts, hs, r.subspace)))
    emulate_routine!(r, ts, hs, cache.Ks, cache.H)
    return r
end
