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
extenum @ecs.EcsPayload += {
  EcsPayload_ecs_ChangedMarker(ChangedMarker)
  EcsPayload_ecs_Dummy(Dummy)
  EcsPayload_ecs_CustomDisabled(CustomDisabled)
  EcsPayload_ecs_AddedMarker(AddedMarker)
  EcsPayload_ecs_TestMarker(TestMarker)
  EcsPayload_ecs_RuntimeConfig(RuntimeConfig)
  EcsPayload_ecs_BrokenConfig(BrokenConfig)
  EcsPayload_ecs_RequiredA(RequiredA)
  EcsPayload_ecs_RequiredB(RequiredB)
  EcsPayload_ecs_RequiredC(RequiredC)
  EcsPayload_ecs_RequiredCounter(RequiredCounter)
  EcsPayload_ecs_BenchPosition(BenchPosition)
  EcsPayload_ecs_BenchVelocity(BenchVelocity)
  EcsPayload_ecs_BenchHealth(BenchHealth)
  EcsPayload_ecs_BenchMass(BenchMass)
  EcsPayload_ecs_BenchSparseTag(BenchSparseTag)
  EcsPayload_ecs_TestRuntimeMessage(TestRuntimeMessage)
  EcsPayload_ecs_TestDefaultRuntimeMessage(TestDefaultRuntimeMessage)
  EcsPayload_ecs_RuntimeEvent(RuntimeEvent)
  EcsPayload_ecs_BrokenEvent(BrokenEvent)
  EcsPayload_ecs_MutQueryPosition(MutQueryPosition)
  EcsPayload_ecs_MutQueryVelocity(MutQueryVelocity)
  EcsPayload_ecs_MutQueryAcceleration(MutQueryAcceleration)
  EcsPayload_ecs_MutQueryMarker(MutQueryMarker)
  EcsPayload_ecs_MutQueryMethodValue(MutQueryMethodValue)
  EcsPayload_ecs_Position(Position)
  EcsPayload_ecs_Velocity(Velocity)
  EcsPayload_ecs_Acceleration(Acceleration)
  EcsPayload_ecs_SparseTag(SparseTag)
  EcsPayload_ecs_GenericPosition(GenericPosition)
  EcsPayload_ecs_GenericVelocity(GenericVelocity)
  EcsPayload_ecs_GenericTag(GenericTag)
  EcsPayload_ecs_HookTestComponent(HookTestComponent)
  EcsPayload_ecs_DuplicateHookTestComponent(DuplicateHookTestComponent)
  EcsPayload_ecs_LateRegistrationHookTestComponent(
    LateRegistrationHookTestComponent
  )
  EcsPayload_ecs_HookCommandsTestComponent(HookCommandsTestComponent)
  EcsPayload_ecs_HooksWithRegistrationTestComponent(
    HooksWithRegistrationTestComponent
  )
  EcsPayload_ecs_HooksWithLateRegistrationTestComponent(
    HooksWithLateRegistrationTestComponent
  )
  EcsPayload_ecs_ObserverMarker(ObserverMarker)
  EcsPayload_ecs_ObserverParentLink(ObserverParentLink)
  EcsPayload_ecs_ObserverParentLinkStable(ObserverParentLinkStable)
  EcsPayload_ecs_ObserverParentLinkLate(ObserverParentLinkLate)
  EcsPayload_ecs_ObserverDetonate(ObserverDetonate)
  EcsPayload_ecs_ObserverAttack(ObserverAttack)
  EcsPayload_ecs_ObserverParentLookupProbe(ObserverParentLookupProbe)
  EcsPayload_ecs_TypedCounter(TypedCounter)
  EcsPayload_ecs_TypedMarker(TypedMarker)
  EcsPayload_ecs_WorldLocalProbe(WorldLocalProbe)
  EcsPayload_ecs_WorldLocalComponent(WorldLocalComponent)
  EcsPayload_ecs_QueuedRequireA(QueuedRequireA)
  EcsPayload_ecs_QueuedRequireB(QueuedRequireB)
  EcsPayload_ecs_SparseStorageCounter(SparseStorageCounter)
  EcsPayload_ecs_StorageModeProbe(StorageModeProbe)
  EcsPayload_ecs_QueuedOrderProbe(QueuedOrderProbe)
  EcsPayload_ecs_ParityHookRegistrationProbe(ParityHookRegistrationProbe)
  EcsPayload_ecs_ParityRequiredA(ParityRequiredA)
  EcsPayload_ecs_ParityRequiredB(ParityRequiredB)
  EcsPayload_ecs_ParityRequiredC(ParityRequiredC)
  EcsPayload_ecs_Counter(Counter)
  EcsPayload_ecs_GlobalConfig(GlobalConfig)
  EcsPayload_ecs_TickEvent(TickEvent)
  EcsPayload_ecs_BrokenCounter(BrokenCounter)
}

