package com.example.nt_location_tracking

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.mockito.Mockito
import kotlin.test.Test

internal class LocationTrackingPluginTest {
    @Test
    fun onMethodCall_unknownMethod_isNotImplemented() {
        val plugin = LocationTrackingPlugin()
        val call = MethodCall("unknownMethod", null)
        val mockResult: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)

        plugin.onMethodCall(call, mockResult)

        Mockito.verify(mockResult).notImplemented()
    }
}
