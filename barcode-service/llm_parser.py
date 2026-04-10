"""
OpenRouter LLM integration for parsing barcode/OCR text into structured JSON
"""
import logging
import json
import os
import unicodedata
from typing import Optional, Dict, Any

from openai import OpenAI
from rapidfuzz import fuzz

logger = logging.getLogger(__name__)

OPENROUTER_API_KEY = os.getenv("OPENROUTER_API_KEY")
OPENROUTER_MODEL = os.getenv("OPENROUTER_MODEL", "meta-llama/llama-3.1-8b-instruct")


def normalize_name(name: str) -> str:
    """
    Normalize Turkish names:
    - Lowercase
    - Remove diacritics (ç→c, ş→s, ü→u, etc.)
    - Replace spaces with underscores
    """
    # Lowercase
    name = name.lower()

    # Remove diacritics using NFKD normalization
    nfd = unicodedata.normalize('NFKD', name)
    ascii_name = ''.join(c for c in nfd if unicodedata.category(c) != 'Mn')

    # Replace spaces and special chars with underscore
    ascii_name = ''.join(c if c.isalnum() else '_' for c in ascii_name)
    # Clean up multiple underscores
    while '__' in ascii_name:
        ascii_name = ascii_name.replace('__', '_')

    return ascii_name.strip('_')


def parse_barcode_with_llm(raw_text: str) -> Dict[str, Any]:
    """
    Use OpenRouter LLM to parse raw OCR/barcode text into structured JSON

    Returns:
    {
        "patient_name": str,
        "doctor_name": str,
        "date": "YYYY-MM-DD",
        "time": "HH:MM:SS",
        "department": str,
        "hospital": str,
        "confidence": float (0-1),
        "raw_text": str,
        "error": str or None,
    }
    """
    result = {
        "patient_name": None,
        "doctor_name": None,
        "date": None,
        "time": None,
        "department": None,
        "hospital": None,
        "confidence": 0.0,
        "raw_text": raw_text,
        "error": None,
    }

    if not OPENROUTER_API_KEY:
        result["error"] = "OPENROUTER_API_KEY not set"
        logger.error(result["error"])
        return result

    try:
        client = OpenAI(
            api_key=OPENROUTER_API_KEY,
            base_url="https://openrouter.ai/api/v1",
        )

        system_prompt = """You are a medical record parser specialized in extracting information from hospital barcode labels.

Your task is to parse the given text (which may be from OCR of a barcode label) and extract the following fields into JSON format:
- patient_name: Full name of the patient
- doctor_name: Name of the doctor/physician
- date: Date in YYYY-MM-DD format
- time: Time in HH:MM:SS format (if available)
- department: Medical department name
- hospital: Hospital name

Return ONLY a valid JSON object with these fields. If a field cannot be found, set it to null.
Be lenient with formatting variations. Examples:
- "Dr. Ahmet YILMAZ" → "Ahmet Yilmaz"
- "15/04/2026" → "2026-04-15"
- "14:30" → "14:30:00"

Return only the JSON, no other text."""

        user_prompt = f"Parse this barcode label text:\n\n{raw_text}"

        response = client.chat.completions.create(
            model=OPENROUTER_MODEL,
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt},
            ],
            temperature=0.2,  # Low temperature for consistent extraction
            max_tokens=500,
        )

        response_text = response.choices[0].message.content.strip()

        # Extract JSON from response (may be wrapped in markdown code blocks)
        if "```json" in response_text:
            response_text = response_text.split("```json")[1].split("```")[0].strip()
        elif "```" in response_text:
            response_text = response_text.split("```")[1].split("```")[0].strip()

        parsed = json.loads(response_text)

        # Normalize patient name
        if parsed.get("patient_name"):
            result["patient_name"] = parsed["patient_name"]

        if parsed.get("doctor_name"):
            result["doctor_name"] = parsed["doctor_name"]

        if parsed.get("date"):
            result["date"] = parsed["date"]

        if parsed.get("time"):
            result["time"] = parsed["time"]

        if parsed.get("department"):
            result["department"] = parsed["department"]

        if parsed.get("hospital"):
            result["hospital"] = parsed["hospital"]

        # Set confidence (LLM parsing is moderately confident)
        result["confidence"] = 0.8

        logger.info(f"LLM parsed: patient={result['patient_name']}, date={result['date']}")

    except json.JSONDecodeError as e:
        result["error"] = f"Failed to parse LLM response as JSON: {e}"
        logger.error(result["error"])
    except Exception as e:
        result["error"] = f"OpenRouter API error: {str(e)}"
        logger.error(result["error"])

    return result


def format_patient_folder_name(patient_name: str) -> str:
    """
    Format patient name for folder creation
    Example: "Ahmet Yilmaz" → "Ahmet_Yilmaz"
    """
    if not patient_name:
        return "Unknown"
    return normalize_name(patient_name).replace('_', '_').title()


def fuzzy_match_patient(name1: str, name2: str, threshold: float = 0.75) -> bool:
    """
    Fuzzy match two patient names
    Useful for finding patients even with slight spelling variations
    """
    if not name1 or not name2:
        return False

    normalized1 = normalize_name(name1)
    normalized2 = normalize_name(name2)

    # Use token_set_ratio for partial matches
    similarity = fuzz.token_set_ratio(normalized1, normalized2) / 100.0

    return similarity >= threshold