///|
pub impl @ecs.EcsPayloadCodec for ChangedMarker with to_ecs_payload(self) {
  EcsPayload_ecs_ChangedMarker(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ChangedMarker with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ecs_ChangedMarker(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Dummy with to_ecs_payload(self) {
  EcsPayload_ecs_Dummy(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Dummy with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ecs_Dummy(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for CustomDisabled with to_ecs_payload(self) {
  EcsPayload_ecs_CustomDisabled(self)
}

///|
pub impl @ecs.EcsPayloadCodec for CustomDisabled with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ecs_CustomDisabled(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for AddedMarker with to_ecs_payload(self) {
  EcsPayload_ecs_AddedMarker(self)
}

///|
pub impl @ecs.EcsPayloadCodec for AddedMarker with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ecs_AddedMarker(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for TestMarker with to_ecs_payload(self) {
  EcsPayload_ecs_TestMarker(self)
}

///|
pub impl @ecs.EcsPayloadCodec for TestMarker with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ecs_TestMarker(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for RuntimeConfig with to_ecs_payload(self) {
  EcsPayload_ecs_RuntimeConfig(self)
}

///|
pub impl @ecs.EcsPayloadCodec for RuntimeConfig with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ecs_RuntimeConfig(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for BrokenConfig with to_ecs_payload(self) {
  EcsPayload_ecs_BrokenConfig(self)
}

///|
pub impl @ecs.EcsPayloadCodec for BrokenConfig with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ecs_BrokenConfig(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for RequiredA with to_ecs_payload(self) {
  EcsPayload_ecs_RequiredA(self)
}

///|
pub impl @ecs.EcsPayloadCodec for RequiredA with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ecs_RequiredA(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for RequiredB with to_ecs_payload(self) {
  EcsPayload_ecs_RequiredB(self)
}

///|
pub impl @ecs.EcsPayloadCodec for RequiredB with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ecs_RequiredB(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for RequiredC with to_ecs_payload(self) {
  EcsPayload_ecs_RequiredC(self)
}

///|
pub impl @ecs.EcsPayloadCodec for RequiredC with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ecs_RequiredC(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for RequiredCounter with to_ecs_payload(self) {
  EcsPayload_ecs_RequiredCounter(self)
}

///|
pub impl @ecs.EcsPayloadCodec for RequiredCounter with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ecs_RequiredCounter(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for BenchPosition with to_ecs_payload(self) {
  EcsPayload_ecs_BenchPosition(self)
}

///|
pub impl @ecs.EcsPayloadCodec for BenchPosition with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ecs_BenchPosition(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for BenchVelocity with to_ecs_payload(self) {
  EcsPayload_ecs_BenchVelocity(self)
}

///|
pub impl @ecs.EcsPayloadCodec for BenchVelocity with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ecs_BenchVelocity(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for BenchHealth with to_ecs_payload(self) {
  EcsPayload_ecs_BenchHealth(self)
}

///|
pub impl @ecs.EcsPayloadCodec for BenchHealth with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ecs_BenchHealth(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for BenchMass with to_ecs_payload(self) {
  EcsPayload_ecs_BenchMass(self)
}

///|
pub impl @ecs.EcsPayloadCodec for BenchMass with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ecs_BenchMass(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for BenchSparseTag with to_ecs_payload(self) {
  EcsPayload_ecs_BenchSparseTag(self)
}

///|
pub impl @ecs.EcsPayloadCodec for BenchSparseTag with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ecs_BenchSparseTag(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for TestRuntimeMessage with to_ecs_payload(self) {
  EcsPayload_ecs_TestRuntimeMessage(self)
}

///|
pub impl @ecs.EcsPayloadCodec for TestRuntimeMessage with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_ecs_TestRuntimeMessage(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for TestDefaultRuntimeMessage with to_ecs_payload(
  self,
) {
  EcsPayload_ecs_TestDefaultRuntimeMessage(self)
}

///|
pub impl @ecs.EcsPayloadCodec for TestDefaultRuntimeMessage with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_ecs_TestDefaultRuntimeMessage(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for RuntimeEvent with to_ecs_payload(self) {
  EcsPayload_ecs_RuntimeEvent(self)
}

///|
pub impl @ecs.EcsPayloadCodec for RuntimeEvent with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ecs_RuntimeEvent(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for BrokenEvent with to_ecs_payload(self) {
  EcsPayload_ecs_BrokenEvent(self)
}

///|
pub impl @ecs.EcsPayloadCodec for BrokenEvent with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ecs_BrokenEvent(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for MutQueryPosition with to_ecs_payload(self) {
  EcsPayload_ecs_MutQueryPosition(self)
}

///|
pub impl @ecs.EcsPayloadCodec for MutQueryPosition with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_ecs_MutQueryPosition(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for MutQueryVelocity with to_ecs_payload(self) {
  EcsPayload_ecs_MutQueryVelocity(self)
}

///|
pub impl @ecs.EcsPayloadCodec for MutQueryVelocity with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_ecs_MutQueryVelocity(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for MutQueryAcceleration with to_ecs_payload(self) {
  EcsPayload_ecs_MutQueryAcceleration(self)
}

///|
pub impl @ecs.EcsPayloadCodec for MutQueryAcceleration with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_ecs_MutQueryAcceleration(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for MutQueryMarker with to_ecs_payload(self) {
  EcsPayload_ecs_MutQueryMarker(self)
}

///|
pub impl @ecs.EcsPayloadCodec for MutQueryMarker with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ecs_MutQueryMarker(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for MutQueryMethodValue with to_ecs_payload(self) {
  EcsPayload_ecs_MutQueryMethodValue(self)
}

///|
pub impl @ecs.EcsPayloadCodec for MutQueryMethodValue with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_ecs_MutQueryMethodValue(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Position with to_ecs_payload(self) {
  EcsPayload_ecs_Position(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Position with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ecs_Position(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Velocity with to_ecs_payload(self) {
  EcsPayload_ecs_Velocity(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Velocity with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ecs_Velocity(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Acceleration with to_ecs_payload(self) {
  EcsPayload_ecs_Acceleration(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Acceleration with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ecs_Acceleration(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for SparseTag with to_ecs_payload(self) {
  EcsPayload_ecs_SparseTag(self)
}

///|
pub impl @ecs.EcsPayloadCodec for SparseTag with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ecs_SparseTag(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for GenericPosition with to_ecs_payload(self) {
  EcsPayload_ecs_GenericPosition(self)
}

///|
pub impl @ecs.EcsPayloadCodec for GenericPosition with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ecs_GenericPosition(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for GenericVelocity with to_ecs_payload(self) {
  EcsPayload_ecs_GenericVelocity(self)
}

///|
pub impl @ecs.EcsPayloadCodec for GenericVelocity with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ecs_GenericVelocity(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for GenericTag with to_ecs_payload(self) {
  EcsPayload_ecs_GenericTag(self)
}

///|
pub impl @ecs.EcsPayloadCodec for GenericTag with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ecs_GenericTag(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for HookTestComponent with to_ecs_payload(self) {
  EcsPayload_ecs_HookTestComponent(self)
}

///|
pub impl @ecs.EcsPayloadCodec for HookTestComponent with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_ecs_HookTestComponent(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for DuplicateHookTestComponent with to_ecs_payload(
  self,
) {
  EcsPayload_ecs_DuplicateHookTestComponent(self)
}

///|
pub impl @ecs.EcsPayloadCodec for DuplicateHookTestComponent with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_ecs_DuplicateHookTestComponent(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for LateRegistrationHookTestComponent with to_ecs_payload(
  self,
) {
  EcsPayload_ecs_LateRegistrationHookTestComponent(self)
}

///|
pub impl @ecs.EcsPayloadCodec for LateRegistrationHookTestComponent with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_ecs_LateRegistrationHookTestComponent(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for HookCommandsTestComponent with to_ecs_payload(
  self,
) {
  EcsPayload_ecs_HookCommandsTestComponent(self)
}

///|
pub impl @ecs.EcsPayloadCodec for HookCommandsTestComponent with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_ecs_HookCommandsTestComponent(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for HooksWithRegistrationTestComponent with to_ecs_payload(
  self,
) {
  EcsPayload_ecs_HooksWithRegistrationTestComponent(self)
}

///|
pub impl @ecs.EcsPayloadCodec for HooksWithRegistrationTestComponent with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_ecs_HooksWithRegistrationTestComponent(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for HooksWithLateRegistrationTestComponent with to_ecs_payload(
  self,
) {
  EcsPayload_ecs_HooksWithLateRegistrationTestComponent(self)
}

///|
pub impl @ecs.EcsPayloadCodec for HooksWithLateRegistrationTestComponent with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_ecs_HooksWithLateRegistrationTestComponent(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ObserverMarker with to_ecs_payload(self) {
  EcsPayload_ecs_ObserverMarker(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ObserverMarker with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ecs_ObserverMarker(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ObserverParentLink with to_ecs_payload(self) {
  EcsPayload_ecs_ObserverParentLink(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ObserverParentLink with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_ecs_ObserverParentLink(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ObserverParentLinkStable with to_ecs_payload(
  self,
) {
  EcsPayload_ecs_ObserverParentLinkStable(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ObserverParentLinkStable with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_ecs_ObserverParentLinkStable(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ObserverParentLinkLate with to_ecs_payload(
  self,
) {
  EcsPayload_ecs_ObserverParentLinkLate(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ObserverParentLinkLate with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_ecs_ObserverParentLinkLate(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ObserverDetonate with to_ecs_payload(self) {
  EcsPayload_ecs_ObserverDetonate(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ObserverDetonate with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_ecs_ObserverDetonate(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ObserverAttack with to_ecs_payload(self) {
  EcsPayload_ecs_ObserverAttack(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ObserverAttack with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ecs_ObserverAttack(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ObserverParentLookupProbe with to_ecs_payload(
  self,
) {
  EcsPayload_ecs_ObserverParentLookupProbe(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ObserverParentLookupProbe with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_ecs_ObserverParentLookupProbe(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for TypedCounter with to_ecs_payload(self) {
  EcsPayload_ecs_TypedCounter(self)
}

///|
pub impl @ecs.EcsPayloadCodec for TypedCounter with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ecs_TypedCounter(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for TypedMarker with to_ecs_payload(self) {
  EcsPayload_ecs_TypedMarker(self)
}

///|
pub impl @ecs.EcsPayloadCodec for TypedMarker with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ecs_TypedMarker(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for WorldLocalProbe with to_ecs_payload(self) {
  EcsPayload_ecs_WorldLocalProbe(self)
}

///|
pub impl @ecs.EcsPayloadCodec for WorldLocalProbe with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ecs_WorldLocalProbe(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for WorldLocalComponent with to_ecs_payload(self) {
  EcsPayload_ecs_WorldLocalComponent(self)
}

///|
pub impl @ecs.EcsPayloadCodec for WorldLocalComponent with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_ecs_WorldLocalComponent(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for QueuedRequireA with to_ecs_payload(self) {
  EcsPayload_ecs_QueuedRequireA(self)
}

///|
pub impl @ecs.EcsPayloadCodec for QueuedRequireA with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ecs_QueuedRequireA(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for QueuedRequireB with to_ecs_payload(self) {
  EcsPayload_ecs_QueuedRequireB(self)
}

///|
pub impl @ecs.EcsPayloadCodec for QueuedRequireB with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ecs_QueuedRequireB(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for SparseStorageCounter with to_ecs_payload(self) {
  EcsPayload_ecs_SparseStorageCounter(self)
}

///|
pub impl @ecs.EcsPayloadCodec for SparseStorageCounter with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_ecs_SparseStorageCounter(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for StorageModeProbe with to_ecs_payload(self) {
  EcsPayload_ecs_StorageModeProbe(self)
}

///|
pub impl @ecs.EcsPayloadCodec for StorageModeProbe with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_ecs_StorageModeProbe(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for QueuedOrderProbe with to_ecs_payload(self) {
  EcsPayload_ecs_QueuedOrderProbe(self)
}

///|
pub impl @ecs.EcsPayloadCodec for QueuedOrderProbe with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_ecs_QueuedOrderProbe(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ParityHookRegistrationProbe with to_ecs_payload(
  self,
) {
  EcsPayload_ecs_ParityHookRegistrationProbe(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ParityHookRegistrationProbe with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_ecs_ParityHookRegistrationProbe(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ParityRequiredA with to_ecs_payload(self) {
  EcsPayload_ecs_ParityRequiredA(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ParityRequiredA with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ecs_ParityRequiredA(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ParityRequiredB with to_ecs_payload(self) {
  EcsPayload_ecs_ParityRequiredB(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ParityRequiredB with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ecs_ParityRequiredB(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ParityRequiredC with to_ecs_payload(self) {
  EcsPayload_ecs_ParityRequiredC(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ParityRequiredC with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ecs_ParityRequiredC(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Counter with to_ecs_payload(self) {
  EcsPayload_ecs_Counter(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Counter with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ecs_Counter(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for GlobalConfig with to_ecs_payload(self) {
  EcsPayload_ecs_GlobalConfig(self)
}

///|
pub impl @ecs.EcsPayloadCodec for GlobalConfig with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ecs_GlobalConfig(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for TickEvent with to_ecs_payload(self) {
  EcsPayload_ecs_TickEvent(self)
}

///|
pub impl @ecs.EcsPayloadCodec for TickEvent with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ecs_TickEvent(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for BrokenCounter with to_ecs_payload(self) {
  EcsPayload_ecs_BrokenCounter(self)
}

///|
pub impl @ecs.EcsPayloadCodec for BrokenCounter with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ecs_BrokenCounter(value) => Some(value)
    _ => None
  }
}
