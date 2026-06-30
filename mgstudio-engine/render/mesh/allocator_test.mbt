// Copyright 2026 International Digital Economy Academy
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

///|
test "render mesh allocator: element layouts preserve bevy copy alignment slots" {
  let vertex_32 = MeshAllocatorElementLayout::vertex(32)
  inspect(vertex_32.class() is Vertex, content="true")
  inspect(vertex_32.elements_per_slot(), content="1")
  inspect(vertex_32.slot_size(), content="32")
  let index_u16 = MeshAllocatorElementLayout::index_u16()
  inspect(index_u16.class() is Index, content="true")
  inspect(index_u16.elements_per_slot(), content="2")
  inspect(index_u16.slot_size(), content="4")
  let packed_3 = MeshAllocatorElementLayout::new(Vertex, 3)
  inspect(packed_3.elements_per_slot(), content="4")
  inspect(packed_3.slot_size(), content="12")
  let packed_5 = MeshAllocatorElementLayout::new(Vertex, 5)
  inspect(packed_5.elements_per_slot(), content="4")
  inspect(packed_5.slot_size(), content="20")
}

///|
test "render mesh allocator: default settings preserve bevy slab thresholds" {
  let settings = @mesh.MeshAllocatorSettings::MeshAllocatorSettings()
  inspect(settings.min_slab_size(), content="1048576")
  inspect(settings.max_slab_size(), content="536870912")
  inspect(settings.large_threshold(), content="268435456")
  inspect(settings.growth_factor(), content="1.5")
}

///|
test "render mesh allocator: new general slab starts at min slab capacity" {
  let plan = mesh_allocator_plan_new_general_slab(
    7,
    96,
    MeshAllocatorElementLayout::vertex(32),
  )
  inspect(plan.slab_id(), content="7")
  inspect(plan.kind() is General, content="true")
  inspect(plan.offset(), content="0")
  inspect(plan.slot_count(), content="3")
  inspect(plan.current_slot_capacity(), content="32768")
  inspect(plan.growth().kind() is NeededGrowth, content="true")
  inspect(plan.growth().old_slot_capacity(), content="0")
}

///|
test "render mesh allocator: growth follows bevy factor until capacity fits" {
  let layout = MeshAllocatorElementLayout::vertex(32)
  let settings = MeshAllocatorSettings::new(
    min_slab_size=32,
    max_slab_size=32 * 16,
    large_threshold=32 * 128,
    growth_factor=1.5F,
  )
  let no_growth = mesh_allocator_grow_general_slab_if_necessary(
    4,
    4,
    layout,
    settings~,
  )
  inspect(no_growth.kind() is NoGrowthNeeded, content="true")
  inspect(no_growth.current_slot_capacity(), content="4")
  let grown = mesh_allocator_grow_general_slab_if_necessary(
    4,
    8,
    layout,
    settings~,
  )
  inspect(grown.kind() is NeededGrowth, content="true")
  inspect(grown.old_slot_capacity(), content="4")
  inspect(grown.current_slot_capacity(), content="9")
  let full = mesh_allocator_grow_general_slab_if_necessary(
    16,
    17,
    layout,
    settings~,
  )
  inspect(full.kind() is CantGrow, content="true")
  inspect(full.current_slot_capacity(), content="16")
}

///|
test "render mesh allocator: large-object decision uses min threshold max slab" {
  let layout = MeshAllocatorElementLayout::vertex(32)
  let settings = MeshAllocatorSettings::new(
    min_slab_size=64,
    max_slab_size=512,
    large_threshold=256,
    growth_factor=1.5F,
  )
  inspect(
    mesh_allocator_should_allocate_large(224, layout, settings~),
    content="false",
  )
  inspect(
    mesh_allocator_should_allocate_large(256, layout, settings~),
    content="true",
  )
  let large = mesh_allocator_plan_large_slab(3, 256, layout)
  inspect(large.kind() is LargeObject, content="true")
  inspect(large.slot_count(), content="8")
  inspect(large.current_slot_capacity(), content="8")
}

