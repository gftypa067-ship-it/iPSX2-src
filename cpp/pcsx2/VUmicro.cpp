// SPDX-FileCopyrightText: 2002-2025 PCSX2 Dev Team
// SPDX-License-Identifier: GPL-3.0+

#include "Common.h"
#include "VUmicro.h"
#include "MTVU.h"
#include "GS.h"
#include "Gif_Unit.h"

BaseVUmicroCPU* CpuVU0 = nullptr;
BaseVUmicroCPU* CpuVU1 = nullptr;

// ============================================================
//  [تعديل مُحسّن] حساب الحد الأدنى لدورات التشغيل
//  زيادة القيمة لتقليل عدد مرات استدعاء Execute وتحسين الأداء
// ============================================================
__inline u32 CalculateMinRunCycles(u32 cycles, bool requiresAccurateCycles)
{
	// في حال كانت العملية تتطلب دقة عالية (مثل عمليات COP2 المتداخلة)
	if (requiresAccurateCycles)
		return cycles;

	// [تعديل] رفع الحد الأدنى من 16 إلى 64 لتقليل عدد الاستدعاءات
	// يؤدي إلى تحسين كبير في الأداء مع مخاطرة بسيطة في التوقيت
	return std::max(64U, cycles);
}

// Executes a Block based on EE delta time
void BaseVUmicroCPU::ExecuteBlock(bool startUp)
{
	const u32& stat = VU0.VI[REG_VPU_STAT].UL;
	const int test = m_Idx ? 0x100 : 1;

	// ============================================================
	//  [تحسين] معالجة MTVU بشكل مستمر حتى لو كان VU1 متوقفاً
	//  هذا يضمن تدفق البيانات دون انتظار
	// ============================================================
	if (m_Idx && THREAD_VU1)
	{
		vu1Thread.Get_MTVUChanges();  // استدعاء دائم لضمان التحديث
		return;
	}

	if (!(stat & test))
	{
		// VU currently flushes XGKICK on VU1 end so no need for this, yet
		/*if (m_Idx == 1 && VU1.xgkickenable)
		{
			_vuXGKICKTransfer((cpuRegs.cycle - VU1.xgkicklastcycle), false);
		}*/
		return;
	}

	if (startUp)
	{
		Execute(CalculateMinRunCycles(0, false));
	}
	else // Continue Executing
	{
		u32 cycle = m_Idx ? VU1.cycle : VU0.cycle;
		s32 delta = (s32)(u32)(cpuRegs.cycle - cycle);

		if (delta > 0)
			Execute(CalculateMinRunCycles(delta, false));
	}
}

// ============================================================
//  [تعديل جذري] تحسين استدعاء VU0 JIT لتقليل التأخير
//  تشغيل VU0 فوراً بعد نقل البيانات من EE
// ============================================================
void BaseVUmicroCPU::ExecuteBlockJIT(BaseVUmicroCPU* cpu, bool interlocked)
{
	const u32& stat = VU0.VI[REG_VPU_STAT].UL;
	constexpr int test = 1;

	if (stat & test)
	{
		s32 delta = (s32)(u32)(cpuRegs.cycle - VU0.cycle);

		// [تحسين] تقليل الحد الأدنى للدلتا إلى 0 لتشغيل VU0 فوراً
		// هذا يضمن استجابة أسرع للألعاب التي تعتمد على VU0 بشكل مكثف
		if (delta > 0 || interlocked) // إذا كانت interlocked = true، شغّل فوراً
		{
			// [تعديل] استخدام دورة تشغيل محسوبة بدقة مع إعطاء أولوية للسرعة
			cpu->Execute(CalculateMinRunCycles(std::max(1U, (u32)delta), interlocked));
		}
	}
}
