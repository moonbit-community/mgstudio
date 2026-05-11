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
  EcsPayload_app_CounterResource(CounterResource)
  EcsPayload_app_HierarchyValidationMarker(HierarchyValidationMarker)
  EcsPayload_app_QueryPosition(QueryPosition)
  EcsPayload_app_QueryVelocity(QueryVelocity)
  EcsPayload_app_QueryMarker(QueryMarker)
  EcsPayload_app_SystemPipingMessage(SystemPipingMessage)
  EcsPayload_app_SystemPipingCounter(SystemPipingCounter)
  EcsPayload_app_SystemPipingMarker(SystemPipingMarker)
  EcsPayload_app_TestMessage(TestMessage)
  EcsPayload_app_EcsPosition(EcsPosition)
  EcsPayload_app_EcsVelocity(EcsVelocity)
  EcsPayload_app_TestAppMessage(TestAppMessage)
  EcsPayload_app_TestCursorAppMessage(TestCursorAppMessage)
  EcsPayload_app_TestDefaultAppMessage(TestDefaultAppMessage)
  EcsPayload_app_OneShotCounterResource(OneShotCounterResource)
  EcsPayload_app_ScheduleBatchMarker(ScheduleBatchMarker)
  EcsPayload_app_MissingRunIfParityResource(MissingRunIfParityResource)
  EcsPayload_app_TriggerIdentityOnce(TriggerIdentityOnce)
  EcsPayload_app_DespawnMarker(DespawnMarker)
  EcsPayload_app_ObserverMarker(ObserverMarker)
  EcsPayload_app_ObserverPulse(ObserverPulse)
  EcsPayload_app_ObserverTriggered(ObserverTriggered)
  EcsPayload_app_TriggerObserverTriggered(TriggerObserverTriggered)
  EcsPayload_app_ErrorHandlingResource(ErrorHandlingResource)
  EcsPayload_app_ErrorHandlingMarker(ErrorHandlingMarker)
  EcsPayload_app_CommandsPosition(CommandsPosition)
  EcsPayload_app_CommandsVelocity(CommandsVelocity)
  EcsPayload_app_CommandsMarker(CommandsMarker)
  EcsPayload_app_CommandsTagA(CommandsTagA)
  EcsPayload_app_CommandsTagB(CommandsTagB)
  EcsPayload_app_CommandsTagC(CommandsTagC)
  EcsPayload_app_CommandsTagD(CommandsTagD)
  EcsPayload_app_CommandsTagE(CommandsTagE)
  EcsPayload_app_CommandsHookComponent(CommandsHookComponent)
  EcsPayload_app_CommandsCounterResource(CommandsCounterResource)
  EcsPayload_app_TestCursorMessage(TestCursorMessage)
  EcsPayload_app_TestParamSetMessage(TestParamSetMessage)
  EcsPayload_app_RemovedMarker(RemovedMarker)
  EcsPayload_app_TestState(TestState)
  EcsPayload_app_DerivedState(DerivedState)
  EcsPayload_app_PairState(PairState)
  EcsPayload_app_OptionalParentState(OptionalParentState)
  EcsPayload_app_OptionalChildState(OptionalChildState)
  EcsPayload_app_MultiSourceDerivedState(MultiSourceDerivedState)
  EcsPayload_app_OptionalDerivedState(OptionalDerivedState)
  EcsPayload_app_TestSubState(TestSubState)
}

///|
pub impl @ecs.EcsPayloadCodec for CounterResource with to_ecs_payload(self) {
  EcsPayload_app_CounterResource(self)
}