///|
test "render mesh allocator: state records vertex and index slab ids" {
  let allocator = MeshAllocator::new()
  let vertex_layout = MeshAllocatorElementLayout::vertex(32)
  let index_layout = MeshAllocatorElementLayout::index_u32()
  guard allocator.allocate(10, 96, vertex_layout) is Some(vertex_plan) else {
    fail("expected vertex allocation")
  }
  guard allocator.allocate(10, 24, index_layout) is Some(index_plan) else {
    fail("expected index allocation")
  }
  inspect(vertex_plan.kind() is General, content="true")
  inspect(index_plan.kind() is General, content="true")
  inspect(allocator.slab_count(), content="2")
  guard allocator.mesh_slabs(10) is Some(mesh_slabs) else {
    fail("expected mesh slab ids")
  }
  inspect(mesh_slabs.vertex_slab_id() == vertex_plan.slab_id(), content="true")
  inspect(
    mesh_slabs.index_slab_id() == Some(index_plan.slab_id()),
    content="true",
  )
  inspect(allocator.allocations(), content="1")
  guard allocator.mesh_vertex_slice(10) is Some(vertex_slice) else {
    fail("expected vertex slice")
  }
  inspect(vertex_slice.start(), content="0")
  inspect(vertex_slice.end(), content="3")
  guard allocator.mesh_index_slice(10) is Some(index_slice) else {
    fail("expected index slice")
  }
  inspect(index_slice.start(), content="0")
  inspect(index_slice.end(), content="6")
}

///|
test "render mesh allocator: free removes both maps and empty slabs" {
  let allocator = MeshAllocator::new()
  let vertex_layout = MeshAllocatorElementLayout::vertex(32)
  let index_layout = MeshAllocatorElementLayout::index_u16()
  ignore(allocator.allocate(20, 64, vertex_layout))
  ignore(allocator.allocate(20, 12, index_layout))
  inspect(allocator.slab_count(), content="2")
  allocator.free_mesh(20)
  inspect(allocator.slab_count(), content="0")
  inspect(allocator.mesh_slabs(20) is None, content="true")
  inspect(allocator.mesh_vertex_slice(20) is None, content="true")
}

///|
test "render mesh allocator: modified meshes follow bevy free-before-allocate semantics" {
  let allocator = MeshAllocator::new()
  let layout = MeshAllocatorElementLayout::vertex(32)
  ignore(allocator.allocate(30, 64, layout))
  ignore(allocator.allocate(31, 64, layout))
  inspect(allocator.slab_count(), content="1")
  allocator.free_meshes([], [30])
  inspect(allocator.mesh_slabs(30) is None, content="true")
  inspect(allocator.mesh_slabs(31) is Some(_), content="true")
  inspect(allocator.slab_count(), content="1")
}

///|
test "render mesh allocator: general slabs grow instead of creating new slab" {
  let allocator = MeshAllocator::new()
  let layout = MeshAllocatorElementLayout::vertex(32)
  let settings = MeshAllocatorSettings::new(
    min_slab_size=64,
    max_slab_size=512,
    large_threshold=1024,
    growth_factor=1.5F,
  )
  guard allocator.allocate(35, 64, layout, settings~) is Some(first) else {
    fail("expected first allocation")
  }
  guard allocator.allocate(36, 64, layout, settings~) is Some(second) else {
    fail("expected second allocation")
  }
  inspect(first.slab_id(), content="0")
  inspect(first.current_slot_capacity(), content="2")
  inspect(second.slab_id(), content="0")
  inspect(second.offset(), content="2")
  inspect(second.growth().kind() is NeededGrowth, content="true")
  inspect(second.growth().old_slot_capacity(), content="2")
  inspect(second.current_slot_capacity(), content="5")
  inspect(allocator.slab_count(), content="1")
}

///|
test "render mesh allocator: upload plans preserve bevy general write semantics" {
  let allocator = MeshAllocator::new()
  let layout = MeshAllocatorElementLayout::vertex(3)
  guard allocator.allocate(37, 5, layout) is Some(plan) else {
    fail("expected allocation")
  }
  guard allocator.pending_upload_plan(37, Vertex, 5) is Some(upload) else {
    fail("expected upload plan")
  }
  inspect(upload.slab_id(), content="\{plan.slab_id()}")
  inspect(upload.label(), content="general mesh slab 0 (vertex buffer)")
  inspect(upload.usage() is VertexBuffer, content="true")
  inspect(upload.offset(), content="0")
  inspect(upload.size(), content="12")
  inspect(upload.mapped_at_creation(), content="false")
  inspect(allocator.mark_resident(37, Vertex), content="true")
  inspect(allocator.pending_upload_plan(37, Vertex, 5) is None, content="true")
}

