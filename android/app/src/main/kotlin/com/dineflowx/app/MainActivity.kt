package com.dineflowx.app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
	private val channelName = "dineflowx.notifications"

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
			when (call.method) {
				"showNewOrderNotification" -> {
					val title = call.argument<String>("title") ?: "New Order"
					val body = call.argument<String>("body") ?: "A new order arrived"
					showNotification(title, body)
					result.success(null)
				}
				else -> result.notImplemented()
			}
		}
	}

	private fun showNotification(title: String, body: String) {
		val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
		val notificationId = 1001
		val notificationChannelId = "dineflowx_orders"

		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
			val channel = NotificationChannel(
				notificationChannelId,
				"Order Alerts",
				NotificationManager.IMPORTANCE_HIGH
			)
			notificationManager.createNotificationChannel(channel)
		}

		val notification = NotificationCompat.Builder(this, notificationChannelId)
			.setSmallIcon(android.R.drawable.ic_dialog_info)
			.setContentTitle(title)
			.setContentText(body)
			.setPriority(NotificationCompat.PRIORITY_HIGH)
			.setAutoCancel(true)
			.build()

		NotificationManagerCompat.from(this).notify(notificationId, notification)
	}
}