///|
pub impl @ecs.EcsPayloadCodec for CounterResource with from_ecs_payload(payload) {
  match payload {
    EcsPayload_app_CounterResource(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for HierarchyValidationMarker with to_ecs_payload(
  self,
) {
  EcsPayload_app_HierarchyValidationMarker(self)
}

///|
pub impl @ecs.EcsPayloadCodec for HierarchyValidationMarker with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_app_HierarchyValidationMarker(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for QueryPosition with to_ecs_payload(self) {
  EcsPayload_app_QueryPosition(self)
}

///|
pub impl @ecs.EcsPayloadCodec for QueryPosition with from_ecs_payload(payload) {
  match payload {
    EcsPayload_app_QueryPosition(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for QueryVelocity with to_ecs_payload(self) {
  EcsPayload_app_QueryVelocity(self)
}

///|
pub impl @ecs.EcsPayloadCodec for QueryVelocity with from_ecs_payload(payload) {
  match payload {
    EcsPayload_app_QueryVelocity(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for QueryMarker with to_ecs_payload(self) {
  EcsPayload_app_QueryMarker(self)
}

///|
pub impl @ecs.EcsPayloadCodec for QueryMarker with from_ecs_payload(payload) {
  match payload {
    EcsPayload_app_QueryMarker(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for SystemPipingMessage with to_ecs_payload(self) {
  EcsPayload_app_SystemPipingMessage(self)
}

///|
pub impl @ecs.EcsPayloadCodec for SystemPipingMessage with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_app_SystemPipingMessage(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for SystemPipingCounter with to_ecs_payload(self) {
  EcsPayload_app_SystemPipingCounter(self)
}

///|
pub impl @ecs.EcsPayloadCodec for SystemPipingCounter with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_app_SystemPipingCounter(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for SystemPipingMarker with to_ecs_payload(self) {
  EcsPayload_app_SystemPipingMarker(self)
}

///|
pub impl @ecs.EcsPayloadCodec for SystemPipingMarker with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_app_SystemPipingMarker(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for TestMessage with to_ecs_payload(self) {
  EcsPayload_app_TestMessage(self)
}

///|
pub impl @ecs.EcsPayloadCodec for TestMessage with from_ecs_payload(payload) {
  match payload {
    EcsPayload_app_TestMessage(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for EcsPosition with to_ecs_payload(self) {
  EcsPayload_app_EcsPosition(self)
}

///|
pub impl @ecs.EcsPayloadCodec for EcsPosition with from_ecs_payload(payload) {
  match payload {
    EcsPayload_app_EcsPosition(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for EcsVelocity with to_ecs_payload(self) {
  EcsPayload_app_EcsVelocity(self)
}

///|
pub impl @ecs.EcsPayloadCodec for EcsVelocity with from_ecs_payload(payload) {
  match payload {
    EcsPayload_app_EcsVelocity(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for TestAppMessage with to_ecs_payload(self) {
  EcsPayload_app_TestAppMessage(self)
}

///|
pub impl @ecs.EcsPayloadCodec for TestAppMessage with from_ecs_payload(payload) {
  match payload {
    EcsPayload_app_TestAppMessage(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for TestCursorAppMessage with to_ecs_payload(self) {
  EcsPayload_app_TestCursorAppMessage(self)
}

///|
pub impl @ecs.EcsPayloadCodec for TestCursorAppMessage with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_app_TestCursorAppMessage(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for TestDefaultAppMessage with to_ecs_payload(
  self,
) {
  EcsPayload_app_TestDefaultAppMessage(self)
}

///|
pub impl @ecs.EcsPayloadCodec for TestDefaultAppMessage with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_app_TestDefaultAppMessage(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for OneShotCounterResource with to_ecs_payload(
  self,
) {
  EcsPayload_app_OneShotCounterResource(self)
}

///|
pub impl @ecs.EcsPayloadCodec for OneShotCounterResource with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_app_OneShotCounterResource(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ScheduleBatchMarker with to_ecs_payload(self) {
  EcsPayload_app_ScheduleBatchMarker(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ScheduleBatchMarker with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_app_ScheduleBatchMarker(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for MissingRunIfParityResource with to_ecs_payload(
  self,
) {
  EcsPayload_app_MissingRunIfParityResource(self)
}

///|
pub impl @ecs.EcsPayloadCodec for MissingRunIfParityResource with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_app_MissingRunIfParityResource(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for TriggerIdentityOnce with to_ecs_payload(self) {
  EcsPayload_app_TriggerIdentityOnce(self)
}

///|
pub impl @ecs.EcsPayloadCodec for TriggerIdentityOnce with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_app_TriggerIdentityOnce(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for DespawnMarker with to_ecs_payload(self) {
  EcsPayload_app_DespawnMarker(self)
}

///|
pub impl @ecs.EcsPayloadCodec for DespawnMarker with from_ecs_payload(payload) {
  match payload {
    EcsPayload_app_DespawnMarker(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ObserverMarker with to_ecs_payload(self) {
  EcsPayload_app_ObserverMarker(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ObserverMarker with from_ecs_payload(payload) {
  match payload {
    EcsPayload_app_ObserverMarker(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ObserverPulse with to_ecs_payload(self) {
  EcsPayload_app_ObserverPulse(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ObserverPulse with from_ecs_payload(payload) {
  match payload {
    EcsPayload_app_ObserverPulse(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ObserverTriggered with to_ecs_payload(self) {
  EcsPayload_app_ObserverTriggered(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ObserverTriggered with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_app_ObserverTriggered(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for TriggerObserverTriggered with to_ecs_payload(
  self,
) {
  EcsPayload_app_TriggerObserverTriggered(self)
}

///|
pub impl @ecs.EcsPayloadCodec for TriggerObserverTriggered with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_app_TriggerObserverTriggered(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ErrorHandlingResource with to_ecs_payload(
  self,
) {
  EcsPayload_app_ErrorHandlingResource(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ErrorHandlingResource with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_app_ErrorHandlingResource(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ErrorHandlingMarker with to_ecs_payload(self) {
  EcsPayload_app_ErrorHandlingMarker(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ErrorHandlingMarker with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_app_ErrorHandlingMarker(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for CommandsPosition with to_ecs_payload(self) {
  EcsPayload_app_CommandsPosition(self)
}

///|
pub impl @ecs.EcsPayloadCodec for CommandsPosition with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_app_CommandsPosition(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for CommandsVelocity with to_ecs_payload(self) {
  EcsPayload_app_CommandsVelocity(self)
}

///|
pub impl @ecs.EcsPayloadCodec for CommandsVelocity with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_app_CommandsVelocity(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for CommandsMarker with to_ecs_payload(self) {
  EcsPayload_app_CommandsMarker(self)
}

///|
pub impl @ecs.EcsPayloadCodec for CommandsMarker with from_ecs_payload(payload) {
  match payload {
    EcsPayload_app_CommandsMarker(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for CommandsTagA with to_ecs_payload(self) {
  EcsPayload_app_CommandsTagA(self)
}

///|
pub impl @ecs.EcsPayloadCodec for CommandsTagA with from_ecs_payload(payload) {
  match payload {
    EcsPayload_app_CommandsTagA(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for CommandsTagB with to_ecs_payload(self) {
  EcsPayload_app_CommandsTagB(self)
}

///|
pub impl @ecs.EcsPayloadCodec for CommandsTagB with from_ecs_payload(payload) {
  match payload {
    EcsPayload_app_CommandsTagB(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for CommandsTagC with to_ecs_payload(self) {
  EcsPayload_app_CommandsTagC(self)
}

///|
pub impl @ecs.EcsPayloadCodec for CommandsTagC with from_ecs_payload(payload) {
  match payload {
    EcsPayload_app_CommandsTagC(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for CommandsTagD with to_ecs_payload(self) {
  EcsPayload_app_CommandsTagD(self)
}

///|
pub impl @ecs.EcsPayloadCodec for CommandsTagD with from_ecs_payload(payload) {
  match payload {
    EcsPayload_app_CommandsTagD(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for CommandsTagE with to_ecs_payload(self) {
  EcsPayload_app_CommandsTagE(self)
}

///|
pub impl @ecs.EcsPayloadCodec for CommandsTagE with from_ecs_payload(payload) {
  match payload {
    EcsPayload_app_CommandsTagE(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for CommandsHookComponent with to_ecs_payload(
  self,
) {
  EcsPayload_app_CommandsHookComponent(self)
}

///|
pub impl @ecs.EcsPayloadCodec for CommandsHookComponent with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_app_CommandsHookComponent(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for CommandsCounterResource with to_ecs_payload(
  self,
) {
  EcsPayload_app_CommandsCounterResource(self)
}

///|
pub impl @ecs.EcsPayloadCodec for CommandsCounterResource with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_app_CommandsCounterResource(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for TestCursorMessage with to_ecs_payload(self) {
  EcsPayload_app_TestCursorMessage(self)
}

///|
pub impl @ecs.EcsPayloadCodec for TestCursorMessage with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_app_TestCursorMessage(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for TestParamSetMessage with to_ecs_payload(self) {
  EcsPayload_app_TestParamSetMessage(self)
}

///|
pub impl @ecs.EcsPayloadCodec for TestParamSetMessage with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_app_TestParamSetMessage(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for RemovedMarker with to_ecs_payload(self) {
  EcsPayload_app_RemovedMarker(self)
}

///|
pub impl @ecs.EcsPayloadCodec for RemovedMarker with from_ecs_payload(payload) {
  match payload {
    EcsPayload_app_RemovedMarker(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for TestState with to_ecs_payload(self) {
  EcsPayload_app_TestState(self)
}

///|
pub impl @ecs.EcsPayloadCodec for TestState with from_ecs_payload(payload) {
  match payload {
    EcsPayload_app_TestState(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for DerivedState with to_ecs_payload(self) {
  EcsPayload_app_DerivedState(self)
}

///|
pub impl @ecs.EcsPayloadCodec for DerivedState with from_ecs_payload(payload) {
  match payload {
    EcsPayload_app_DerivedState(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for PairState with to_ecs_payload(self) {
  EcsPayload_app_PairState(self)
}

///|
pub impl @ecs.EcsPayloadCodec for PairState with from_ecs_payload(payload) {
  match payload {
    EcsPayload_app_PairState(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for OptionalParentState with to_ecs_payload(self) {
  EcsPayload_app_OptionalParentState(self)
}

///|
pub impl @ecs.EcsPayloadCodec for OptionalParentState with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_app_OptionalParentState(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for OptionalChildState with to_ecs_payload(self) {
  EcsPayload_app_OptionalChildState(self)
}

///|
pub impl @ecs.EcsPayloadCodec for OptionalChildState with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_app_OptionalChildState(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for MultiSourceDerivedState with to_ecs_payload(
  self,
) {
  EcsPayload_app_MultiSourceDerivedState(self)
}

///|
pub impl @ecs.EcsPayloadCodec for MultiSourceDerivedState with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_app_MultiSourceDerivedState(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for OptionalDerivedState with to_ecs_payload(self) {
  EcsPayload_app_OptionalDerivedState(self)
}

///|
pub impl @ecs.EcsPayloadCodec for OptionalDerivedState with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_app_OptionalDerivedState(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for TestSubState with to_ecs_payload(self) {
  EcsPayload_app_TestSubState(self)
}

///|
pub impl @ecs.EcsPayloadCodec for TestSubState with from_ecs_payload(payload) {
  match payload {
    EcsPayload_app_TestSubState(value) => Some(value)
    _ => None
  }
}