///|
test "render mesh allocator: render mesh plan allocates vertex and index uploads" {
  let allocator = MeshAllocator::new()
  let mesh = RenderMesh::new(vertex_count=4, indexed=true, index_count=6)
  let plan = allocator.allocate_render_mesh(41, mesh, 32)
  guard plan.vertex_allocation() is Some(vertex_allocation) else {
    fail("expected vertex allocation")
  }
  guard plan.index_allocation() is Some(index_allocation) else {
    fail("expected index allocation")
  }
  inspect(vertex_allocation.kind() is General, content="true")
  inspect(vertex_allocation.slot_count(), content="4")
  inspect(index_allocation.kind() is General, content="true")
  inspect(index_allocation.slot_count(), content="6")
  guard plan.vertex_upload() is Some(vertex_upload) else {
    fail("expected vertex upload")
  }
  guard plan.index_upload() is Some(index_upload) else {
    fail("expected index upload")
  }
  inspect(vertex_upload.usage() is VertexBuffer, content="true")
  inspect(vertex_upload.size(), content="128")
  inspect(index_upload.usage() is IndexBuffer, content="true")
  inspect(index_upload.size(), content="24")
  inspect(plan.vertex_reallocate() is Some(_), content="true")
  inspect(plan.index_reallocate() is Some(_), content="true")
}

///|
test "render mesh allocator: render mesh index format selects index layout" {
  let allocator = MeshAllocator::new()
  let mesh = RenderMesh::new(
    vertex_count=4,
    indexed=true,
    index_count=6,
    index_format=Uint16,
  )
  let plan = allocator.allocate_render_mesh(44, mesh, 32)
  guard plan.index_allocation() is Some(index_allocation) else {
    fail("expected index allocation")
  }
  guard plan.index_upload() is Some(index_upload) else {
    fail("expected index upload")
  }
  inspect(index_allocation.slot_count(), content="3")
  inspect(index_upload.size(), content="12")
}

///|
test "render mesh allocator: index allocation count tracks indexed meshes only" {
  let allocator = MeshAllocator::new()
  let indexed = RenderMesh::new(vertex_count=4, indexed=true, index_count=6)
  let non_indexed = RenderMesh::new(vertex_count=3)
  ignore(allocator.allocate_render_mesh(45, indexed, 32))
  ignore(allocator.allocate_render_mesh(46, non_indexed, 32))
  inspect(allocator.index_allocation_count(), content="1")
  allocator.free_mesh(45)
  inspect(allocator.index_allocation_count(), content="0")
}

///|
test "render mesh: constructor preserves topology key and vertex layout" {
  let layouts = @asset_mesh.MeshVertexBufferLayouts::MeshVertexBufferLayouts()
  let layout = layouts.insert(
    @asset_mesh.MeshVertexBufferLayout::new(
      attribute_ids=[],
      layout=@asset_mesh.VertexBufferLayout::new(
        array_stride=0,
        step_mode=@asset_mesh.MeshVertexStepMode::Vertex,
        attributes=[],
      ),
    ),
  )
  let key_bits = @asset_mesh.BaseMeshPipelineKey::from_primitive_topology(
    @asset_mesh.Mesh3dPrimitiveTopology::LineList,
  )
  let render_mesh = RenderMesh::new(
    vertex_count=2,
    indexed=false,
    key_bits~,
    layout~,
  )
  inspect(render_mesh.vertex_count(), content="2")
  inspect(render_mesh.indexed(), content="false")
  inspect(
    render_mesh.primitive_topology() ==
    @asset_mesh.Mesh3dPrimitiveTopology::LineList,
    content="true",
  )
  inspect(render_mesh.layout().index(), content="0")
  inspect(layouts.len(), content="1")
}

///|
test "render mesh: from mesh includes morph target key bit" {
  let geometry = @asset_mesh.Mesh3dGeometry::new(
    [
      @math.Vec3::new(0.0F, 0.0F, 0.0F),
      @math.Vec3::new(1.0F, 0.0F, 0.0F),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ],
    [
      @math.Vec2::new(0.0F, 0.0F),
      @math.Vec2::new(1.0F, 0.0F),
      @math.Vec2::new(0.0F, 1.0F),
    ],
    Some([0, 1, 2]),
  ).with_morph_targets(
    Some([
      [
        @math.Vec3::new(0.1F, 0.0F, 0.0F),
        @math.Vec3::new(0.0F, 0.1F, 0.0F),
        @math.Vec3::new(0.0F, 0.0F, 0.1F),
      ],
    ]),
  )
  let layouts = @asset_mesh.MeshVertexBufferLayouts::MeshVertexBufferLayouts()
  let render_mesh = RenderMesh::from_mesh(
    @asset_mesh.Mesh::from_3d_geometry(geometry),
    layouts,
  )
  inspect(render_mesh.key_bits().contains_morph_targets(), content="true")
}

///|
test "render mesh assets: prepare assets owns render mesh conversion" {
  let geometry = @asset_mesh.Mesh3dGeometry::new(
    [
      @math.Vec3::new(0.0F, 0.0F, 0.0F),
      @math.Vec3::new(1.0F, 0.0F, 0.0F),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ],
    [
      @math.Vec2::new(0.0F, 0.0F),
      @math.Vec2::new(1.0F, 0.0F),
      @math.Vec2::new(0.0F, 1.0F),
    ],
    Some([0, 1, 2]),
  )
  let layouts = @asset_mesh.MeshVertexBufferLayouts::MeshVertexBufferLayouts()
  let assets = RenderMeshAssets::RenderMeshAssets()
  assets.prepare_assets(
    [
      ExtractedRenderMeshAsset::new(
        77,
        @asset_mesh.Mesh::from_3d_geometry(geometry),
      ),
    ],
    layouts,
  )
  inspect(assets.len(), content="1")
  guard assets.get(77) is Some(render_mesh) else {
    fail("expected prepared render mesh")
  }
  inspect(render_mesh.vertex_count(), content="3")
  inspect(render_mesh.indexed(), content="true")
}

///|
test "render mesh allocator: non-indexed render mesh skips index allocation" {
  let allocator = MeshAllocator::new()
  let mesh = RenderMesh::new(vertex_count=3)
  let plan = allocator.allocate_render_mesh(42, mesh, 32)
  guard plan.vertex_allocation() is Some(vertex_allocation) else {
    fail("expected vertex allocation")
  }
  inspect(vertex_allocation.slot_count(), content="3")
  inspect(plan.index_allocation() is None, content="true")
  inspect(plan.index_upload() is None, content="true")
  inspect(plan.index_reallocate() is None, content="true")
}

///|
test "render mesh allocator: render mesh plan preserves webgl vertex slab rule" {
  let allocator = MeshAllocator::new(general_vertex_slabs_supported=false)
  let mesh = RenderMesh::new(vertex_count=4, indexed=true, index_count=6)
  let plan = allocator.allocate_render_mesh(43, mesh, 32)
  guard plan.vertex_allocation() is Some(vertex_allocation) else {
    fail("expected vertex allocation")
  }
  guard plan.index_allocation() is Some(index_allocation) else {
    fail("expected index allocation")
  }
  inspect(vertex_allocation.kind() is LargeObject, content="true")
  inspect(index_allocation.kind() is General, content="true")
  guard plan.vertex_upload() is Some(vertex_upload) else {
    fail("expected vertex upload")
  }
  guard plan.index_upload() is Some(index_upload) else {
    fail("expected index upload")
  }
  inspect(vertex_upload.mapped_at_creation(), content="true")
  inspect(index_upload.mapped_at_creation(), content="false")
  inspect(plan.vertex_reallocate() is None, content="true")
  inspect(plan.index_reallocate() is Some(_), content="true")
}

///|
test "render mesh allocator: large upload plans preserve mapped buffer labels" {
  let allocator = MeshAllocator::new(general_vertex_slabs_supported=false)
  guard allocator.allocate(38, 96, MeshAllocatorElementLayout::vertex(32))
    is Some(plan) else {
    fail("expected large allocation")
  }
  guard allocator.pending_upload_plan(38, Vertex, 96) is Some(upload) else {
    fail("expected large upload plan")
  }
  inspect(plan.kind() is LargeObject, content="true")
  inspect(upload.label(), content="large mesh slab 0 (vertex buffer)")
  inspect(upload.offset(), content="0")
  inspect(upload.size(), content="96")
  inspect(upload.mapped_at_creation(), content="true")
}

///|
test "render mesh allocator: reallocation plan preserves bevy copy size" {
  let allocator = MeshAllocator::new()
  let layout = MeshAllocatorElementLayout::index_u16()
  let settings = MeshAllocatorSettings::new(
    min_slab_size=8,
    max_slab_size=64,
    large_threshold=128,
    growth_factor=2.0F,
  )
  guard allocator.allocate(39, 8, layout, settings~) is Some(first) else {
    fail("expected first allocation")
  }
  guard allocator.allocate(40, 8, layout, settings~) is Some(second) else {
    fail("expected second allocation")
  }
  inspect(first.current_slot_capacity(), content="2")
  inspect(second.growth().old_slot_capacity(), content="2")
  guard allocator.reallocate_slab_plan(0, second.growth().old_slot_capacity())
    is Some(reallocate) else {
    fail("expected reallocation plan")
  }
  inspect(reallocate.label(), content="general mesh slab 0 (index buffer)")
  inspect(reallocate.usage() is IndexBuffer, content="true")
  inspect(reallocate.new_size(), content="16")
  inspect(reallocate.old_copy_size(), content="8")
}

///|
test "render mesh allocator: webgl-style vertex allocation uses large slabs" {
  let allocator = MeshAllocator::new(general_vertex_slabs_supported=false)
  guard allocator.allocate(40, 96, MeshAllocatorElementLayout::vertex(32))
    is Some(plan) else {
    fail("expected vertex allocation")
  }
  inspect(plan.kind() is LargeObject, content="true")
  inspect(plan.slot_count(), content="3")
  guard allocator.mesh_vertex_slice(40) is Some(slice) else {
    fail("expected large vertex slice")
  }
  inspect(slice.start(), content="0")
  inspect(slice.end(), content="3")
}

///|
test "render mesh allocator plugin initializes resource owners without overwriting" {
  let render_sub_app = @app.SubApp::new(@ecs.World::new())
  let app = @app.App::new(@ecs.World::new())
    .insert_sub_app(@app.RenderApp, render_sub_app)
    .add_plugins(MeshAllocatorPlugin::MeshAllocatorPlugin())
  let render_world = app.get_sub_app(@app.RenderApp).unwrap().world()
  inspect(
    render_world.get_resource(MeshAllocatorSettings::resource()) is Some(_),
    content="true",
  )
  inspect(
    render_world.get_resource(MeshAllocator::resource()) is Some(_),
    content="true",
  )
  inspect(
    render_world.get_resource(RenderMeshAssets::resource()) is Some(_),
    content="true",
  )
  inspect(app.contains_resource(MeshAllocator::resource()), content="false")

  let seeded = MeshAllocator::new(general_vertex_slabs_supported=false)
  let seeded_world = @ecs.World::new()
  seeded_world.insert_resource(MeshAllocator::resource(), seeded)
  let app = @app.App::new(@ecs.World::new())
    .insert_sub_app(@app.RenderApp, @app.SubApp::new(seeded_world))
    .add_plugins(MeshAllocatorPlugin::MeshAllocatorPlugin())
  guard app
    .get_sub_app(@app.RenderApp)
    .unwrap()
    .world()
    .get_resource(MeshAllocator::resource())
    is Some(value) else {
    fail("expected mesh allocator resource")
  }
  guard value.allocate(50, 96, MeshAllocatorElementLayout::vertex(32))
    is Some(plan) else {
    fail("expected webgl-style allocator resource")
  }
  inspect(plan.kind() is LargeObject, content="true")
}

///|
test "render mesh allocator plugin tolerates missing render app" {
  let app = @app.App::new(@ecs.World::new()).add_plugins(
    MeshAllocatorPlugin::MeshAllocatorPlugin(),
  )
  inspect(app.contains_resource(MeshAllocator::resource()), content="false")
}
